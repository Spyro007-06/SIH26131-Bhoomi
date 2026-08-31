"""Speech to text, Marathi and Hindi. Regional language is a PS clause.

OWNER: Shruthi. Spec: docs/API_CONTRACT.md §4, docs/DESIGN.md §12.

Below `config.ASR_FLOOR`, `parsed_intent` is omitted and the client re-prompts.
`needs_confirmation` mirrors whether `parsed_intent` survived that gate: a
response that asks the farmer to confirm something the client was never shown
is a self-contradiction, so this module treats them as the same gate rather
than tracking a separate "consequential fields" concept.

Flag: ASR_PROVIDER = live | stub, read via app.voice.providers' factory. This
flag governs the whole voice pipeline (ASR, TTS, translate-before-embed), not
ASR alone: stub means no Sarvam call on any of the three, live means all three
hit Sarvam.

Live provider: Sarvam Saaras (config.SARVAM_STT_MODEL), transcribe mode — audio
in, native-script text out. The native transcript is the single source: it is
read back for confirmation AND fed to to_embedding_text() (docs/DESIGN.md §8).
The stub returns a fixed low-confidence transcript so the ASR_FLOOR re-prompt
path is exercised without a key or network.

S3 note: Sarvam reports no transcript-confidence number, so a provider may
return `confidence=None` (never a fabricated sentinel — see providers.py).
When that happens the floor gate below falls back to a transcript-quality
heuristic (empty transcript -> below-floor) instead of comparing to
`ASR_FLOOR`. This is a deliberate deviation from docs/API_CONTRACT.md §4's
always-numeric `confidence` example, flagged for the doc to catch up.
"""

from __future__ import annotations

from app.config import ASR_FLOOR
from app.voice.providers import TranscriptResult, get_speech_to_text


def _is_usable_transcript(text: str) -> bool:
    """Non-empty after stripping whitespace. No length cutoff: a "too-short"
    threshold would need a new config constant, and config.py is out of
    scope for this module to add one to (docs/DESIGN.md §6) — flagged as a
    narrower heuristic than "too-short" implies, not an oversight."""
    return bool(text.strip())


def transcribe(asset_id: str, lang: str, context: str) -> TranscriptResult:
    """Transcribe an uploaded audio asset.

    Args:
        asset_id: the object the client PUT via /assets/presign.
        lang: BCP-47 tag, e.g. "mr-IN".
        context: "onboarding" | "doubt_doctor" | "query".

    Return shape is docs/API_CONTRACT.md §4: text, confidence, lang,
    parsed_intent, needs_confirmation. Below `config.ASR_FLOOR` (or, in live
    mode, for an empty transcript when no confidence is reported at all),
    parsed_intent is None and needs_confirmation is False — the client
    re-prompts rather than being asked to confirm something it was never shown.

    Raises:
        NotImplementedError: when the live Sarvam provider is selected but its
            core dependency (asset-bytes read) is not yet wired; see
            providers.LiveSpeechToText's docstring.
    """
    raw = get_speech_to_text().transcribe(asset_id, lang, context)
    if raw.confidence is not None:
        exposed = raw.confidence >= ASR_FLOOR
    else:
        exposed = _is_usable_transcript(raw.text)
    parsed_intent = raw.parsed_intent if exposed else None
    return TranscriptResult(
        text=raw.text,
        confidence=raw.confidence,
        lang=lang,
        parsed_intent=parsed_intent,
        needs_confirmation=parsed_intent is not None,
        is_stub=raw.is_stub,
    )
