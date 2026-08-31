"""transcribe(): the ASR_FLOOR gate. docs/API_CONTRACT.md §4.

"Below the ASR confidence floor, parsed_intent is omitted and the client
re-prompts." The stub's confidence is always below ASR_FLOOR by construction
(app.voice.providers.StubSpeechToText), so this exercises the gate end to end
without a key or network.
"""

from __future__ import annotations

from app.voice.asr import transcribe


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
