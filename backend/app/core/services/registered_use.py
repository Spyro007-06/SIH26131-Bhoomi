"""F8 - the lookup half.

OWNER: Shreekumar

Table lookup against registered_use. No model is consulted and the LLM is not
in this path. An ingredient with no row is NOT_IN_RECORDS, never an inferred
verdict.

Specified by: docs/DESIGN.md §9, docs/API_CONTRACT.md §9.

-----------------------------------------------------------------------------
Two decisions here are safety properties, not implementation taste.

**Returns every target, not just the requested one.** docs/DESIGN.md §9 has six
verdicts, and two of them are only distinguishable from the full row set for an
ingredient:

    NOT_IN_RECORDS             no rows at all for this ingredient
    NOT_REGISTERED_FOR_TARGET  rows exist, none of them for this target

Filtering by target in SQL would collapse both into "no rows" and the verdict
logic could not tell "I have never heard of this chemical" from "this chemical
is real but not for this pest". Those are different sentences to a farmer.

**Matching is exact after casefold and trim, and nothing else.** No fuzzy match,
no stemming, no edit distance. If OCR reads "carbendazirn" (rn for m), this must
MISS and produce NOT_IN_RECORDS, which tells the farmer to ask an expert. A
fuzzy matcher that resolved it to carbendazim would return a confident PHI and
class verdict for a product the system never actually identified.

Wrong-row-returned is the failure mode that matters. No-row-returned is safe.
-----------------------------------------------------------------------------
"""

from __future__ import annotations

from dataclasses import dataclass
from datetime import date

from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.contracts.enums import Crop
from app.core.models import RegisteredUse


@dataclass(frozen=True, slots=True)
class RegisteredUseRow:
    """One registered use, detached from the ORM.

    A frozen dataclass rather than the ORM object: intelligence/ consumes this
    and docs/DESIGN.md §3 says that package never touches the database. Handing
    it a live ORM instance would give it a lazy-loading session handle, which is
    exactly the boundary that rule exists to keep closed.
    """

    id: str
    active_ingredient: str
    crop: str
    target: str
    pesticide_class: str
    dosage_text: str
    phi_days: int
    reentry_hours: int
    source: str
    last_verified: date | None


def normalise_ingredient(raw: str) -> str:
    """The only transformation applied to a searched ingredient.

    casefold() rather than lower() so non-ASCII input folds correctly; strip()
    for OCR whitespace. Nothing else — see the module docstring.
    """
    return (raw or "").strip().casefold()


async def lookup(
    session: AsyncSession, active_ingredient: str, crop: str
) -> list[RegisteredUseRow]:
    """Every registered use of `active_ingredient` on `crop`, across all targets.

    Args:
        session: an open AsyncSession. core/ owns the database connection;
            callers in intelligence/ receive the result, not the session.
        active_ingredient: as extracted by OCR or spoken by the farmer.
        crop: a value from the frozen `crop` enum.

    Returns:
        Possibly empty. An empty list means NOT_IN_RECORDS territory and is a
        normal result, not an error — the table is legitimately empty right now.
    """
    needle = normalise_ingredient(active_ingredient)
    if not needle:
        return []

    # `crop` is a native Postgres enum, so comparing it against a value outside
    # the frozen set is a database-level type error rather than a miss. Checked
    # in Python instead: an unrecognised crop is no rows, consistent with the
    # rule that no-row-returned is the safe failure.
    if crop not in {c.value for c in Crop}:
        return []

    statement = (
        select(RegisteredUse)
        .where(
            func.lower(func.trim(RegisteredUse.active_ingredient)) == needle,
            RegisteredUse.crop == crop,
        )
        .order_by(RegisteredUse.target)
    )
    rows = (await session.execute(statement)).scalars().all()

    return [
        RegisteredUseRow(
            id=str(row.id),
            active_ingredient=row.active_ingredient,
            crop=row.crop.value if hasattr(row.crop, "value") else str(row.crop),
            target=row.target.value if hasattr(row.target, "value") else str(row.target),
            pesticide_class=row.pesticide_class,
            dosage_text=row.dosage_text,
            phi_days=row.phi_days,
            reentry_hours=row.reentry_hours,
            source=row.source,
            last_verified=row.last_verified,
        )
        for row in rows
    ]
