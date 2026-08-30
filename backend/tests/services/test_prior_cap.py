"""The prior cannot move a prediction across a gate band.

docs/DESIGN.md §13 lists this as one of the nine invariants, and §11 says why:
"A prior that can push a prediction over the gate threshold means the system
becomes confident because of history rather than evidence — which is a
fabrication path wearing a statistics hat."

This is a PROPERTY test, not three examples. The whole job of `apply()` is to be
bounded, and a bound is not evidenced by hand-picked cases: it is evidenced by
sweeping the space and finding no counterexample. The sweep below covers every
(top1, top2, bias) combination on a fine grid, including the boundaries
themselves.
"""

from __future__ import annotations

import pytest

from app import config
from app.contracts.vision import Prediction, TopK
from app.core.services.prior import apply, bias_from_counts

# ---------------------------------------------------------------------------
# Reference gate.
#
# Transcribed from docs/DESIGN.md §6 because the real one
# (app/intelligence/gate.py, Thaariha) raises NotImplementedError. The ORDER
# matters and is the whole point: the floor check runs BEFORE the ambiguity
# check, which is why the cap alone does not protect the escalate/clarify
# boundary.
#
# When decide() lands, replace this with a call to it. If the two ever disagree,
# the real gate is right and this is wrong.
# ---------------------------------------------------------------------------


def reference_gate(topk: TopK) -> str:
    top1 = topk.predictions[0].confidence
    top2 = topk.predictions[1].confidence
    if topk.out_of_scope:
        return "escalate"
    if top1 < config.FLOOR:
        return "escalate"
    if top1 - top2 < config.MARGIN:
        return "clarify"
    if top1 < config.GATE:
        return "escalate"
    return "advise"


def _topk(top1: float, top2: float, top3: float = 0.0) -> TopK:
    return TopK(
        predictions=[
            Prediction(label="blast", confidence=top1),
            Prediction(label="brown_spot", confidence=top2),
            Prediction(label="bacterial_leaf_blight", confidence=top3),
        ],
        out_of_scope=False,
        model_version="property-test",
        is_stub=False,
    )


def _grid() -> list[tuple[float, float, float]]:
    """(top1, top2, bias) across the range, boundaries included.

    Steps of 0.01 over confidence, plus the exact threshold values and the
    points one step either side of them — an off-by-one in a comparison hides
    in exactly those places.
    """
    edges = {
        config.FLOOR, config.GATE, config.MARGIN,
        config.FLOOR - 0.01, config.FLOOR + 0.01,
        config.GATE - 0.01, config.GATE + 0.01,
    }
    tops = sorted({round(x / 100, 4) for x in range(0, 101)} | edges)
    biases = sorted(
        {0.0, config.PRIOR_MAX_BIAS, config.PRIOR_MAX_BIAS / 2, config.PRIOR_MAX_BIAS / 10}
    )

    cases: list[tuple[float, float, float]] = []
    for top1 in tops:
        if not 0.0 <= top1 <= 1.0:
            continue
        for top2 in tops:
            if top2 > top1 or not 0.0 <= top2 <= 1.0:
                continue
            for bias in biases:
                cases.append((top1, top2, bias))
    return cases


GRID = _grid()


def test_the_grid_is_actually_large() -> None:
    """Guards the guard: a property test that sweeps four cases proves nothing."""
    assert len(GRID) > 15_000, f"grid is only {len(GRID)} cases"


def test_prior_never_changes_the_gate_outcome() -> None:
    """THE invariant. Every case in the grid, outcome before == outcome after."""
    failures: list[str] = []

    for top1, top2, bias in GRID:
        before = _topk(top1, top2)
        after = apply(before, {"blast": bias})

        outcome_before = reference_gate(before)
        outcome_after = reference_gate(after)
        if outcome_before != outcome_after:
            failures.append(
                f"top1={top1} top2={top2} bias={bias}: "
                f"{outcome_before} -> {outcome_after} "
                f"(top1 became {after.predictions[0].confidence})"
            )

    assert not failures, (
        f"{len(failures)} of {len(GRID)} cases crossed a band. First five:\n  "
        + "\n  ".join(failures[:5])
    )


def test_the_cap_alone_would_not_have_been_enough() -> None:
    """Documents WHY apply() clamps rather than trusting the constants.

    app/config.py asserts PRIOR_MAX_BIAS < MARGIN and < (GATE - FLOOR). Both
    hold. Both are necessary. Neither prevents this, because the gate tests the
    floor before it tests ambiguity.

    If this test ever starts failing, the clamp has become redundant — which
    would be good news, but check why before deleting it.
    """
    assert config.PRIOR_MAX_BIAS < config.MARGIN
    assert config.PRIOR_MAX_BIAS < (config.GATE - config.FLOOR)

    crossings = [
        (top1, top2, bias)
        for top1, top2, bias in GRID
        if reference_gate(_topk(top1, top2))
        != reference_gate(apply(_topk(top1, top2), {"blast": bias}, clamp=False))
    ]
    assert crossings, (
        "expected the unclamped prior to cross a band somewhere in the grid; "
        "if it no longer does, the constants changed"
    )


def test_the_clamp_never_increases_the_bias() -> None:
    """A clamp that could raise the nudge would be a different bug."""
    for top1, top2, bias in GRID:
        before = _topk(top1, top2)
        after = apply(before, {"blast": bias})
        delta = after.predictions[0].confidence - top1
        assert -1e-9 <= delta <= bias + 1e-9, f"delta {delta} outside [0, {bias}]"


def test_apply_preserves_the_contract_shape() -> None:
    """Still exactly 3 predictions, still descending — TopK validates both, so a
    reordering bug would raise rather than pass silently."""
    for top1, top2, bias in GRID[::97]:
        after = apply(_topk(top1, top2), {"blast": bias})
        assert len(after.predictions) == 3
        confidences = [p.confidence for p in after.predictions]
        assert confidences == sorted(confidences, reverse=True)


def test_apply_leaves_other_labels_alone() -> None:
    """Only top-1 is nudged. Adjusting every candidate by its own prior would
    let history reorder the list, which is a larger claim than §11 makes."""
    before = _topk(0.80, 0.10, 0.05)
    after = apply(before, {"brown_spot": config.PRIOR_MAX_BIAS})
    assert after.predictions == before.predictions


# --- the arithmetic itself --------------------------------------------------


@pytest.mark.parametrize(
    ("confirmed", "corrected", "expected_fraction"),
    [
        (0, 0, 0.0),
        (5, 5, 0.0),      # corrected as often as confirmed earns nothing
        (3, 5, 0.0),      # net negative floors at zero
        (5, 0, 0.5),
        (10, 0, 1.0),
        (100, 0, 1.0),    # saturates
        (12, 2, 1.0),
    ],
)
def test_bias_arithmetic_is_readable(confirmed, corrected, expected_fraction) -> None:
    assert bias_from_counts(confirmed, corrected) == pytest.approx(
        expected_fraction * config.PRIOR_MAX_BIAS
    )


def test_bias_never_exceeds_the_cap() -> None:
    for confirmed in range(0, 200, 7):
        for corrected in range(0, 200, 11):
            assert 0.0 <= bias_from_counts(confirmed, corrected) <= config.PRIOR_MAX_BIAS
