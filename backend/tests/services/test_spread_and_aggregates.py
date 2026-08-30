"""F6 spread and F15 aggregates, with the invariant docs/DESIGN.md §13 names:

    "Only confirmed diagnoses drive spread alerts and hotspot points."

The tests that carry this file are the negative ones — a problem with a
diagnosis and no confirmation must produce zero spread alerts and zero hotspot
points. docs/DESIGN.md §10: an unconfirmed model output triggering village-wide
alarm "is how a system loses trust in one afternoon".

---------------------------------------------------------------------------
Test geography is ISOLATED from the seed, deliberately.

ST_DWithin does not care about `region`, so test farms placed at the real Nashik
coordinates fall inside 2 km of the SEEDED farms A and B — which these tests can
see. The db_session fixture rolls back what a test writes; it does not hide rows
that were already committed. propagate() then correctly found five neighbours
and the assertion about one was wrong: the test, not the code.

So each test gets a random base far from any real farm, with the Phase 1 offsets
applied so the geometry under test is unchanged:

    base -> near   1527 m   inside SPREAD_RADIUS_M (2000)
    base -> far   22256 m   outside
---------------------------------------------------------------------------
"""

from __future__ import annotations

import ast
import inspect
import random
import uuid
from datetime import UTC, datetime

import pytest
from sqlalchemy import select

from app.config import SPREAD_RADIUS_M
from app.contracts.enums import (
    AlertTrigger,
    ConfirmationVerdict,
    Crop,
    GateOutcome,
    GateReasonCode,
    GrowthStage,
    ProblemType,
    Role,
    TargetLabel,
)
from app.core.models import Alert, Case, Diagnosis, Farm, LabelPrior, Problem, User
from app.core.services import aggregates
from app.core.services import spread as spread_module
from app.core.services.confirmation import confirm_case
from app.core.services.spread import neighbours_within_radius, propagate

NEAR_OFFSET = (-0.00420, +0.01390)   # ~1527 m, seed farm A -> B
FAR_OFFSET = (+0.09550, +0.18720)    # ~22 km,  seed farm A -> C


def isolated_base() -> tuple[float, float]:
    """A random empty point, nowhere near the seeded Nashik farms."""
    return (
        round(random.uniform(-40.0, -20.0), 5),
        round(random.uniform(-60.0, -30.0), 5),
    )


def offset(base: tuple[float, float], delta: tuple[float, float]) -> tuple[float, float]:
    return (round(base[0] + delta[0], 5), round(base[1] + delta[1], 5))


async def _farm(session, coords, crop=Crop.PADDY, region="Probe") -> Farm:
    farmer = User(role=Role.FARMER, phone=f"+9197{uuid.uuid4().int % 10**9:09d}", name="probe")
    session.add(farmer)
    await session.flush()
    lat, lng = coords
    farm = Farm(
        farmer_id=farmer.id, crop=crop, growth_stage=GrowthStage.TILLERING,
        region=region, location=f"SRID=4326;POINT({lng} {lat})",
    )
    session.add(farm)
    await session.flush()
    return farm


async def _problem(session, farm, label=TargetLabel.BLAST) -> Problem:
    problem = Problem(farm_id=farm.id, problem_type=ProblemType.DISEASE, label=label)
    session.add(problem)
    await session.flush()
    return problem


async def _diagnosed(session, problem) -> Diagnosis:
    diagnosis = Diagnosis(
        problem_id=problem.id,
        topk={"predictions": [{"label": "blast", "confidence": 0.58}]},
        gate_outcome=GateOutcome.CLARIFY, gate_confidence=0.58,
        reason_code=GateReasonCode.AMBIGUOUS, model_version="probe", is_stub=False,
    )
    session.add(diagnosis)
    await session.flush()
    return diagnosis


async def _agronomist(session) -> User:
    user = User(
        role=Role.AGRONOMIST, email=f"a{uuid.uuid4().hex[:8]}@kvk.example",
        name="probe", password_hash="x",
    )
    session.add(user)
    await session.flush()
    return user


async def _case(session, problem, agronomist) -> Case:
    case = Case(problem_id=problem.id, assigned_to=agronomist.id)
    session.add(case)
    await session.flush()
    return case


# ===========================================================================
# THE invariant: only confirmed diagnoses propagate
# ===========================================================================


def test_spread_has_no_code_path_from_a_diagnosis() -> None:
    """docs/DESIGN.md §13. Structural, not behavioural: the module never reads
    Diagnosis at all, so there is no filter anyone could later remove.

    Checked over the AST rather than the source text — the word appears in the
    module's own docstring explaining why it is absent from the code, and a
    substring search cannot tell the two apart.
    """
    tree = ast.parse(inspect.getsource(spread_module))
    referenced = {
        node.id for node in ast.walk(tree) if isinstance(node, ast.Name)
    } | {
        node.attr for node in ast.walk(tree) if isinstance(node, ast.Attribute)
    } | {
        alias.name for node in ast.walk(tree)
        if isinstance(node, ast.ImportFrom) for alias in node.names
    }
    assert "Diagnosis" not in referenced, (
        "spread.py references Diagnosis in code - the only route in is a Confirmation"
    )
    assert "Confirmation" in inspect.getdoc(spread_module), (
        "the docstring must state the only route in"
    )


async def test_a_diagnosed_but_unconfirmed_problem_warns_nobody(db_session) -> None:
    """Behavioural half. A diagnosis exists, no confirmation, so no alert lands
    on the neighbour — because nothing calls propagate()."""
    base = isolated_base()
    origin = await _farm(db_session, base)
    neighbour = await _farm(db_session, offset(base, NEAR_OFFSET))
    problem = await _problem(db_session, origin)
    await _diagnosed(db_session, problem)

    alerts = (
        await db_session.execute(select(Alert).where(Alert.farm_id == neighbour.id))
    ).scalars().all()
    assert list(alerts) == []


async def test_an_unconfirmed_diagnosis_contributes_no_hotspot_point(db_session) -> None:
    """docs/API_CONTRACT.md §17 invariant 10, at the aggregate."""
    farm = await _farm(db_session, isolated_base(), region="Probe-Unconfirmed")
    problem = await _problem(db_session, farm)
    await _diagnosed(db_session, problem)

    points, totals = await aggregates.hotspots(db_session, region="Probe-Unconfirmed")
    assert points == []
    assert totals == {}


async def test_a_confirmation_does_contribute_a_hotspot_point(db_session) -> None:
    """The control. An invariant that hides everything is not an invariant."""
    farm = await _farm(db_session, isolated_base(), region="Probe-Confirmed")
    problem = await _problem(db_session, farm)
    await _diagnosed(db_session, problem)
    agronomist = await _agronomist(db_session)
    case = await _case(db_session, problem, agronomist)

    await confirm_case(
        db_session, case=case, agronomist_id=agronomist.id,
        verdict=ConfirmationVerdict.CONFIRMED,
    )

    points, totals = await aggregates.hotspots(db_session, region="Probe-Confirmed")
    assert any(p.label == "blast" and p.confirmed_count >= 1 for p in points)
    assert totals.get("blast", 0) >= 1


# ===========================================================================
# Radius
# ===========================================================================


async def test_radius_reaches_the_near_farm_and_not_the_far_one(db_session) -> None:
    """1527 m in, 22 km out — the Phase 1 seed geometry, same offsets."""
    base = isolated_base()
    origin = await _farm(db_session, base)
    near = await _farm(db_session, offset(base, NEAR_OFFSET))
    far = await _farm(db_session, offset(base, FAR_OFFSET))

    ids = {f.id for f in await neighbours_within_radius(db_session, origin)}
    assert near.id in ids
    assert far.id not in ids
    assert origin.id not in ids, "the origin must not warn itself"


async def test_propagate_issues_one_alert_per_neighbour(db_session) -> None:
    base = isolated_base()
    origin = await _farm(db_session, base)
    near = await _farm(db_session, offset(base, NEAR_OFFSET))
    await _farm(db_session, offset(base, FAR_OFFSET))

    report = await propagate(db_session, origin, TargetLabel.BLAST)
    assert (report.neighbours, report.issued, report.upgraded) == (1, 1, 0)
    assert report.total == 1
    assert report.farm_ids == [near.id]


def test_the_radius_query_is_crop_scoped() -> None:
    """Only paddy exists in the frozen enum today, so this asserts the predicate
    is present rather than exercising two crops."""
    source = inspect.getsource(neighbours_within_radius)
    assert "Farm.crop == origin.crop" in source


# ===========================================================================
# The upgrade path
# ===========================================================================


async def test_an_existing_same_day_alert_is_upgraded_not_skipped(db_session) -> None:
    """Migration 0004's unique index would otherwise silently suppress the most
    important alert this system can send."""
    base = isolated_base()
    origin = await _farm(db_session, base)
    near = await _farm(db_session, offset(base, NEAR_OFFSET))

    existing = Alert(
        farm_id=near.id, trigger_type=AlertTrigger.WEATHER, target=TargetLabel.BLAST,
        risk_level="moderate", reason="Humidity stayed above 90% for 4 consecutive days.",
        inspection_tasks=["Walk a diagonal line and check ten upper leaves today."],
        outcome="nothing_found",
    )
    db_session.add(existing)
    await db_session.flush()

    report = await propagate(db_session, origin, TargetLabel.BLAST)
    assert (report.issued, report.upgraded) == (0, 1)
    assert report.total == 1, "an upgraded card still warns a farm"

    await db_session.refresh(existing)
    assert existing.trigger_type == AlertTrigger.COMBINED
    assert existing.risk_level == "high", "takes the higher of the two levels"
    assert "Humidity stayed above 90%" in existing.reason, "original reason kept"
    assert "confirmed by an agronomist" in existing.reason, "spread clause appended"
    assert existing.outcome is None, "a stale answer to the old alert is cleared"
    assert len(existing.inspection_tasks) > 1
    assert len(existing.inspection_tasks) == len(set(existing.inspection_tasks))


async def test_upgrading_twice_does_not_duplicate_the_reason(db_session) -> None:
    base = isolated_base()
    origin = await _farm(db_session, base)
    near = await _farm(db_session, offset(base, NEAR_OFFSET))
    db_session.add(
        Alert(
            farm_id=near.id, trigger_type=AlertTrigger.WEATHER, target=TargetLabel.BLAST,
            risk_level="low", reason="Weather window.",
            inspection_tasks=["Walk a diagonal line and check ten leaves today."],
        )
    )
    await db_session.flush()

    await propagate(db_session, origin, TargetLabel.BLAST)
    alert = (
        await db_session.execute(select(Alert).where(Alert.farm_id == near.id))
    ).scalar_one()
    once = alert.reason

    await propagate(db_session, origin, TargetLabel.BLAST)
    await db_session.refresh(alert)
    assert alert.reason == once, "the spread clause is appended once, not per call"


# ===========================================================================
# Confirmation effects
# ===========================================================================


async def test_confirmation_moves_both_prior_counters_on_a_correction(db_session) -> None:
    """docs/DESIGN.md §11. The model's label was wrong AND the corrected label
    was right; recording only one would flatter the model in F15."""
    farm = await _farm(db_session, isolated_base(), region="Probe-Correction")
    problem = await _problem(db_session, farm, label=TargetLabel.BLAST)
    agronomist = await _agronomist(db_session)
    case = await _case(db_session, problem, agronomist)

    result = await confirm_case(
        db_session, case=case, agronomist_id=agronomist.id,
        verdict=ConfirmationVerdict.CORRECTED, corrected_label=TargetLabel.BROWN_SPOT,
    )

    assert result.label_before == "blast"
    assert result.label_after == "brown_spot", "the case file says what it actually was"

    rows = {
        (r.label.value if hasattr(r.label, "value") else r.label): r
        for r in (
            await db_session.execute(
                select(LabelPrior).where(LabelPrior.region == "Probe-Correction")
            )
        ).scalars().all()
    }
    assert rows["blast"].corrected_count >= 1
    assert rows["brown_spot"].confirmed_count >= 1


async def test_confirmation_resolves_the_problem_and_the_case(db_session) -> None:
    farm = await _farm(db_session, isolated_base())
    problem = await _problem(db_session, farm)
    agronomist = await _agronomist(db_session)
    case = await _case(db_session, problem, agronomist)

    result = await confirm_case(
        db_session, case=case, agronomist_id=agronomist.id,
        verdict=ConfirmationVerdict.CONFIRMED,
    )
    assert result.problem.status.value == "resolved"
    assert result.problem.resolved_at is not None
    assert result.case.status.value == "resolved"
    assert datetime.now(UTC) >= result.problem.resolved_at


# ===========================================================================
# Accuracy
# ===========================================================================


def test_accuracy_is_none_not_zero_when_nothing_reviewed() -> None:
    """A label nobody has reviewed has undefined accuracy. Rendering 0.0 would
    put a bar at the bottom of the chart implying the model is always wrong."""
    assert aggregates.AccuracyRow(label="blast", confirmed=0, corrected=0).accuracy is None


@pytest.mark.parametrize(
    ("confirmed", "corrected", "expected"),
    [(12, 3, 0.8), (5, 6, 0.45), (1, 0, 1.0), (0, 4, 0.0)],
)
def test_accuracy_ratio(confirmed, corrected, expected) -> None:
    row = aggregates.AccuracyRow(label="blast", confirmed=confirmed, corrected=corrected)
    assert row.accuracy == expected


def test_spread_radius_comes_from_config() -> None:
    """No radius literal outside config. docs/DESIGN.md §6."""
    assert SPREAD_RADIUS_M == 2000
