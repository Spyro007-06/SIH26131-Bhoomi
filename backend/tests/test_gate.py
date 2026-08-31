"""The confidence gate (F2) against Phase 1's vision fixtures.

docs/DESIGN.md §6. Runs decide() against the same four TopK objects the
POST /vision/classify fixture endpoint serves, so the gate is exercised
against realistic band-boundary values before any real corpus content exists
(Phase 2 brief: zero dependency on the corpus or registered_use.csv here).
"""

from __future__ import annotations

from app.core.routers.diagnose import _FIXTURES
from app.intelligence.gate import decide


def test_confident_fixture_advises() -> None:
    decision = decide(_FIXTURES["confident"], None)
    assert decision.outcome == "advise"
    assert decision.reason_code == "ABOVE_GATE"


def test_torn_fixture_goes_to_doubt_doctor() -> None:
    """blast vs brown_spot — the intended Doubt Doctor demo pair."""
    decision = decide(_FIXTURES["torn"], None)
    assert decision.outcome == "clarify"
    assert decision.reason_code == "AMBIGUOUS"
    competing = {p.label for p in decision.alternatives[:2]}
    assert competing == {"blast", "brown_spot"}


def test_low_confidence_fixture_escalates() -> None:
    decision = decide(_FIXTURES["low_confidence"], None)
    assert decision.outcome == "escalate"
    assert decision.reason_code == "BELOW_FLOOR"


def test_out_of_scope_fixture_escalates_regardless_of_confidence() -> None:
    """0.91 is well above GATE — the out-of-scope check must still win."""
    decision = decide(_FIXTURES["out_of_scope"], None)
    assert decision.outcome == "escalate"
    assert decision.reason_code == "OUT_OF_SCOPE"


def test_alternatives_are_always_populated() -> None:
    """docs/API_CONTRACT.md §17 invariant 3, on every branch including advise."""
    for fixture in _FIXTURES.values():
        assert decide(fixture, None).alternatives
