"""Manual smoke test against the REAL Sarvam API. Not part of the normal suite.

Skipped unless SARVAMAI_API_KEY is set in the environment — the default
`pytest` run and CI never touch the real network. Run explicitly with:

    SARVAMAI_API_KEY=... pytest -q tests/test_voice_live_smoke.py

Only LiveTranslator is exercised here: LiveSpeechToText and LiveTextToSpeech
are still blocked on a missing core helper (see providers.py's Live*
docstrings) and have no live path to smoke-test yet.
"""

from __future__ import annotations

import os

import pytest

from app.config import settings
from app.voice.providers import LiveTranslator

pytestmark = pytest.mark.skipif(
    not os.environ.get("SARVAMAI_API_KEY"),
    reason="set SARVAMAI_API_KEY to run this against the real Sarvam API",
)


def test_live_translator_against_real_sarvam(monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.setattr(settings, "sarvamai_api_key", os.environ["SARVAMAI_API_KEY"])

    result = LiveTranslator().translate("माझ्या भातावर करपा आहे", "mr-IN")

    assert result.text
    assert result.is_stub is False
