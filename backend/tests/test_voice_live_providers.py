"""Live Sarvam providers: request shape and error handling. docs.sarvam.ai.

Hermetic — `httpx.post` is monkeypatched everywhere here; nothing in this file
touches the real network, and no SARVAMAI_API_KEY is required to run it.
"""

from __future__ import annotations

import httpx
import pytest

from app.config import (
    SARVAM_STT_MODEL,
    SARVAM_TRANSLATE_MODE,
    SARVAM_TRANSLATE_MODEL,
    SARVAM_TTS_MODEL,
    settings,
)
from app.contracts.enums import Lang
from app.errors import BhoomiError
from app.voice.providers import LiveSpeechToText, LiveTextToSpeech, LiveTranslator


def _fake_response(status_code: int, json_body: dict) -> httpx.Response:
    return httpx.Response(
        status_code, json=json_body, request=httpx.Request("POST", "https://api.sarvam.ai/x")
    )


@pytest.fixture(autouse=True)
def _fake_api_key(monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.setattr(settings, "sarvamai_api_key", "test-key-123")


def test_live_translator_sends_correct_request_and_parses_response(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    captured: dict = {}

    def fake_post(url: str, headers: dict, **kwargs: object) -> httpx.Response:
        captured["url"] = url
        captured["headers"] = headers
        captured["kwargs"] = kwargs
        return _fake_response(
            200,
            {
                "request_id": "r1",
                "translated_text": "my paddy has blast",
                "source_language_code": "mr-IN",
            },
        )

    monkeypatch.setattr("app.voice.providers.httpx.post", fake_post)

    result = LiveTranslator().translate("माझ्या भातावर करपा आहे", "mr-IN")

    assert captured["url"] == "https://api.sarvam.ai/translate"
    assert captured["headers"] == {"api-subscription-key": "test-key-123"}
    body = captured["kwargs"]["json"]
    assert body == {
        "input": "माझ्या भातावर करपा आहे",
        "source_language_code": "mr-IN",
        "target_language_code": Lang.ENGLISH.value,
        "model": SARVAM_TRANSLATE_MODEL,
        "mode": SARVAM_TRANSLATE_MODE,
    }
    assert result.text == "my paddy has blast"
    assert result.is_stub is False


def test_live_translator_non_200_raises_bhoomi_error_not_raw_exception(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    monkeypatch.setattr(
        "app.voice.providers.httpx.post",
        lambda *a, **kw: _fake_response(403, {"error": "forbidden"}),
    )

    with pytest.raises(BhoomiError):
        LiveTranslator().translate("hello", "en-IN")


def test_live_translator_transport_failure_raises_bhoomi_error_not_raw_exception(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    def fake_post(*a: object, **kw: object) -> httpx.Response:
        raise httpx.ConnectError("connection refused")

    monkeypatch.setattr("app.voice.providers.httpx.post", fake_post)

    with pytest.raises(BhoomiError):
        LiveTranslator().translate("hello", "en-IN")


def test_live_stt_sends_correct_request(monkeypatch: pytest.MonkeyPatch) -> None:
    captured: dict = {}

    def fake_post(url: str, headers: dict, **kwargs: object) -> httpx.Response:
        captured["url"] = url
        captured["headers"] = headers
        captured["kwargs"] = kwargs
        return _fake_response(200, {"request_id": "r1", "transcript": "माझं भात तिळरी अवस्थेत आहे"})

    monkeypatch.setattr("app.voice.providers.httpx.post", fake_post)

    result = LiveSpeechToText()._transcribe_bytes(b"fake-audio-bytes", "mr-IN")

    assert captured["url"] == "https://api.sarvam.ai/speech-to-text"
    assert captured["headers"] == {"api-subscription-key": "test-key-123"}
    assert captured["kwargs"]["data"] == {
        "model": SARVAM_STT_MODEL,
        "language_code": "mr-IN",
        "mode": "transcribe",
    }
    assert captured["kwargs"]["files"] == {"file": ("audio", b"fake-audio-bytes")}
    assert result.text == "माझं भात तिळरी अवस्थेत आहे"


def test_live_stt_never_fabricates_a_confidence_number(monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.setattr(
        "app.voice.providers.httpx.post",
        lambda *a, **kw: _fake_response(200, {"request_id": "r1", "transcript": "some words"}),
    )

    result = LiveSpeechToText()._transcribe_bytes(b"fake-audio-bytes", "mr-IN")
    assert result.confidence is None


def test_live_stt_empty_transcript_still_omits_parsed_intent(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    monkeypatch.setattr(
        "app.voice.providers.httpx.post",
        lambda *a, **kw: _fake_response(200, {"request_id": "r1", "transcript": ""}),
    )

    result = LiveSpeechToText()._transcribe_bytes(b"fake-audio-bytes", "mr-IN")
    assert result.text == ""
    assert result.parsed_intent is None
    assert result.needs_confirmation is False


def test_live_stt_non_200_raises_bhoomi_error_not_raw_exception(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    monkeypatch.setattr(
        "app.voice.providers.httpx.post",
        lambda *a, **kw: _fake_response(500, {"error": "internal"}),
    )

    with pytest.raises(BhoomiError):
        LiveSpeechToText()._transcribe_bytes(b"fake-audio-bytes", "mr-IN")


def test_live_tts_sends_correct_request_and_decodes_audio(monkeypatch: pytest.MonkeyPatch) -> None:
    import base64

    captured: dict = {}
    encoded = base64.b64encode(b"fake-wav-bytes").decode()

    def fake_post(url: str, headers: dict, **kwargs: object) -> httpx.Response:
        captured["url"] = url
        captured["headers"] = headers
        captured["kwargs"] = kwargs
        return _fake_response(200, {"request_id": "r1", "audios": [encoded]})

    monkeypatch.setattr("app.voice.providers.httpx.post", fake_post)

    audio = LiveTextToSpeech()._synthesize_bytes("hello", "mr-IN")

    assert captured["url"] == "https://api.sarvam.ai/text-to-speech"
    assert captured["headers"] == {"api-subscription-key": "test-key-123"}
    assert captured["kwargs"]["json"] == {
        "text": "hello",
        "language_code": "mr-IN",
        "model": SARVAM_TTS_MODEL,
    }
    assert audio == b"fake-wav-bytes"


def test_live_tts_non_200_raises_bhoomi_error_not_raw_exception(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    monkeypatch.setattr(
        "app.voice.providers.httpx.post",
        lambda *a, **kw: _fake_response(429, {"error": "rate limited"}),
    )

    with pytest.raises(BhoomiError):
        LiveTextToSpeech()._synthesize_bytes("hello", "mr-IN")
