"""The three frozen contracts import cleanly and hold their stated shape.

docs/DESIGN.md §4. If one of these fails, four workstreams are building against
something that changed.
"""

from __future__ import annotations

import uuid
from datetime import UTC, datetime

import pytest
from pydantic import ValidationError

from app.contracts import (
    ENDORSEMENT_VOCABULARY,
    SRID,
    TOPK_SIZE,
    VERDICT_MESSAGES,
    Farm,
    GateDecision,
    GeoPoint,
    Prediction,
    TopK,
    VerdictCode,
    enums,
    phi_conflict_message,
)


def _topk(*confidences: float, **kw) -> TopK:
    labels = ["blast", "brown_spot", "bacterial_leaf_blight"]
    return TopK(
        predictions=[
            Prediction(label=lbl, confidence=c) for lbl, c in zip(labels, confidences, strict=False)
        ],
        out_of_scope=kw.pop("out_of_scope", False),
        model_version=kw.pop("model_version", "test-1"),
        is_stub=kw.pop("is_stub", False),
    )


# --- C1 · vision -> intelligence -------------------------------------------


def test_topk_accepts_exactly_three_descending_predictions() -> None:
    topk = _topk(0.87, 0.09, 0.04)
    assert len(topk.predictions) == TOPK_SIZE


def test_topk_rejects_wrong_length() -> None:
    with pytest.raises(ValidationError):
        TopK(
            predictions=[Prediction(label="blast", confidence=0.9)],
            out_of_scope=False,
            model_version="test-1",
            is_stub=False,
        )


def test_topk_rejects_unsorted_predictions() -> None:
    """The gate reads predictions[0]/[1] as top-1/top-2. An unsorted list would
    make every downstream threshold comparison silently wrong."""
    with pytest.raises(ValidationError):
        _topk(0.09, 0.87, 0.04)


def test_confidence_is_bounded() -> None:
    with pytest.raises(ValidationError):
        Prediction(label="blast", confidence=1.4)


# --- C2 · core -> everyone --------------------------------------------------


def test_farm_requires_location() -> None:
    """docs/DESIGN.md §4: F6 and F15 are inoperable without geolocation."""
    with pytest.raises(ValidationError):
        Farm(
            id=uuid.uuid4(),
            farmer_id=uuid.uuid4(),
            crop="paddy",
            growth_stage="tillering",
            region="Nashik",
            created_at=datetime.now(UTC),
        )


def test_farm_round_trips_with_location() -> None:
    farm = Farm(
        id=uuid.uuid4(),
        farmer_id=uuid.uuid4(),
        crop="paddy",
        variety="Indrayani",
        growth_stage="tillering",
        region="Nashik",
        location=GeoPoint(lat=19.9975, lng=73.7898),
        created_at=datetime.now(UTC),
    )
    assert farm.location.lat == pytest.approx(19.9975)
    assert SRID == 4326


def test_geopoint_rejects_impossible_coordinates() -> None:
    with pytest.raises(ValidationError):
        GeoPoint(lat=91.0, lng=73.0)


# --- C3 · intelligence -> clients -------------------------------------------


def test_gate_decision_carries_alternatives_on_advise() -> None:
    """docs/API_CONTRACT.md §17 invariant 3: alternatives populated on every
    branch, including advise. The farmer always sees what else was considered."""
    decision = GateDecision(
        outcome="advise",
        confidence=0.87,
        threshold_applied=0.70,
        reason_code="ABOVE_GATE",
        alternatives=_topk(0.87, 0.09, 0.04).predictions,
    )
    assert decision.alternatives


def test_gate_decision_rejects_an_invented_outcome() -> None:
    with pytest.raises(ValidationError):
        GateDecision(
            outcome="maybe",
            confidence=0.5,
            threshold_applied=0.7,
            reason_code="ABOVE_GATE",
            alternatives=[],
        )


# --- F8 verdict copy · docs/DESIGN.md §9 ------------------------------------


def test_all_six_verdict_codes_have_a_message() -> None:
    assert set(VERDICT_MESSAGES) == set(VerdictCode)
    assert len(VERDICT_MESSAGES) == 6


@pytest.mark.parametrize("code", list(VerdictCode))
def test_no_verdict_message_contains_endorsement_vocabulary(code: VerdictCode) -> None:
    """docs/API_CONTRACT.md §17 invariant 7, and docs/DESIGN.md §9: "Note what is
    absent: any string containing 'safe', 'approved', 'you can use'. The
    vocabulary itself makes endorsement impossible."
    """
    message = VERDICT_MESSAGES[code].lower()
    hits = [word for word in ENDORSEMENT_VOCABULARY if word in message]
    assert not hits, f"{code} message contains endorsement vocabulary {hits}: {message!r}"


def test_phi_substitution_keeps_the_message_endorsement_free() -> None:
    message = phi_conflict_message(30).lower()
    assert "30 days" in message
    assert not [w for w in ENDORSEMENT_VOCABULARY if w in message]


# --- Enums · docs/API_CONTRACT.md §1 ----------------------------------------


def test_enum_wire_values_match_the_contract() -> None:
    """Spot-check the values four workstreams serialise. Renaming any of these
    breaks the Flutter app and the portal at the same time."""
    assert [r.value for r in enums.Role] == ["farmer", "agronomist", "official"]
    assert [o.value for o in enums.GateOutcome] == ["advise", "clarify", "escalate"]
    assert [c.value for c in enums.Crop] == ["paddy", "cotton", "soybean", "jowar"]

    # 26 targets, namespaced by crop. The prefix is not decoration: bacterial
    # blight exists in cotton AND soybean, anthracnose in soybean AND jowar, and
    # unprefixed those would be one value two crops could both hold.
    labels = [t.value for t in enums.TargetLabel]
    assert len(labels) == 26
    assert labels[:5] == [
        "paddy_blast",
        "paddy_brown_spot",
        "paddy_bacterial_leaf_blight",
        "paddy_yellow_stem_borer",
        "paddy_brown_planthopper",
    ]
    for label in labels:
        assert label.split("_", 1)[0] in {c.value for c in enums.Crop}, (
            f"{label} is not namespaced by a known crop"
        )
    assert {"cotton_bacterial_blight", "soybean_bacterial_blight"} <= set(labels)
    assert {"soybean_anthracnose", "jowar_anthracnose"} <= set(labels)

    assert [t.value for t in enums.TargetTier] == ["diagnosable", "inspection"]
    assert set(enums.TARGET_TIERS) == set(enums.TargetLabel), "every target needs a tier"
    assert len(enums.DIAGNOSABLE_TARGETS) == 14
    assert len(enums.INSPECTION_TARGETS) == 12
    assert [t.value for t in enums.LadderTier] == ["cultural", "biological", "chemical"]
    assert enums.LADDER_TIER_ORDER[-1] is enums.LadderTier.CHEMICAL


def test_enums_serialise_as_bare_strings() -> None:
    assert f"{enums.Role.FARMER}" == "farmer"
