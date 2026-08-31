"""Corpus and cue coverage across all 26 frozen targets.

OWNER: Shreekumar. Run from backend/:  python scripts/corpus_coverage.py

Re-runnable at any time -- this is the table meant to be circulated after
every corpus delivery, not a one-off report. Reads live state, writes nothing.

Reports what is missing rather than papering over it: docs/DESIGN.md §14
already names both gaps this script surfaces --

  distinguishing_cues   F4's clarify branch needs a cue for a pair of labels
                        to resolve ambiguity. Zero cues means every ambiguous
                        pair escalates -- the designed degradation, not a bug,
                        but worth seeing as a number rather than discovering
                        it by reading code.

  corpus coverage       F7's advisory composition and F5's inspection tasks
                        both read the corpus. A target with no corpus chunk
                        takes the no-retrieval path -- honest, but the
                        advisory feature does not demo for that target.
"""

from __future__ import annotations

import asyncio
import pathlib
import sys

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parents[1]))

from sqlalchemy import func, select  # noqa: E402

from app.contracts.enums import TargetLabel  # noqa: E402
from app.core.models import CorpusDoc, DistinguishingCue  # noqa: E402
from app.db import SessionLocal, dispose_engine  # noqa: E402


async def coverage() -> None:
    async with SessionLocal() as session:
        corpus_counts = dict(
            (
                await session.execute(
                    select(CorpusDoc.target, func.count())
                    .where(CorpusDoc.target.is_not(None))
                    .group_by(CorpusDoc.target)
                )
            ).all()
        )
        authoritative_counts = dict(
            (
                await session.execute(
                    select(CorpusDoc.target, func.count())
                    .where(CorpusDoc.target.is_not(None), CorpusDoc.authoritative.is_(True))
                    .group_by(CorpusDoc.target)
                )
            ).all()
        )

        cue_targets: set[str] = set()
        for row in (
            await session.execute(select(DistinguishingCue.discriminates))
        ).scalars().all():
            cue_targets.update(row)
        total_cues = (
            await session.scalar(select(func.count()).select_from(DistinguishingCue))
        )

    targets = sorted(TargetLabel, key=lambda t: t.value)
    covered = sum(1 for t in targets if corpus_counts.get(t.value, 0) > 0)
    with_cue = sum(1 for t in targets if t.value in cue_targets)

    print(f"\n  {'target':32s} {'has_corpus':11s} {'chunks':7s} {'authoritative':13s} has_cue")
    print("  " + "-" * 78)
    for t in targets:
        value = t.value if hasattr(t, "value") else str(t)
        chunks = corpus_counts.get(value, 0)
        auth = authoritative_counts.get(value, 0)
        has_corpus = "yes" if chunks else "NO"
        has_cue = "yes" if value in cue_targets else "no"
        print(f"  {value:32s} {has_corpus:11s} {chunks:<7d} {auth:<13d} {has_cue}")

    print(f"\n  {covered}/{len(targets)} targets have at least one corpus chunk")
    print(f"  {with_cue}/{len(targets)} targets are covered by at least one cue")
    print(f"  {total_cues} distinguishing_cue row(s) total")
    if total_cues == 0:
        print(
            "\n  distinguishing_cue is EMPTY. F4's clarify branch resolves nothing --\n"
            "  every ambiguous pair escalates. The designed degradation "
            "(docs/DESIGN.md §7),\n"
            "  reported here as a number rather than left silent."
        )
    print()


async def main() -> None:
    try:
        await coverage()
    finally:
        await dispose_engine()


if __name__ == "__main__":
    asyncio.run(main())
