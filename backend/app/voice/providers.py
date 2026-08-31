"""Provider seam — Sarvam STT/TTS/Translator behind stub and live implementations.

OWNER: Shruthi. Spec: docs/DESIGN.md §8, §12, docs/API_CONTRACT.md §4.

`settings.asr_provider` ("stub" | "live") governs all three providers together:
stub means no Sarvam call anywhere in the voice pipeline, live means all three
call Sarvam. `asr.py`, `tts.py` and `embedding_text.py` call through the
factories below rather than instantiating a provider directly, so S3 swaps the
Live* bodies for real Sarvam calls without touching any caller.

The stub implementations are loud on purpose, mirroring vision/classifier.py's
own stub convention (docs/DESIGN.md §12): fixed, deterministic output that
never reads its input, `is_stub=True` on every result, and a warning logged on
every call.
"""

from __future__ import annotations

import logging
from dataclasses import dataclass
from typing import Protocol

from app.config import (
    ASR_FLOOR,
    SARVAM_STT_MODEL,
    SARVAM_TRANSLATE_MODEL,
    SARVAM_TTS_MODEL,
    settings,
)
from app.contracts.enums import GrowthStage

log = logging.getLogger("bhoomi.voice")

# ---------------------------------------------------------------------------
# Result shapes. Internal only — no frozen wire contract exists for voice yet
# (docs/API_CONTRACT.md §4 is prose, not a type in contracts/), so these are
# plain frozen dataclasses, not pydantic models: they never leave this process
# in this phase and shouldn't be mistaken for a team-reviewed C-contract.
# ---------------------------------------------------------------------------


@dataclass(frozen=True, slots=True)
class ParsedIntent:
    field: str
    value: str


@dataclass(frozen=True, slots=True)
class TranscriptResult:
    text: str
    confidence: float
    lang: str
    parsed_intent: ParsedIntent | None
    needs_confirmation: bool
    is_stub: bool


@dataclass(frozen=True, slots=True)
class SynthesisResult:
    audio_url: str
    expires_in: int
    is_stub: bool


@dataclass(frozen=True, slots=True)
class TranslationResult:
    text: str
    is_stub: bool


# ---------------------------------------------------------------------------
# Protocols. S3 implements the Live* bodies against these; nothing else in the
# codebase changes when it does.
# ---------------------------------------------------------------------------


class SpeechToText(Protocol):
    def transcribe(self, asset_id: str, lang: str, context: str) -> TranscriptResult: ...


class TextToSpeech(Protocol):
    def synthesize(self, text: str, lang: str) -> SynthesisResult: ...


class Translator(Protocol):
    def translate(self, text: str, source_lang: str) -> TranslationResult: ...


# ---------------------------------------------------------------------------
# Stubs. Fixed, deterministic, never read their input. docs/DESIGN.md §12.
# ---------------------------------------------------------------------------

_STUB_TRANSCRIPT_TEXT = "[stub transcript — ASR not implemented, provider=stub]"
_STUB_AUDIO_URL = "stub://voice-tts/not-implemented"


class StubSpeechToText:
    """Fixed low-confidence transcript. Never reads the audio asset.

    Confidence is derived from `ASR_FLOOR` (not an independent literal), so it
    stays below the floor by construction even if the floor is retuned — the
    ASR_FLOOR re-prompt path (docs/API_CONTRACT.md §4) is always exercisable
    without a key or network.

    `needs_confirmation` here is a placeholder (False); `asr.transcribe()` is
    the sole authority on that field and recomputes it from whether
    `parsed_intent` survives the floor gate.
    """

    def transcribe(self, asset_id: str, lang: str, context: str) -> TranscriptResult:
        log.warning(
            "voice.transcribe() served by STUB — fixed transcript, audio not "
            "read. is_stub=true. docs/DESIGN.md §12."
        )
        return TranscriptResult(
            text=_STUB_TRANSCRIPT_TEXT,
            confidence=ASR_FLOOR * 0.5,
            lang=lang,
            parsed_intent=ParsedIntent(field="growth_stage", value=GrowthStage.TILLERING.value),
            needs_confirmation=False,
            is_stub=True,
        )


class StubTextToSpeech:
    """Fixed placeholder audio URL. Never reads or renders `text`."""

    def synthesize(self, text: str, lang: str) -> SynthesisResult:
        log.warning(
            "voice.synthesize() served by STUB — fixed audio_url, text not "
            "rendered. is_stub=true. docs/DESIGN.md §12."
        )
        return SynthesisResult(
            audio_url=_STUB_AUDIO_URL,
            expires_in=settings.presign_expiry_seconds,
            is_stub=True,
        )


class StubTranslator:
    """Identity passthrough — performs no real translation.

    Until S3 wires live Mayura, the Devanagari-trap fix in `to_embedding_text()`
    is carried entirely by `glossary.py`'s domain-term pinning, not by this
    class. That is a documented property of this stub, not an oversight.
    """

    def translate(self, text: str, source_lang: str) -> TranslationResult:
        log.warning(
            "voice.to_embedding_text() translator served by STUB — identity "
            "passthrough, no real translation. is_stub=true. docs/DESIGN.md §12."
        )
        return TranslationResult(text=text, is_stub=True)


# ---------------------------------------------------------------------------
# Live placeholders. S3 implements the real Sarvam calls here. No SDK import,
# no network — this phase only builds the seam they will plug into.
# ---------------------------------------------------------------------------


class LiveSpeechToText:
    """Sarvam Saaras, transcribe mode. docs/DESIGN.md §12. Implemented in S3."""

    def transcribe(self, asset_id: str, lang: str, context: str) -> TranscriptResult:
        log.info("voice.transcribe() would call Sarvam %s — not yet implemented.", SARVAM_STT_MODEL)
        raise NotImplementedError("live Sarvam call — implemented in S3")


class LiveTextToSpeech:
    """Sarvam Bulbul. docs/DESIGN.md §12. Implemented in S3."""

    def synthesize(self, text: str, lang: str) -> SynthesisResult:
        log.info("voice.synthesize() would call Sarvam %s — not yet implemented.", SARVAM_TTS_MODEL)
        raise NotImplementedError("live Sarvam call — implemented in S3")


class LiveTranslator:
    """Sarvam Mayura, formal mode, pinned. docs/DESIGN.md §8. Implemented in S3."""

    def translate(self, text: str, source_lang: str) -> TranslationResult:
        log.info(
            "voice.to_embedding_text() would call Sarvam %s — not yet implemented.",
            SARVAM_TRANSLATE_MODEL,
        )
        raise NotImplementedError("live Sarvam call — implemented in S3")


# ---------------------------------------------------------------------------
# Factories. One flag, `settings.asr_provider`, governs all three.
# ---------------------------------------------------------------------------


def get_speech_to_text() -> SpeechToText:
    if settings.asr_provider == "stub":
        return StubSpeechToText()
    return LiveSpeechToText()


def get_text_to_speech() -> TextToSpeech:
    if settings.asr_provider == "stub":
        return StubTextToSpeech()
    return LiveTextToSpeech()


def get_translator() -> Translator:
    if settings.asr_provider == "stub":
        return StubTranslator()
    return LiveTranslator()
