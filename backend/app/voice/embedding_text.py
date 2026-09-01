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

Provider caveat: step 1 only translates for real when the live Sarvam
provider is selected (S3, merged) — `StubTranslator` (providers.py) stays an
identity passthrough, and with the stub selected it is step 3 (glossary.py)
that fixes the Devanagari trap for the one domain term the glossary knows
(करपा -> blast), not yet a general-purpose translator. `ASR_PROVIDER=stub` is
still this project's default; see .env.example.
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
