"""Corpus reads: crop/target retrieval, with the authoritative filter.

OWNER: Shreekumar

Specified by: docs/DESIGN.md §5 and §8 (v3).

-----------------------------------------------------------------------------
Two read paths, deliberately different.

`chunks_for(crop, target)` returns everything -- background reading, unfiltered.

`authoritative_chunks(crop, target)` excludes `authoritative = false` rows.
This is the ONLY function that may feed a chemical rung. Every corpus document
carries a Chemical Management section written from training knowledge and
flagged by the manifest itself as unverified against any registration table
(scripts/load_corpus.py). DESIGN §8 (v3) requires a chemical rung to resolve
against `registered_use` at composition time regardless of what the corpus
says -- that check belongs to whoever builds compose() (Thaariha,
app/intelligence/rag.py, currently NotImplementedError). This function is the
half of that guarantee that lives on the read side: compose() must call
authoritative_chunks(), never chunks_for(), when the retrieved text is about
to inform a dosage. A citation attached to an unverified figure is more
dangerous than no citation, because it looks checked.

core/ owns this because docs/DESIGN.md §3 keeps every database read inside
core/; intelligence/ receives typed results, never a session.
-----------------------------------------------------------------------------
"""

from __future__ import annotations

from dataclasses import dataclass

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.models import CorpusDoc


@dataclass(frozen=True, slots=True)
class CorpusChunk:
    """One retrievable section, detached from the ORM.

    Same reasoning as RegisteredUseRow in services/registered_use.py:
    intelligence/ never touches the database, so it receives a plain value
    rather than a lazy-loading ORM instance.
    """

    id: str
    doc_id: str
    title: str
    source: str
    content: str
    authoritative: bool


def _as_chunk(row: CorpusDoc) -> CorpusChunk:
    return CorpusChunk(
        id=str(row.id), doc_id=row.doc_id, title=row.title, source=row.source,
        content=row.content, authoritative=row.authoritative,
    )


async def chunks_for(session: AsyncSession, crop: str, target: str) -> list[CorpusChunk]:
    """Every chunk for a crop/target, authoritative and not.

    For background reading and for anything that is NOT composing a chemical
    rung -- what-to-check text, cultural and biological ladder rungs, Doubt
    Doctor context. Use authoritative_chunks() instead for anything that could
    end up as a dosage a farmer acts on.
    """
    rows = (
        await session.execute(
            select(CorpusDoc).where(CorpusDoc.crop == crop, CorpusDoc.target == target)
        )
    ).scalars().all()
    return [_as_chunk(r) for r in rows]


async def authoritative_chunks(
    session: AsyncSession, crop: str, target: str
) -> list[CorpusChunk]:
    """Chunks safe to inform a chemical rung. Excludes authoritative=false.

    THE function to call before any chemical-composition decision. See the
    module docstring.
    """
    rows = (
        await session.execute(
            select(CorpusDoc).where(
                CorpusDoc.crop == crop,
                CorpusDoc.target == target,
                CorpusDoc.authoritative.is_(True),
            )
        )
    ).scalars().all()
    return [_as_chunk(r) for r in rows]
