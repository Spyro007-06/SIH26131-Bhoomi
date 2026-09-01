"""transcribe(): the ASR_FLOOR gate. docs/API_CONTRACT.md §4.

"Below the ASR confidence floor, parsed_intent is omitted and the client
re-prompts." The stub's confidence is always below ASR_FLOOR by construction
(app.voice.providers.StubSpeechToText), so this exercises the gate end to end
without a key or network.
"""

from __future__ import annotations

from dataclasses import dataclass

import app.voice.asr as asr_module
from app.voice.asr import transcribe
from app.voice.providers import TranscriptResult


def test_below_floor_omits_parsed_intent() -> None:
    result = transcribe("a_1", "mr-IN", "query")
    assert result.parsed_intent is None


def test_below_floor_needs_confirmation_is_false() -> None:
    result = transcribe("a_1", "mr-IN", "query")
    assert result.needs_confirmation is False


def test_transcribe_result_is_detectable_as_a_stub() -> None:
    result = transcribe("a_1", "mr-IN", "query")
    assert result.is_stub is True


def test_transcribe_echoes_the_requested_lang() -> None:
    result = transcribe("a_1", "hi-IN", "onboarding")
    assert result.lang == "hi-IN"


@dataclass(frozen=True, slots=True)
class _FakeLiveStyleProvider:
    """A minimal provider standing in for LiveSpeechToText: confidence=None,
    the shape a real Sarvam call always returns (S3 — no fabricated sentinel)."""

    text: str

    def transcribe(self, asset_id: str, lang: str, context: str) -> TranscriptResult:
        return TranscriptResult(
            text=self.text,
            confidence=None,
            lang=lang,
            parsed_intent=None,
            needs_confirmation=False,
            is_stub=False,
        )


def test_none_confidence_with_empty_transcript_omits_parsed_intent(monkeypatch) -> None:
    """The live-mode floor fallback: no numeric confidence to compare against
    ASR_FLOOR, so an empty transcript takes the below-floor path on transcript
    quality alone."""
    monkeypatch.setattr(asr_module, "get_speech_to_text", lambda: _FakeLiveStyleProvider(""))

    result = transcribe("a_1", "mr-IN", "query")
    assert result.parsed_intent is None
    assert result.needs_confirmation is False


def test_none_confidence_with_usable_transcript_still_has_no_parsed_intent(monkeypatch) -> None:
    """Documents a real, flagged gap from the original S3 ask: even a "usable"
    (non-empty) live transcript never gets needs_confirmation=True, because no
    live intent-extraction exists anywhere in this stack (Sarvam Saaras
    transcribes; it does not parse intent) — parsed_intent is always None for
    the live path, and needs_confirmation is tied to parsed_intent's presence
    (the S0 invariant). If a farmer-facing "please confirm what I heard" signal
    independent of parsed_intent is wanted, that is a product decision this
    test intentionally does not make on its own."""
    monkeypatch.setattr(
        asr_module, "get_speech_to_text", lambda: _FakeLiveStyleProvider("माझं भात तिळरी अवस्थेत आहे")
    )

    result = transcribe("a_1", "mr-IN", "query")
    assert result.parsed_intent is None
    assert result.needs_confirmation is False
