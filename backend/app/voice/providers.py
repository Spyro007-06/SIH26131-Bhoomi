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

import base64
import logging
from dataclasses import dataclass
from typing import Protocol

import httpx

from app.config import (
    ASR_FLOOR,
    SARVAM_STT_MODEL,
    SARVAM_TRANSLATE_MODE,
    SARVAM_TRANSLATE_MODEL,
    SARVAM_TTS_MODEL,
    settings,
)
from app.contracts.enums import GrowthStage, Lang
from app.errors import BhoomiError, ErrorCode

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
    confidence: float | None
    """None means "the provider does not report one" (live Saaras never does),
    not "we forgot to check" — never a fabricated sentinel. asr.transcribe()
    falls back to a transcript-quality heuristic instead of an ASR_FLOOR
    comparison when this is None. docs/API_CONTRACT.md §4 shows `confidence`
    as always-numeric; that is a deliberate deviation in live mode, flagged
    for the doc to catch up, not silently done."""
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
# Live providers. S3: Sarvam over HTTP via httpx — no sarvamai SDK, no other
# network call. Endpoints, headers and field names verified against
# docs.sarvam.ai (2026-08); see the S3 PR notes for the exact pages checked.
#
# core/ has no way for voice to read or write asset bytes: the only S3 code in
# core/ is the private, upload-only `_s3()` client inside
# core/routers/assets.py (presigned PUT for the client's own uploads). There is
# no presigned GET, no download helper, no bytes-fetch, and no "write bytes the
# server generated and get a URL back" helper anywhere in core/. That gap
# blocks LiveSpeechToText (needs to READ audio by asset_id) and
# LiveTextToSpeech (needs to STORE audio) in both directions — flagged for
# Shreekumar below, not worked around with a direct DB or boto3 call from
# voice/, which would break the module boundary docs/DESIGN.md §3 draws.
# ---------------------------------------------------------------------------

_SARVAM_BASE_URL = "https://api.sarvam.ai"
_SARVAM_API_KEY_HEADER = "api-subscription-key"


def _sarvam_headers() -> dict[str, str]:
    return {_SARVAM_API_KEY_HEADER: settings.sarvamai_api_key or ""}


def _sarvam_post(path: str, provider: str, **kwargs: object) -> dict:
    """POST to Sarvam; non-200 or a transport failure becomes a clean
    BhoomiError, never a raw httpx exception past this module boundary.

    `ErrorCode.VOICE_PROVIDER_UNAVAILABLE` (503, app/errors.py) is distinct
    from `AGRONOMIST_UNAVAILABLE`: that code carries a specific escalation
    meaning clients may branch on, and a Sarvam outage is an unrelated
    upstream-provider failure — this is its own code, not a reuse.
    """
    try:
        response = httpx.post(f"{_SARVAM_BASE_URL}{path}", headers=_sarvam_headers(), **kwargs)
    except httpx.HTTPError as exc:
        raise BhoomiError(
            ErrorCode.VOICE_PROVIDER_UNAVAILABLE,
            f"Voice service ({provider}) is temporarily unavailable. Try again shortly.",
            details={"error": str(exc)},
        ) from exc
    if response.status_code != 200:
        raise BhoomiError(
            ErrorCode.VOICE_PROVIDER_UNAVAILABLE,
            f"Voice service ({provider}) is temporarily unavailable. Try again shortly.",
            details={"status_code": response.status_code},
        )
    return response.json()


class LiveSpeechToText:
    """Sarvam Saaras, transcribe mode. docs.sarvam.ai/api-reference/speech-to-text/transcribe.

    BLOCKED: `transcribe()` receives only `asset_id`; Sarvam's endpoint needs
    the raw audio bytes as a multipart `file` field. Resolving asset_id ->
    bytes needs either a DB read (core/'s exclusive boundary, docs/DESIGN.md
    §3) or an S3 GET keyed by the Asset row's `object_key` (itself only
    resolvable via that same DB read) — voice has no legitimate path to
    either. Needed, exposed by Shreekumar: something like
    `core.assets.get_asset_bytes(asset_id) -> bytes` (or a presigned GET URL).
    Not built here.

    `_transcribe_bytes()` below is the real Sarvam call — endpoint, header,
    model, language_code, mode, response parsing, and the confidence-shape
    decision — fully built and unit-tested against a mocked audio payload, so
    wiring this in is a one-line change once that helper exists.
    """

    def transcribe(self, asset_id: str, lang: str, context: str) -> TranscriptResult:
        raise NotImplementedError(
            "live Sarvam call — implemented in S3, blocked on a core "
            "asset-bytes-read helper for `asset_id`. See LiveSpeechToText's "
            "docstring."
        )

    def _transcribe_bytes(self, audio: bytes, lang: str) -> TranscriptResult:
        """The Sarvam call itself, given raw audio bytes already in hand.

        Sarvam's response carries no transcript-confidence field — only
        `language_probability`, which scores language *detection*, not
        transcription quality, and is nullable even then. `confidence` is
        `None` here, always — never a fabricated sentinel;
        `asr.transcribe()` falls back to a transcript-quality heuristic
        instead of an ASR_FLOOR comparison when it sees `None`.

        `parsed_intent` is always `None`: Sarvam Saaras transcribes, it does
        not extract intent, and no NLU component exists anywhere in this
        stack. Building one is out of S3's Sarvam-only scope — flagged as a
        deliberate default, not an oversight.
        """
        body = _sarvam_post(
            "/speech-to-text",
            "speech-to-text",
            data={"model": SARVAM_STT_MODEL, "language_code": lang, "mode": "transcribe"},
            files={"file": ("audio", audio)},
        )
        return TranscriptResult(
            text=body["transcript"],
            confidence=None,
            lang=lang,
            parsed_intent=None,
            needs_confirmation=False,
            is_stub=False,
        )


class LiveTextToSpeech:
    """Sarvam Bulbul. docs.sarvam.ai/api-reference/text-to-speech/convert.

    BLOCKED: Sarvam returns base64-encoded audio bytes in the response body
    (`audios: [str]`), but `synthesize()` must return `audio_url` +
    `expires_in` — voice must not write to object storage directly (core/'s
    exclusive boundary, docs/DESIGN.md §3). core/ exposes presigned PUT for
    the client's OWN uploads (core/routers/assets.py) but nothing the *server*
    can call to write bytes it generated itself and get a URL back. Needed,
    exposed by Shreekumar: something like `core.assets.store_bytes(kind,
    content_type, data: bytes) -> (asset_id, presigned_url)`. Not built here.

    `_synthesize_bytes()` below is the real Sarvam call, returning decoded
    audio bytes — fully built and unit-tested — so wiring this in is a
    one-line change once that helper exists.
    """

    def synthesize(self, text: str, lang: str) -> SynthesisResult:
        raise NotImplementedError(
            "live Sarvam call — implemented in S3, blocked on a core "
            "bytes-write/presign helper for synthesized audio. See "
            "LiveTextToSpeech's docstring."
        )

    def _synthesize_bytes(self, text: str, lang: str) -> bytes:
        """The Sarvam call itself; returns decoded audio bytes.

        Storing these bytes and minting a URL is core's boundary — see the
        class docstring. This method stops at the bytes.
        """
        body = _sarvam_post(
            "/text-to-speech",
            "text-to-speech",
            json={"text": text, "language_code": lang, "model": SARVAM_TTS_MODEL},
        )
        return base64.b64decode(body["audios"][0])


class LiveTranslator:
    """Sarvam Mayura, formal mode, pinned. docs.sarvam.ai/api-reference/text/translate-text.

    Fully unblocked: no boundary or schema issue. One engine for both
    voice-origin and typed-origin queries (docs/DESIGN.md §8) — always
    translates to `Lang.ENGLISH`, never an inline "en-IN" literal.
    """

    def translate(self, text: str, source_lang: str) -> TranslationResult:
        body = _sarvam_post(
            "/translate",
            "translate",
            json={
                "input": text,
                "source_language_code": source_lang,
                "target_language_code": Lang.ENGLISH.value,
                "model": SARVAM_TRANSLATE_MODEL,
                "mode": SARVAM_TRANSLATE_MODE,
            },
        )
        return TranslationResult(text=body["translated_text"], is_stub=False)


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
