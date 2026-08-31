"""Load seed/registered_use.csv into the registered_use table.

OWNER: Shreekumar. Spec: docs/DESIGN.md §5 and §9, docs/API_CONTRACT.md §9.

Run from backend/:

    python scripts/load_registered_use.py
    python scripts/load_registered_use.py --dry-run

Idempotent. Upserts on the natural key (active_ingredient, crop, target), so
re-running corrects rows rather than duplicating them.

-----------------------------------------------------------------------------
This loader VALIDATES AND REFUSES. It never coerces, defaults or guesses.

A row missing pesticide_class, phi_days, source, source_dated or last_verified
is rejected and reported, not filled in. The reasoning is the advisory
ladder's, from docs/API_CONTRACT.md §8: a chemical rung missing its PHI is
omitted entirely rather than shipped incomplete. A half-populated row in this
table is worse than an absent one, because this table vetoes pesticide use —
an absent row yields NOT_IN_RECORDS ("Ask an expert before using it"), which
is honest, while a row with a guessed phi_days yields a confident PHI verdict
about a chemical going onto a field.

reentry_hours is the one exception, deliberately not in that list (migration
0011): a source stating a PHI but silent on re-entry is common, and the row
loads with reentry_hours = NULL rather than being refused for an omission
that belongs to the source, not the row. services/registered_use.py's
for_advisory() is what excludes an incomplete row from ever composing a
chemical rung — it needs the row to exist in the table to do that.

A row with no `source` is not auditable. It cannot be traced back to CIB&RC or
the state package of practices, so it cannot be defended, so it does not belong
in a table whose output a farmer acts on.

source_dated and last_verified are different facts, both required. source_dated
is the date the SOURCE DOCUMENT carries — a CIB&RC major-use table dated
30.09.2012 stays dated 2012 forever. last_verified is the date someone checked
that source still applies. Writing last_verified into a field a reader takes as
"still current" is how a 2012 document reads as current in 2026.
-----------------------------------------------------------------------------
"""

from __future__ import annotations

import argparse
import asyncio
import csv
import pathlib
import sys
from dataclasses import dataclass, field
from datetime import date, datetime

# Running this as a path (`python scripts/load_registered_use.py`) puts scripts/
# on sys.path rather than backend/, so `import app...` would fail. Fixed here so
# the documented command works without a PYTHONPATH dance.
sys.path.insert(0, str(pathlib.Path(__file__).resolve().parents[1]))

from sqlalchemy.dialects.postgresql import insert  # noqa: E402

from app.contracts.enums import Crop, TargetLabel  # noqa: E402
from app.core.models import PESTICIDE_CLASSES, RegisteredUse  # noqa: E402
from app.db import SessionLocal, dispose_engine  # noqa: E402

CSV_PATH = pathlib.Path(__file__).resolve().parents[1] / "seed" / "registered_use.csv"

REQUIRED = (
    "active_ingredient",
    "crop",
    "target",
    "pesticide_class",
    "dosage_text",
    "phi_days",
    "source",
    "source_dated",
    "last_verified",
)

# reentry_hours is deliberately absent from REQUIRED: a source that states a
# PHI without stating a re-entry period is common (CIB&RC major-use tables
# and PPQS labels both do this), and the row should load with
# reentry_hours = NULL rather than be refused for an omission that is the
# source's, not the row's. See migration 0011 and for_advisory() in
# services/registered_use.py, which is what excludes an incomplete row from
# a chemical rung -- it needs the row to exist in order to exclude it.


@dataclass
class Refusal:
    line: int
    ingredient: str
    reasons: list[str] = field(default_factory=list)


def _parse_int(raw: str, field_name: str, reasons: list[str]) -> int | None:
    try:
        value = int(raw)
    except (TypeError, ValueError):
        reasons.append(f"{field_name} is not an integer ({raw!r})")
        return None
    if value < 0:
        reasons.append(f"{field_name} is negative ({value})")
        return None
    return value


def _parse_date(raw: str, field_name: str, reasons: list[str]) -> date | None:
    for fmt in ("%Y-%m-%d", "%d-%m-%Y", "%d/%m/%Y"):
        try:
            return datetime.strptime(raw, fmt).date()
        except ValueError:
            continue
    reasons.append(f"{field_name} is not a date ({raw!r})")
    return None


def validate(row: dict[str, str], line: int) -> tuple[dict | None, Refusal | None]:
    """Return (clean_row, None) or (None, refusal). Never a partial row."""
    cleaned = {k: (v or "").strip() for k, v in row.items() if k}
    reasons: list[str] = []

    for column in REQUIRED:
        if not cleaned.get(column):
            reasons.append(f"{column} is missing or blank")

    ingredient = cleaned.get("active_ingredient", "")

    if cleaned.get("crop") and cleaned["crop"] not in {c.value for c in Crop}:
        reasons.append(
            f"crop {cleaned['crop']!r} is not in the frozen enum "
            f"({', '.join(c.value for c in Crop)})"
        )
    if cleaned.get("target") and cleaned["target"] not in {t.value for t in TargetLabel}:
        reasons.append(
            f"target {cleaned['target']!r} is not in the frozen enum "
            f"({', '.join(t.value for t in TargetLabel)})"
        )
    if cleaned.get("pesticide_class") and cleaned["pesticide_class"] not in PESTICIDE_CLASSES:
        reasons.append(
            f"pesticide_class {cleaned['pesticide_class']!r} is not one of "
            f"{', '.join(PESTICIDE_CLASSES)}"
        )

    phi = (
        _parse_int(cleaned["phi_days"], "phi_days", reasons)
        if cleaned.get("phi_days")
        else None
    )
    reentry = (
        _parse_int(cleaned.get("reentry_hours", ""), "reentry_hours", reasons)
        if cleaned.get("reentry_hours")
        else None
    )
    source_dated = (
        _parse_date(cleaned["source_dated"], "source_dated", reasons)
        if cleaned.get("source_dated")
        else None
    )
    verified = (
        _parse_date(cleaned["last_verified"], "last_verified", reasons)
        if cleaned.get("last_verified")
        else None
    )

    if reasons:
        return None, Refusal(line=line, ingredient=ingredient or "(blank)", reasons=reasons)

    return {
        # Stored lowercase and trimmed so the lookup's case-insensitive match has
        # a single canonical form to compare against.
        "active_ingredient": ingredient.lower(),
        "crop": cleaned["crop"],
        "target": cleaned["target"],
        "pesticide_class": cleaned["pesticide_class"],
        "dosage_text": cleaned["dosage_text"],
        "phi_days": phi,
        "reentry_hours": reentry,
        "source": cleaned["source"],
        "source_dated": source_dated,
        "last_verified": verified,
        "restriction_note": cleaned.get("restriction_note") or None,
    }, None


async def load(dry_run: bool = False) -> int:
    if not CSV_PATH.exists():
        print(f"ERROR: {CSV_PATH} does not exist.")
        return 1

    with CSV_PATH.open(newline="", encoding="utf-8") as handle:
        reader = csv.DictReader(handle)
        missing_columns = set(REQUIRED) - set(reader.fieldnames or [])
        if missing_columns:
            print(f"ERROR: CSV is missing columns: {', '.join(sorted(missing_columns))}")
            return 1
        rows = list(reader)

    clean: list[dict] = []
    refusals: list[Refusal] = []
    for offset, raw in enumerate(rows, start=2):  # line 1 is the header
        row, refusal = validate(raw, offset)
        if refusal:
            refusals.append(refusal)
        else:
            clean.append(row)

    loaded = 0
    if clean and not dry_run:
        async with SessionLocal() as session:
            for row in clean:
                statement = insert(RegisteredUse.__table__).values(**row)
                statement = statement.on_conflict_do_update(
                    constraint="uq_registered_use_ingredient_crop_target",
                    set_={
                        k: statement.excluded[k]
                        for k in row
                        if k not in ("active_ingredient", "crop", "target")
                    },
                )
                await session.execute(statement)
                loaded += 1
            await session.commit()
    elif clean and dry_run:
        loaded = len(clean)

    print()
    print(f"  source        {CSV_PATH.relative_to(CSV_PATH.parents[1])}")
    print(f"  rows read     {len(rows)}")
    print(f"  rows loaded   {loaded}{'  (dry run, nothing written)' if dry_run else ''}")
    print(f"  rows refused  {len(refusals)}")

    if refusals:
        print("\n  refused rows - correct these in the CSV, never here:")
        for refusal in refusals:
            print(f"    line {refusal.line}  {refusal.ingredient}")
            for reason in refusal.reasons:
                print(f"        - {reason}")

    if not rows:
        print(
            "\n  The CSV holds a header and no data rows. That is the current state and\n"
            "  a clean load, not a failure - but F8 cannot veto anything until it is\n"
            "  populated. See docs/DESIGN.md section 14 - as an unowned blocker."
        )

    # Refusals are reported, not fatal: a partially-good CSV should still load
    # its good rows. Exit code stays 0 so this is usable in a seed pipeline.
    return 0


async def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--dry-run", action="store_true", help="validate and report, write nothing"
    )
    args = parser.parse_args()
    try:
        return await load(dry_run=args.dry_run)
    finally:
        await dispose_engine()


if __name__ == "__main__":
    raise SystemExit(asyncio.run(main()))
