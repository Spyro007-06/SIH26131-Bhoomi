"""Provider seam: stubs are loud, deterministic, and floor-safe by construction.

Spec: docs/DESIGN.md §8, §12, docs/API_CONTRACT.md §4.
"""

from __future__ import annotations

import pytest

from app.config import ASR_FLOOR, settings
from app.voice.providers import (
    LiveSpeechToText,
    LiveTextToSpeech,
    LiveTranslator,
    StubSpeechToText,
    StubTextToSpeech,
    StubTranslator,
    get_speech_to_text,
    get_text_to_speech,
    get_translator,
)


def test_stub_speech_to_text_is_detectable_and_below_floor() -> None:
    result = StubSpeechToText().transcribe("a_1", "mr-IN", "query")
    assert result.is_stub is True
    assert result.confidence < ASR_FLOOR


def test_stub_speech_to_text_is_deterministic_and_ignores_asset_id() -> None:
    first = StubSpeechToText().transcribe("a_1", "mr-IN", "query")
    second = StubSpeechToText().transcribe("a_completely_different_asset", "mr-IN", "query")
    assert first.text == second.text
    assert first.confidence == second.confidence == pytest.approx(ASR_FLOOR * 0.5)


def test_stub_text_to_speech_is_detectable_and_uses_presign_expiry() -> None:
    result = StubTextToSpeech().synthesize("hello", "mr-IN")
    assert result.is_stub is True
    assert result.expires_in == settings.presign_expiry_seconds


def test_stub_text_to_speech_is_deterministic_and_ignores_text() -> None:
    first = StubTextToSpeech().synthesize("hello", "mr-IN")
    second = StubTextToSpeech().synthesize("something else entirely", "hi-IN")
    assert first.audio_url == second.audio_url


def test_stub_translator_is_detectable_and_is_identity() -> None:
    result = StubTranslator().translate("माझ्या भातावर करपा आहे", "mr-IN")
    assert result.is_stub is True
    assert result.text == "माझ्या भातावर करपा आहे"


@pytest.mark.parametrize(
    ("factory", "stub_type"),
    [
        (get_speech_to_text, StubSpeechToText),
        (get_text_to_speech, StubTextToSpeech),
        (get_translator, StubTranslator),
    ],
)
def test_factory_returns_stub_by_default(factory, stub_type) -> None:
    assert isinstance(factory(), stub_type)


@pytest.mark.parametrize(
    ("factory", "live_type"),
    [
        (get_speech_to_text, LiveSpeechToText),
        (get_text_to_speech, LiveTextToSpeech),
        (get_translator, LiveTranslator),
    ],
)
def test_factory_returns_live_when_selected(monkeypatch, factory, live_type) -> None:
    monkeypatch.setattr(settings, "asr_provider", "live")
    assert isinstance(factory(), live_type)


def test_live_stt_and_tts_entrypoints_are_blocked_on_a_core_helper() -> None:
    """Neither makes a network call: both raise before touching httpx, because
    each needs a core capability that does not exist yet (asset-bytes read for
    STT, bytes-write/presign for TTS). See providers.py's Live* docstrings.

    LiveTranslator is NOT asserted here — S3 wired it for real (it needs
    neither), so calling it here would hit the live network. See
    test_voice_live_providers.py for its (mocked) coverage.
    """
    with pytest.raises(NotImplementedError, match="live Sarvam call"):
        LiveSpeechToText().transcribe("a_1", "mr-IN", "query")
    with pytest.raises(NotImplementedError, match="live Sarvam call"):
        LiveTextToSpeech().synthesize("hello", "mr-IN")
