"""Translate-before-embed. The fix for the Devanagari trap.

OWNER: Shruthi. Spec: docs/DESIGN.md §8.

docs/DESIGN.md §8, verbatim in substance: any normalisation step that strips
non-ASCII produces a zero vector for a Marathi query, which produces a degenerate
similarity score, which sails past the relevance threshold and yields confident
fabricated advice. This has bitten this codebase before.

So: translate to a common language BEFORE embedding. Never strip, never
transliterate-and-hope. docs/DESIGN.md §13 requires a test asserting a Marathi
query and its English equivalent retrieve overlapping documents.
"""

from __future__ import annotations


def to_embedding_text(text: str, lang: str) -> str:
    """Return the text that should be embedded for `text` written in `lang`.

    Must never return an empty string for non-empty input, and must never strip
    a script it does not recognise.

    Raises:
        NotImplementedError: owner Shruthi, docs/DESIGN.md §8.
    """
    raise NotImplementedError(
        "translate-before-embed not implemented — owner: Shruthi, docs/DESIGN.md §8."
    )
