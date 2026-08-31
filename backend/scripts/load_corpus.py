"""Load the corpus manifest + markdown documents into CorpusDoc.

OWNER: Shreekumar. Spec: docs/DESIGN.md §5 and §8 (v3), docs/DESIGN.md §14.

Run from backend/:

    python scripts/load_corpus.py
    python scripts/load_corpus.py --dry-run

Idempotent on (doc_id, target): for each manifest row, every existing chunk
for that (doc_id, target) pair is deleted and the file's current chunks are
reinserted. Not a per-chunk upsert -- markdown section headings can change
between manifest revisions, so there is no stable per-chunk key to upsert
against, only a stable (doc_id, target) group. See migration
0009_corpus_doc_id_authoritative for the schema reasoning.

Must succeed cleanly on an empty seed/corpus/ directory (no manifest found).

-----------------------------------------------------------------------------
THE MANIFEST SCHEMA THIS LOADER READS

The 15 delivered documents and their manifest were not in the working tree
when this loader was written (confirmed absent on every branch). The shape
below is this loader's own specification for what it will read once they
land -- built from the fourth-loader-in-the-family brief, not guessed at
blind. If the delivered manifest differs, either the manifest is corrected to
this shape (consistent with every other loader in this family: the input is
what gets fixed) or this loader is revised in a reviewed change, not patched
silently to swallow a different shape.

`seed/corpus/manifest.json`, a JSON object with a `rows` array (plus `_note`
and `DOSAGE_VERIFICATION_NEEDED` strings for the human author -- read by
nobody in this codebase). One row per (document, target) pair -- a two-target
document appears TWICE, once per target, naming the same `doc_id` and
`source_file` both times (docs/DESIGN.md's "ingest that file's chunks once
per target, per the manifest's own note"):

    {
      "rows": [
        {
          "doc_id": "cotton_bollworm_complex_v1",
          "source_file": "cotton/cotton_bollworm_complex_v1.md",
          "crop": "cotton",
          "target": "cotton_american_bollworm",
          "title": "Cotton Bollworm Complex",
          "source": "TNAU Agritech Portal, Crop Protection > Cotton Pests, ...",
          "reviewed_on": "2026-08-31",
          "source_dated": "2024-03-15"
        },
        {
          "doc_id": "cotton_bollworm_complex_v1",
          "source_file": "cotton/cotton_bollworm_complex_v1.md",
          "crop": "cotton",
          "target": "cotton_pink_bollworm",
          "title": "Cotton Bollworm Complex",
          "source": "TNAU Agritech Portal, Crop Protection > Cotton Pests, ...",
          "reviewed_on": "2026-08-31",
          "source_dated": "2024-03-15"
        }
      ]
    }

`source_file` is relative to seed/corpus/. `source_dated` is REQUIRED --
the field the author must positively fill in to assert they know how current
the underlying source material is -- and is validated only, never stored: the
schema's own `reviewed_on` (when the row was last checked) is what lands in
CorpusDoc.reviewed_on. Every row in the first real delivery has
`source_dated: null` and is expected to fail on this until corrected. That is
the validation working, not a bug in this script.

-----------------------------------------------------------------------------
CHUNKING

By markdown section (H2, or H1 where a document has no H2), never by a fixed
token window. "Symptoms", "Early Symptoms", "Similar Diseases", "Cultural
Management", "Chemical Management" are natural boundaries and each is
independently meaningful as a retrieval unit -- splitting one in the middle
would return half an idea. See _chunk_markdown().

A heading containing "chemical" (case-insensitive) marks its chunk
authoritative=False. Every delivered document carries a Chemical Management
section written from training knowledge, flagged by the manifest itself as
unverified against any registration table. The corpus text stays available as
background reading; app/core/services/corpus.py's authoritative_chunks() is
the retrieval entry point that filters it out before it can reach anything
that composes a chemical rung. See that module for why the flag exists and
who is responsible for calling the filtered function.

-----------------------------------------------------------------------------
VALIDATION -- refuses, never coerces

target      exact member of TargetLabel. No fuzzy matching, no normalisation
            beyond none. A wrong target refused here and silently reattached
            by a smarter loader later is the exact failure mode this rule
            exists to prevent -- see NAME_MAPPING_NEEDED.md, which reports
            the mismatch for a human to fix at the source, and is read by
            nothing in this codebase.
crop        exact member of Crop.
source      must name a specific, findable document -- refused if it exact-
            matches a known generic placeholder, or carries no citation
            signal at all (no URL, no year, no known institution acronym, no
            quoted title). See GENERIC_SOURCE_PHRASES and
            _looks_like_a_real_citation().
source_dated  must be present. Validated only, never stored -- it is the
            author's positive attestation that they know how current the
            underlying source material is. reviewed_on (also manifest-
            supplied) is the value that lands in CorpusDoc.reviewed_on.
content     each markdown section must have non-empty body text once its
            heading line is removed; an empty section is skipped (not a
            document-level refusal) and reported.

Embeddings: no vector-generation path exists in this codebase as of this
loader (searched: no embedding client, no BGE-m3 call, nothing that returns
a `list[float]` -- app.voice.embedding_text.to_embedding_text() produces
normalised TEXT for a query, not a vector, and is the wrong function for
ingestion-time document embedding regardless). Every row loads with
`embedding = NULL`. NULL is an honest "not indexed yet"; generating a vector
with a different, unvetted model to fill the column would be indistinguishable
from a correctly-indexed row and is exactly the kind of silent substitution
this loader family refuses to do anywhere else.
-----------------------------------------------------------------------------
"""

from __future__ import annotations

import argparse
import asyncio
import json
import pathlib
import re
import sys
from dataclasses import dataclass, field
from datetime import date, datetime

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parents[1]))

from sqlalchemy import delete  # noqa: E402

from app.contracts.enums import Crop, TargetLabel  # noqa: E402
from app.core.models import CorpusDoc  # noqa: E402
from app.db import SessionLocal, dispose_engine  # noqa: E402

CORPUS_DIR = pathlib.Path(__file__).resolve().parents[1] / "seed" / "corpus"
MANIFEST_PATH = CORPUS_DIR / "manifest.json"
MAPPING_REPORT_PATH = CORPUS_DIR / "NAME_MAPPING_NEEDED.md"

REQUIRED_MANIFEST_FIELDS = (
    "doc_id",
    "source_file",
    "crop",
    "target",
    "title",
    "source",
    "source_dated",
)

# Known-bad, drawn verbatim from the brief plus the same shape of phrase for
# other crops. Exact match, case-insensitive, after stripping trailing
# punctuation -- a phrase list is not a fuzzy matcher, it is a fixed refusal
# list a human can extend by adding a line.
GENERIC_SOURCE_PHRASES = {
    "cotton disease field guides",
    "sorghum disease references",
    "soybean disease references",
    "jowar disease references",
    "agricultural crop-protection references",
    "crop protection references",
    "pest and disease references",
    "general agricultural references",
    "standard agricultural references",
    "field guides",
}

# A source with none of these signals names nothing a reader could go and
# find, whatever its wording. This is a structural floor, not a substitute for
# the phrase list above -- a source can dodge every phrase on the list and
# still fail this.
_URL_RE = re.compile(r"https?://", re.IGNORECASE)
_YEAR_RE = re.compile(r"\b(19|20)\d{2}\b")
_QUOTED_TITLE_RE = re.compile(r"['‘’\"“”][^'\"‘’“”]{6,}")
KNOWN_INSTITUTIONS = (
    "tnau", "icar", "niphm", "dppqs", "dppq", "ppqs", "cib&rc", "cibrc",
    "icrisat", "cicr", "iisr", "iimr", "aicrp", "krishi vigyan", "kvk",
)


@dataclass
class ChunkRow:
    doc_id: str
    title: str
    source: str
    reviewed_on: date | None
    target: str
    crop: str
    content: str
    authoritative: bool


@dataclass
class Refusal:
    doc_id: str
    target_raw: str
    reasons: list[str] = field(default_factory=list)


@dataclass
class NameMismatch:
    doc_id: str
    file: str
    field_name: str  # "target" or "crop"
    value: str
    likely: str | None


def _looks_like_a_real_citation(source: str) -> bool:
    lowered = source.lower()
    if _URL_RE.search(source):
        return True
    if any(inst in lowered for inst in KNOWN_INSTITUTIONS):
        return True
    if _YEAR_RE.search(source) and _QUOTED_TITLE_RE.search(source):
        # A bare year alone ("references, 2020") is not a citation; a year
        # attached to a quoted or titled work is.
        return True
    return bool(_QUOTED_TITLE_RE.search(source) and len(source) > 40)


def _validate_source(source: str, reasons: list[str]) -> None:
    normalised = source.strip().rstrip(".").lower()
    if normalised in GENERIC_SOURCE_PHRASES:
        reasons.append(
            f"source {source!r} is a generic placeholder, not a citation "
            "(exact match against the known-bad phrase list)"
        )
        return
    if not _looks_like_a_real_citation(source):
        reasons.append(
            f"source {source!r} carries no citation signal (no URL, no "
            "recognised institution, no dated quoted title) -- cannot be "
            "traced back to a document a reader could go and find"
        )


def _likely_target(raw: str, crop_hint: str | None) -> str | None:
    """Best-effort SUGGESTION for the human report only.

    Never consulted by the loader to accept a row -- see the module docstring.
    Tries an exact suffix match against every real target sharing the
    manifest row's crop (or every crop if none given), then a substring match.
    Returns None rather than guessing when nothing lines up cleanly.
    """
    raw_norm = raw.strip().lower()
    candidates = [
        t.value for t in TargetLabel
        if crop_hint is None or t.value.startswith(f"{crop_hint}_")
    ] or [t.value for t in TargetLabel]

    exact_suffix = [c for c in candidates if c == f"{crop_hint}_{raw_norm}"]
    if len(exact_suffix) == 1:
        return exact_suffix[0]

    suffix_matches = [c for c in candidates if c.endswith(f"_{raw_norm}")]
    if len(suffix_matches) == 1:
        return suffix_matches[0]

    substring_matches = [c for c in candidates if raw_norm in c or c.split("_", 1)[-1] in raw_norm]
    if len(substring_matches) == 1:
        return substring_matches[0]

    return None


def _chunk_markdown(text: str) -> list[tuple[str, str]]:
    """Split markdown into (heading, body) pairs on ATX headings.

    Boundaries are H2 (##) if any exist; otherwise H1 (#), excluding the very
    first heading, which is treated as the document title rather than a
    section. Never a fixed token window -- a heading is a natural boundary
    and a farmer-facing chunk should be one complete idea, not half of one
    split by a counter.
    """
    lines = text.splitlines()
    all_h1 = [i for i, ln in enumerate(lines) if re.match(r"^#\s+\S", ln)]
    h2_positions = [i for i, ln in enumerate(lines) if re.match(r"^##\s+\S", ln)]
    # H1 boundaries exclude the very first H1, which is the document title.
    boundaries = h2_positions if h2_positions else all_h1[1:]

    if not boundaries:
        # A document with no heading structure at all is treated as one
        # chunk. A document that HAS a heading structure (at least one H1)
        # but produced no boundaries -- a lone title and nothing else -- has
        # no body to chunk, and must not fall back to serving the raw
        # "# Title" markup as if it were content.
        if all_h1:
            return []
        body = text.strip()
        return [("Full document", body)] if body else []

    chunks: list[tuple[str, str]] = []
    for idx, start in enumerate(boundaries):
        end = boundaries[idx + 1] if idx + 1 < len(boundaries) else len(lines)
        heading = re.sub(r"^#+\s+", "", lines[start]).strip()
        body = "\n".join(lines[start + 1 : end]).strip()
        if body:
            chunks.append((heading, body))
    return chunks


def _parse_date(raw: str) -> date | None:
    if not raw:
        return None
    for fmt in ("%Y-%m-%d", "%d-%m-%Y", "%d/%m/%Y"):
        try:
            return datetime.strptime(raw, fmt).date()
        except ValueError:
            continue
    return None


def _validate_row(
    row: dict, index: int
) -> tuple[list[ChunkRow], Refusal | None, NameMismatch | None]:
    reasons: list[str] = []
    doc_id = str(row.get("doc_id") or f"(row {index})")

    for column in REQUIRED_MANIFEST_FIELDS:
        if not row.get(column):
            reasons.append(f"{column} is missing or blank")

    crop_raw = row.get("crop", "")
    target_raw = row.get("target", "")
    mismatch: NameMismatch | None = None

    if crop_raw and crop_raw not in {c.value for c in Crop}:
        reasons.append(
            f"crop {crop_raw!r} is not in the frozen enum "
            f"({', '.join(c.value for c in Crop)})"
        )

    if target_raw and target_raw not in {t.value for t in TargetLabel}:
        likely = _likely_target(target_raw, crop_raw or None)
        reasons.append(
            f"target {target_raw!r} is not an exact member of target_label"
            + (f" -- likely {likely!r}" if likely else " -- no confident match found")
        )
        mismatch = NameMismatch(
            doc_id=doc_id, file=str(row.get("source_file", "")), field_name="target",
            value=target_raw, likely=likely,
        )

    if row.get("source"):
        _validate_source(row["source"], reasons)

    if row.get("source_dated") and not _parse_date(row["source_dated"]):
        reasons.append(f"source_dated {row['source_dated']!r} is not a recognised date")

    if reasons:
        return (
            [],
            Refusal(doc_id=doc_id, target_raw=target_raw or "(none)", reasons=reasons),
            mismatch,
        )

    file_path = CORPUS_DIR / row["source_file"]
    if not file_path.exists():
        return [], Refusal(
            doc_id=doc_id, target_raw=target_raw,
            reasons=[f"source_file {row['source_file']!r} does not exist"],
        ), None

    sections = _chunk_markdown(file_path.read_text(encoding="utf-8"))
    if not sections:
        return [], Refusal(
            doc_id=doc_id, target_raw=target_raw,
            reasons=[f"source_file {row['source_file']!r} produced zero non-empty sections"],
        ), None

    reviewed = _parse_date(row.get("reviewed_on", "") or "")
    chunks = [
        ChunkRow(
            doc_id=doc_id,
            title=f"{row['title']} — {heading}",
            source=row["source"],
            reviewed_on=reviewed,
            target=target_raw,
            crop=crop_raw,
            content=body,
            authoritative="chemical" not in heading.lower(),
        )
        for heading, body in sections
    ]
    return chunks, None, None


def _write_mapping_report(mismatches: list[NameMismatch]) -> None:
    lines = [
        "# NAME_MAPPING_NEEDED.md",
        "",
        "Generated by scripts/load_corpus.py. A report for a human, not an input",
        "to the loader -- nothing in this codebase reads this file.",
        "",
        "Every row below has a `target` value in the manifest that is not an exact",
        "member of the frozen `target_label` enum. The loader refuses these rows",
        "outright rather than guessing; fixing the manifest at its source is the",
        "correct move, not adding a mapping layer here.",
        "",
        "| doc_id | file | manifest value | likely enum target |",
        "|---|---|---|---|",
    ]
    for m in mismatches:
        lines.append(
            f"| `{m.doc_id}` | `{m.file}` | `{m.value}` | "
            f"{'`' + m.likely + '`' if m.likely else '**no confident match**'} |"
        )
    lines.append("")
    MAPPING_REPORT_PATH.write_text("\n".join(lines), encoding="utf-8")


async def load(dry_run: bool = False) -> int:
    if not MANIFEST_PATH.exists():
        print(
            f"\n  {MANIFEST_PATH.relative_to(CORPUS_DIR.parents[1])} does not exist.\n"
            "  That is a clean, empty-corpus state, not a failure -- nothing to load.\n"
        )
        return 0

    manifest = json.loads(MANIFEST_PATH.read_text(encoding="utf-8"))
    if isinstance(manifest, dict):
        raw_rows = manifest.get("rows")
    else:
        raw_rows = manifest
    if not isinstance(raw_rows, list):
        print("ERROR: manifest.json must be a JSON object with a 'rows' array.")
        return 1

    all_chunks: list[ChunkRow] = []
    refusals: list[Refusal] = []
    mismatches: list[NameMismatch] = []

    for index, row in enumerate(raw_rows, start=1):
        chunks, refusal, mismatch = _validate_row(row, index)
        if refusal:
            refusals.append(refusal)
        else:
            all_chunks.extend(chunks)
        if mismatch:
            mismatches.append(mismatch)

    by_pair: dict[tuple[str, str], list[ChunkRow]] = {}
    for chunk in all_chunks:
        by_pair.setdefault((chunk.doc_id, chunk.target), []).append(chunk)

    written = 0
    if not dry_run:
        async with SessionLocal() as session:
            for (doc_id, target), chunks in by_pair.items():
                await session.execute(
                    delete(CorpusDoc).where(
                        CorpusDoc.doc_id == doc_id, CorpusDoc.target == target
                    )
                )
                for chunk in chunks:
                    session.add(
                        CorpusDoc(
                            doc_id=chunk.doc_id, title=chunk.title, source=chunk.source,
                            reviewed_on=chunk.reviewed_on, target=chunk.target,
                            crop=chunk.crop, content=chunk.content,
                            authoritative=chunk.authoritative, embedding=None,
                        )
                    )
                    written += 1
            await session.commit()
    else:
        written = len(all_chunks)

    if mismatches:
        _write_mapping_report(mismatches)

    print(f"\n  manifest       {MANIFEST_PATH.relative_to(CORPUS_DIR.parents[1])}")
    print(f"  rows read      {len(raw_rows)}")
    print(f"  (doc_id, target) pairs loaded  {len(by_pair)}")
    print(f"  chunks written {written}{'  (dry run, nothing written)' if dry_run else ''}")
    print(f"  rows refused   {len(refusals)}")
    non_auth = sum(1 for c in all_chunks if not c.authoritative)
    print(f"  non-authoritative chunks (Chemical Management)  {non_auth}")
    print("  embedding column: NULL on every row -- no embedding path exists yet")

    if refusals:
        print("\n  refused rows - correct the manifest, never here:")
        for r in refusals:
            print(f"    {r.doc_id}  (target={r.target_raw})")
            for reason in r.reasons:
                print(f"        - {reason}")

    if mismatches:
        print(
            f"\n  {len(mismatches)} target-name mismatch(es) written to "
            f"{MAPPING_REPORT_PATH.relative_to(CORPUS_DIR.parents[1])}"
        )

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
