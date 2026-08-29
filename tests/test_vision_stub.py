"""The vision stub is inert, deterministic and honest.

docs/DESIGN.md section 12 and docs/PRD.md: "A stub that returns confident output
on arbitrary input is worse than no feature."
"""

from __future__ import annotations

import pytest

from app import config
from app.config import settings
from app.contracts.vision import TOPK_SIZE
from app.vision import classify


@pytest.fixture(autouse=True)
def _force_stub(monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.setattr(settings, "vision_model", "stub")


def test_stub_declares_itself() -> None:
    """is_stub=true is what makes the client render the banner. Section 12."""
    assert classify(b"anything").is_stub is True


def test_stub_output_does_not_depend_on_the_image() -> None:
    """It must not hash the image or otherwise produce input-dependent output
    that looks like a real prediction."""
    a = classify(b"one image")
    b = classify(b"a completely different set of bytes")
    c = classify("an-asset-id-instead-of-bytes")
    assert a.predictions == b.predictions == c.predictions


def test_stub_returns_a_valid_topk() -> None:
    topk = classify(b"x")
    assert len(topk.predictions) == TOPK_SIZE
    confidences = [p.confidence for p in topk.predictions]
    assert confidences == sorted(confidences, reverse=True)


def test_stub_cannot_reach_the_advise_band() -> None:
    """The property that matters: no gate path turns stub output into advice.

    Top-1 sits below FLOOR, so the floor check escalates. The top1-top2 gap sits
    below MARGIN, so even if the checks were reordered the worst case is clarify.
    """
    predictions = classify(b"x").predictions
    top1, top2 = predictions[0].confidence, predictions[1].confidence

    assert top1 < config.FLOOR
    assert top1 - top2 < config.MARGIN


def test_real_model_is_not_silently_stubbed(monkeypatch: pytest.MonkeyPatch) -> None:
    """With VISION_MODEL=real and no model, classify() must fail loudly rather
    than quietly serving stub output."""
    monkeypatch.setattr(settings, "vision_model", "real")
    with pytest.raises(NotImplementedError):
        classify(b"x")
