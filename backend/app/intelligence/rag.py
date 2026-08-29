"""Advisory pipeline (F7) — retrieval, grounded composition, structural validation.

OWNER: Thaariha. Spec: docs/DESIGN.md §8, docs/API_CONTRACT.md §8.

    query -> to_embedding_text() -> embed (BGE-m3) -> pgvector search
          -> relevance below RAG_THRESHOLD? -> retrieved:false, STOP
          -> LLM composes into the fixed schema, grounded on retrieved chunks
          -> validate: ladder ordered, chemical last, citations present
          -> persist Advisory

The validation step is not optional. A ladder with a chemical rung first is
rejected and recomposed, not shipped. Structural guarantees enforced only by
prompt wording are not guarantees.

The Devanagari trap (docs/DESIGN.md §8): any normalisation that strips non-ASCII
gives a Marathi query a zero vector, a degenerate similarity score, and confident
fabricated advice past the threshold. This has bitten this codebase before.
"""

from __future__ import annotations

from typing import Any


def compose(
    query_text: str,
    crop: str,
    target: str,
    retrieved_docs: list[Any],
) -> Any:
    """Compose an advisory strictly grounded on `retrieved_docs`.

    Called only after the gate returns `advise`. Never called speculatively.

    Return shape is the advisory object in docs/API_CONTRACT.md §8: possible_issue,
    what_to_check, what_to_avoid, ladder (chemical last), expert_trigger, citations.

    Raises:
        NotImplementedError: owner Thaariha, docs/DESIGN.md §8.
    """
    raise NotImplementedError(
        "Advisory composition not implemented — owner: Thaariha, docs/DESIGN.md §8."
    )
