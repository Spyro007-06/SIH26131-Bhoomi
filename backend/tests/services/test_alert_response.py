"""alerts_service.record_response — the inspection-tier branch.

The property under test: a target the camera cannot settle must never
suggest the diagnose path, and a `found` on it must open a real Problem and
escalate rather than leave the farmer's observation nowhere. A diagnosable
target's existing behaviour must be unchanged.
"""

from __future__ import annotations

import uuid

from sqlalchemy import select

from app.contracts.enums import AlertOutcome, AlertTrigger, Crop, ProblemType, Role, TargetLabel
from app.core.models import Alert, Case, Farm, Problem, User
from app.core.services.alerts import record_response

TASKS = ["Walk the field today and check ten plants along the bund."]


async def _farm(session) -> Farm:
    farmer = User(role=Role.FARMER, phone=f"+9199{uuid.uuid4().int % 10**8:08d}", name="probe")
    session.add(farmer)
    await session.flush()
    farm = Farm(
        farmer_id=farmer.id,
        crop=Crop.PADDY,
        growth_stage="tillering",
        region="Nashik",
        location="SRID=4326;POINT(73.7898 19.9975)",
    )
    session.add(farm)
    await session.flush()
    return farm


def _alert(farm: Farm, target: TargetLabel) -> Alert:
    return Alert(
        farm_id=farm.id,
        trigger_type=AlertTrigger.WEATHER,
        target=target,
        risk_level="high",
        reason="probe",
        inspection_tasks=TASKS,
    )


# --- diagnosable tier: unchanged ---------------------------------------------


async def test_found_on_a_diagnosable_target_suggests_diagnose_and_opens_nothing(
    db_session,
) -> None:
    farm = await _farm(db_session)
    alert = _alert(farm, TargetLabel.PADDY_BLAST)
    db_session.add(alert)
    await db_session.flush()

    diagnose_suggested, case_id = await record_response(db_session, alert, AlertOutcome.FOUND)

    assert diagnose_suggested is True
    assert case_id is None
    assert alert.outcome == AlertOutcome.FOUND
    problems = (
        await db_session.execute(select(Problem).where(Problem.farm_id == farm.id))
    ).scalars().all()
    assert problems == []


async def test_nothing_found_on_a_diagnosable_target_suggests_nothing(db_session) -> None:
    farm = await _farm(db_session)
    alert = _alert(farm, TargetLabel.PADDY_BLAST)
    db_session.add(alert)
    await db_session.flush()

    diagnose_suggested, case_id = await record_response(
        db_session, alert, AlertOutcome.NOTHING_FOUND
    )
    assert diagnose_suggested is False
    assert case_id is None


# --- inspection tier: the fix -------------------------------------------------


async def test_found_on_an_inspection_target_opens_a_problem_and_escalates(db_session) -> None:
    """paddy_brown_planthopper: alert-and-inspect only, never reaches the gate.
    A photograph cannot settle it, so `found` must not suggest one."""
    farm = await _farm(db_session)
    alert = _alert(farm, TargetLabel.PADDY_BROWN_PLANTHOPPER)
    db_session.add(alert)
    await db_session.flush()

    diagnose_suggested, case_id = await record_response(db_session, alert, AlertOutcome.FOUND)

    assert diagnose_suggested is False
    assert case_id is not None

    case = await db_session.get(Case, case_id)
    assert case is not None
    problem = await db_session.get(Problem, case.problem_id)
    assert problem is not None
    assert problem.farm_id == farm.id
    assert problem.label == TargetLabel.PADDY_BROWN_PLANTHOPPER
    assert problem.problem_type == ProblemType.PEST


async def test_a_second_crop_inspection_target_reads_its_own_map_entry(db_session) -> None:
    """Guards against the classification silently defaulting to one value:
    a different crop, different target, its own TARGET_PROBLEM_TYPES entry."""
    farm = await _farm(db_session)
    alert = _alert(farm, TargetLabel.SOYBEAN_STEM_FLY)
    db_session.add(alert)
    await db_session.flush()

    _, case_id = await record_response(db_session, alert, AlertOutcome.FOUND)
    case = await db_session.get(Case, case_id)
    problem = await db_session.get(Problem, case.problem_id)
    assert problem.label == TargetLabel.SOYBEAN_STEM_FLY
    assert problem.problem_type == ProblemType.PEST


async def test_snoozed_on_an_inspection_target_opens_nothing(db_session) -> None:
    farm = await _farm(db_session)
    alert = _alert(farm, TargetLabel.PADDY_BROWN_PLANTHOPPER)
    db_session.add(alert)
    await db_session.flush()

    diagnose_suggested, case_id = await record_response(db_session, alert, AlertOutcome.SNOOZED)
    assert diagnose_suggested is False
    assert case_id is None
    problems = (
        await db_session.execute(select(Problem).where(Problem.farm_id == farm.id))
    ).scalars().all()
    assert problems == []
