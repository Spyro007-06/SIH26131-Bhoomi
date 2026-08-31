"""Translate-before-embed. The fix for the Devanagari trap.

OWNER: Shruthi. Spec: docs/DESIGN.md §8.

docs/DESIGN.md §8, verbatim in substance: any normalisation step that strips
non-ASCII produces a zero vector for a Marathi query, which produces a degenerate
similarity score, which sails past the relevance threshold and yields confident
fabricated advice. This has bitten this codebase before.

So: translate to a common language BEFORE embedding. Never strip, never
transliterate-and-hope. docs/DESIGN.md §13 requires a test asserting a Marathi
query and its English equivalent retrieve overlapping documents.

Live translator: Sarvam Mayura (config.SARVAM_TRANSLATE_MODEL) in formal mode,
pinned. ONE engine for both voice-origin and typed-origin queries, so the same
Marathi sentence yields the same English yields the same vector — that is what
keeps the §13 overlap test reproducible. Do not route voice through Saaras
translate-mode as a shortcut; two engines means two English renderings and a
flaky test.

Order, and it matters (docs/DESIGN.md §8):
  1. translate mr/hi -> en  (Mayura, formal, pinned)
  2. normalise the ENGLISH output only  (never touch the Devanagari)
  3. glossary-pin domain terms to the target_label vocabulary
  4. length guard: refuse empty/degenerate text rather than embed a near-zero vector

S0 caveat: `StubTranslator` (providers.py) is an identity passthrough — step 1
is a no-op until S3 wires live Mayura. In S0 it is step 3 (glossary.py) that
actually fixes the Devanagari trap for the one domain term the glossary knows
(करपा -> blast); it is not yet a general-purpose translator.
"""

from __future__ import annotations

import app.voice.glossary as glossary
from app.voice.providers import get_translator


def _normalize_english_only(text: str) -> str:
    """Lowercase/collapse-whitespace on ASCII tokens only; leave every other
    token byte-for-byte untouched — the Devanagari trap this module exists to
    avoid."""
    return " ".join(token.lower() if token.isascii() else token for token in text.split())


def to_embedding_text(text: str, lang: str) -> str:
    """Return the text that should be embedded for `text` written in `lang`.

    Must never return an empty string for non-empty input, and must never strip
    a script it does not recognise.

    Raises:
        NotImplementedError: when the live Sarvam translator is selected; that
            call is implemented in S3.
        ValueError: the pipeline produced degenerate (empty) output. The
            caller (intelligence/rag.py, not yet implemented) decides whether
            to translate this into a BhoomiError at the API boundary — there
            is no router in this phase to own that.
    """
    translated = get_translator().translate(text, lang).text
    normalized = _normalize_english_only(translated)
    pinned = glossary.pin(normalized)
    cleaned = pinned.strip()
    if not cleaned:
        raise ValueError(
            "to_embedding_text: refusing degenerate (empty) output — would "
            "embed to a near-zero vector. docs/DESIGN.md §8."
        )
    return cleaned
