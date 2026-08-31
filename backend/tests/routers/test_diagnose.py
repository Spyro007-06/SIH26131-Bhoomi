"""POST /vision/classify — the Phase 1 vision fixture / test mode.

The endpoint exists so the three gate bands can be driven by header before
app.intelligence.gate.decide() lands. That is only worth anything if each
fixture is a distribution a bounded classifier could actually return, and if the
numbers are pinned — a downstream owner curling `torn` today must get the same
values tomorrow.

docs/DESIGN.md §12 (flags and stubs), §13 (invariants); contract C1 in §4.
"""

from __future__ import annotations

import pytest
from fastapi.testclient import TestClient

from app import config
from app.config import settings
from app.contracts.enums import TargetLabel
from app.contracts.vision import TOPK_SIZE
from app.core.routers.diagnose import _FIXTURES
from app.vision.classifier import STUB_DISTRIBUTION, STUB_MODEL_VERSION

ENDPOINT = f"{settings.api_prefix}/vision/classify"

# The wire values, written out rather than read back from _FIXTURES. A test that
# imports the thing it is checking passes on any value at all; these numbers are
# what teammates curl against, so changing one should fail here first.
EXPECTED: dict[str, list[tuple[str, float]]] = {
    "confident": [
        ("paddy_blast", 0.85),
        ("paddy_brown_spot", 0.10),
        ("paddy_bacterial_leaf_blight", 0.05),
    ],
    "torn": [
        ("paddy_blast", 0.50),
        ("paddy_brown_spot", 0.46),
        ("paddy_bacterial_leaf_blight", 0.04),
    ],
    "low_confidence": [
        ("paddy_blast", 0.38),
        ("paddy_brown_spot", 0.33),
        ("paddy_bacterial_leaf_blight", 0.29),
    ],
    "out_of_scope": [
        ("paddy_blast", 0.36),
        ("paddy_brown_spot", 0.33),
        ("paddy_bacterial_leaf_blight", 0.31),
    ],
}


@pytest.fixture(autouse=True)
def _force_stub(monkeypatch: pytest.MonkeyPatch) -> None:
    """Fixtures are served in stub mode only, so that is the mode under test.

    Also pins the flag for the whole module: settings is a process-wide
    singleton, and a test that flips it to "real" must not leak that to the next
    one.
    """
    monkeypatch.setattr(settings, "vision_model", "stub")


def _top1_top2(name: str) -> tuple[float, float]:
    predictions = _FIXTURES[name].predictions
    return predictions[0].confidence, predictions[1].confidence


# ---------------------------------------------------------------------------
# The four fixtures, over the wire.
# ---------------------------------------------------------------------------


@pytest.mark.parametrize("name", sorted(EXPECTED))
def test_fixture_returns_its_pinned_distribution(client: TestClient, name: str) -> None:
    response = client.post(ENDPOINT, headers={"X-Vision-Fixture": name})

    assert response.status_code == 200
    body = response.json()
    assert len(body["predictions"]) == TOPK_SIZE
    assert [p["label"] for p in body["predictions"]] == [lbl for lbl, _ in EXPECTED[name]]
    assert [p["confidence"] for p in body["predictions"]] == pytest.approx(
        [c for _, c in EXPECTED[name]]
    )
    assert body["out_of_scope"] is (name == "out_of_scope")
    assert body["model_version"] == STUB_MODEL_VERSION
    assert body["is_stub"] is True


# ---------------------------------------------------------------------------
# What makes a fixture a plausible classifier output rather than free text.
# ---------------------------------------------------------------------------


def test_every_fixture_label_is_in_the_bounded_set() -> None:
    """The failure this catches: `out_of_scope` once returned "wheat_rust".

    A five-class paddy classifier cannot emit it, and these predictions reach
    the client as gate.alternatives, where each label is rendered against
    reference data that exists only for TargetLabel. Out-of-scope is the flag,
    never a label borrowed from another crop.
    """
    bounded = {str(label) for label in TargetLabel}
    offenders = [
        f"{name}: {prediction.label!r}"
        for name, topk in _FIXTURES.items()
        for prediction in topk.predictions
        if prediction.label not in bounded
    ]
    assert not offenders, f"labels outside TargetLabel: {offenders}"


def test_every_fixture_distribution_sums_to_at_most_one() -> None:
    """A TopK is the top THREE of a softmax, so it sums to AT MOST 1.0.

    Changed from == 1.0 in v3. With five classes the top-3 held nearly all the
    mass and equality was almost true; with 26 it is simply wrong — the other 23
    classes hold the remainder, and a fixture forced to sum to exactly 1.0 would
    be asserting the model is certain the answer is in the top three.

    The lower bound is what actually protects the gate: top-1 plus top-2 cannot
    exceed 1.0 either, or MARGIN comparisons stop meaning anything.
    """
    offenders = {
        name: total
        for name, topk in _FIXTURES.items()
        if (total := sum(p.confidence for p in topk.predictions)) > 1.0 + 1e-9
    }
    assert not offenders, f"distributions summing above 1.0: {offenders}"


def test_every_fixture_is_descending_and_bounded() -> None:
    """Each confidence is a probability and the order is the contract's."""
    for name, topk in _FIXTURES.items():
        confidences = [p.confidence for p in topk.predictions]
        assert confidences == sorted(confidences, reverse=True), name
        assert all(0.0 <= c <= 1.0 for c in confidences), name


# ---------------------------------------------------------------------------
# Each fixture lands in the band it advertises — asserted against config, since
# a threshold written into a comment is checked by nothing and believed anyway.
# ---------------------------------------------------------------------------


def test_confident_reaches_the_advise_band() -> None:
    top1, top2 = _top1_top2("confident")
    assert top1 >= config.GATE
    assert top1 - top2 >= config.MARGIN


def test_torn_is_ambiguous_and_above_the_floor() -> None:
    """Two live candidates, neither clear of the other: the Doubt Doctor path."""
    top1, top2 = _top1_top2("torn")
    assert top2 >= config.FLOOR
    assert top1 < config.GATE
    assert top1 - top2 < config.MARGIN


def test_low_confidence_is_below_the_floor() -> None:
    top1, _ = _top1_top2("low_confidence")
    assert top1 < config.FLOOR


def test_out_of_scope_is_flagged_and_carries_no_usable_top1() -> None:
    top1, _ = _top1_top2("out_of_scope")
    assert _FIXTURES["out_of_scope"].out_of_scope is True
    assert top1 < config.FLOOR


# ---------------------------------------------------------------------------
# Refusals.
# ---------------------------------------------------------------------------


def test_fixtures_are_refused_when_the_real_model_is_loaded(
    client: TestClient, monkeypatch: pytest.MonkeyPatch
) -> None:
    """A stray X-Vision-Fixture header must not stand in for real inference.

    docs/DESIGN.md §12: silent stubs are how a demo dies. On a machine running
    VISION_MODEL=real the fixture path is closed, loudly.
    """
    monkeypatch.setattr(settings, "vision_model", "real")

    response = client.post(ENDPOINT, headers={"X-Vision-Fixture": "confident"})

    # v3: FIXTURES_DISABLED / 409, not FORBIDDEN / 403. The caller's identity is
    # irrelevant here — with VISION_MODEL=real nobody may pull a fixture and with
    # stub everybody may. It is a server configuration state, so the code says so.
    assert response.status_code == 409
    assert response.json()["error"]["code"] == "FIXTURES_DISABLED"


def test_unrecognised_fixture_name_is_a_422(client: TestClient) -> None:
    """A typo'd header used to fall through to the stub's near-uniform
    distribution, which looks like a gate bug rather than a bad request.

    v3: 422, not 400. VALIDATION_FAILED returned both depending on the call
    site, so a client switching on `code` could not predict the status — which
    is most of what a stable envelope is for. One code, one status."""
    response = client.post(ENDPOINT, headers={"X-Vision-Fixture": "cofident"})

    assert response.status_code == 422
    error = response.json()["error"]
    assert error["code"] == "VALIDATION_FAILED"
    assert error["details"]["known_fixtures"] == sorted(_FIXTURES)


# ---------------------------------------------------------------------------
# The no-header fallback.
# ---------------------------------------------------------------------------


def test_no_header_returns_the_inert_stub(client: TestClient) -> None:
    response = client.post(ENDPOINT)

    assert response.status_code == 200
    body = response.json()
    assert [p["label"] for p in body["predictions"]] == [lbl for lbl, _ in STUB_DISTRIBUTION]
    assert [p["confidence"] for p in body["predictions"]] == pytest.approx(
        [c for _, c in STUB_DISTRIBUTION]
    )
    assert body["is_stub"] is True


def test_no_header_returns_the_stub_without_reaching_the_classifier(
    client: TestClient, monkeypatch: pytest.MonkeyPatch
) -> None:
    """The refusal above is aimed at a stray fixture header, not at the endpoint:
    a missing header keeps its existing behaviour in every mode.

    This is also how the suite proves the fallback no longer calls classify(b"").
    Empty bytes are harmless to the stub and are garbage — or a crash — to the
    real model, and classify() under VISION_MODEL=real raises
    NotImplementedError. A 200 here means nothing on this path reached it.
    """
    monkeypatch.setattr(settings, "vision_model", "real")

    response = client.post(ENDPOINT)

    assert response.status_code == 200
    assert response.json()["is_stub"] is True
