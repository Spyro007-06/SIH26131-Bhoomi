"""POST /farms/{id}/diagnose -- the orchestration. docs/API_CONTRACT.md §6.

Calls diagnose_farm() directly rather than through TestClient/HTTP: the
client fixture's TestClient runs against app.db's own engine, a separate
connection from db_session's rolled-back-on-teardown transaction, so data
created here would be invisible to it (or would leak permanently if made
visible). diagnose_farm() is a plain async function -- FastAPI route
handlers always are -- so it is called directly with a real Farm/Asset row
from the same session, same style test_alert_response.py already uses for
alerts_service.record_response().

Everything here was ALSO verified live over real HTTP -- see the task's
pasted curl output -- this file is the regression net, not the first proof.
"""

from __future__ import annotations

import uuid

import pytest
from sqlalchemy import select

from app.contracts.enums import AssetKind, Crop, GateOutcome, Role
from app.core.models import Asset, Diagnosis, Farm, LabelPrior, Problem, User
from app.core.routers.diagnose import diagnose_farm
from app.core.schemas.diagnose import DiagnoseIn
from app.deps import Principal
from app.errors import BhoomiError


def _unique_region() -> str:
    """A region string that cannot collide with real seeded/live data.

    LabelPrior's primary key is (region, crop, growth_stage, label) with no
    upsert on the write path this test exercises directly -- a fixed region
    like "Nashik" collided with a real LabelPrior row this suite's own live
    verification had already committed for real (Nashik/paddy/tillering/
    paddy_blast, via POST /cases/{id}/confirm against the same database).
    db_session's rollback-on-teardown isolates what THIS test writes; it does
    not protect against colliding with what already exists.
    """
    return f"probe-{uuid.uuid4()}"


async def _farm(
    session, *, crop: Crop = Crop.PADDY, growth_stage: str = "tillering", region: str | None = None
) -> Farm:
    farmer = User(role=Role.FARMER, phone=f"+9199{uuid.uuid4().int % 10**8:08d}", name="probe")
    session.add(farmer)
    await session.flush()
    farm = Farm(
        farmer_id=farmer.id,
        crop=crop,
        growth_stage=growth_stage,
        region=region or _unique_region(),
        location="SRID=4326;POINT(73.7898 19.9975)",
    )
    session.add(farm)
    await session.flush()
    return farm


async def _asset(session, farm: Farm) -> Asset:
    asset = Asset(
        kind=AssetKind.IMAGE, content_type="image/jpeg",
        object_key=f"probe/{uuid.uuid4()}.jpg", farm_id=farm.id,
    )
    session.add(asset)
    await session.flush()
    return asset


async def _diagnose(session, farm: Farm, fixture: str | None) -> object:
    asset = await _asset(session, farm)
    payload = DiagnoseIn(image_asset_id=asset.id, lang="mr-IN")
    principal = Principal(subject=farm.farmer_id, role=Role.FARMER)
    return await diagnose_farm(
        farm_id=farm.id, payload=payload, x_vision_fixture=fixture,
        principal=principal, session=session,
    )


# --- the four fixtures, each gate outcome ------------------------------------


async def test_low_confidence_escalates_below_floor(db_session) -> None:
    farm = await _farm(db_session)
    out = await _diagnose(db_session, farm, "low_confidence")

    assert out.gate.outcome == "escalate"
    assert out.gate.reason_code == "BELOW_FLOOR"
    assert out.gate.is_stub is True
    assert len(out.gate.alternatives) == 3
    assert out.escalation is not None
    assert out.escalation.case_id is not None


async def test_torn_is_ambiguous_then_escalated_no_cue_exists(db_session) -> None:
    """DistinguishingCue is empty in this environment -- docs/DESIGN.md §7's
    "not found -> escalate". reason_code stays AMBIGUOUS (why); outcome
    reports escalate (what actually happened)."""
    farm = await _farm(db_session)
    out = await _diagnose(db_session, farm, "torn")

    assert out.gate.outcome == "escalate"
    assert out.gate.reason_code == "AMBIGUOUS"
    assert out.escalation is not None


async def test_out_of_scope_escalates(db_session) -> None:
    farm = await _farm(db_session)
    out = await _diagnose(db_session, farm, "out_of_scope")

    assert out.gate.outcome == "escalate"
    assert out.gate.reason_code == "OUT_OF_SCOPE"
    assert out.escalation is not None


async def test_confident_reaches_advise_and_is_refused_not_composed(db_session) -> None:
    """The gate.py deployed today is the Phase 2 implementation -- it does
    not consult retrieval_score at all (see app/intelligence/gate.py's own
    module docstring), so a confident, in-scope, unambiguous prediction
    reaches advise even with zero corpus rows loaded. This build refuses to
    compose an advisory rather than fabricate one -- 501, not a bug."""
    farm = await _farm(db_session)

    with pytest.raises(BhoomiError) as caught:
        await _diagnose(db_session, farm, "confident")

    assert caught.value.code.value == "NOT_IMPLEMENTED"
    assert caught.value.status_code == 501


# --- no advisory/clarification object on any non-advise path ----------------


async def test_no_advisory_or_clarification_field_on_any_response(db_session) -> None:
    """Only `escalation` is ever populated by this build. Asserted against
    the response body's own field set, not just the service return, per the
    task's testable-invariant list."""
    farm = await _farm(db_session)
    for fixture in ("low_confidence", "torn", "out_of_scope"):
        out = await _diagnose(db_session, farm, fixture)
        dumped = out.model_dump(exclude_none=True)
        assert "advisory" not in dumped
        assert "clarification" not in dumped
        assert "escalation" in dumped


# --- the Problem/Diagnosis record, written regardless of branch -------------


async def test_problem_and_diagnosis_are_recorded_even_on_the_501_branch(db_session) -> None:
    farm = await _farm(db_session)
    with pytest.raises(BhoomiError):
        await _diagnose(db_session, farm, "confident")

    problems = (
        await db_session.execute(select(Problem).where(Problem.farm_id == farm.id))
    ).scalars().all()
    assert len(problems) == 1
    assert problems[0].label == "paddy_blast"
    assert problems[0].problem_type == "disease"

    diagnoses = (
        await db_session.execute(select(Diagnosis).where(Diagnosis.problem_id == problems[0].id))
    ).scalars().all()
    assert len(diagnoses) == 1
    assert diagnoses[0].gate_outcome == GateOutcome.ADVISE
    assert diagnoses[0].is_stub is True


async def test_repeated_diagnose_on_the_same_label_reuses_the_open_problem(db_session) -> None:
    """_upsert_open_problem: a second diagnose call against the same
    (farm, label) must not create a duplicate Problem row."""
    farm = await _farm(db_session)
    first = await _diagnose(db_session, farm, "low_confidence")
    second = await _diagnose(db_session, farm, "torn")

    assert first.problem_id == second.problem_id
    problems = (
        await db_session.execute(select(Problem).where(Problem.farm_id == farm.id))
    ).scalars().all()
    assert len(problems) == 1


# --- the prior clamp holds through the full orchestration -------------------


async def test_prior_bias_is_applied_and_clamped_through_the_orchestration(db_session) -> None:
    """A raw bias big enough to flip low_confidence's top-1 across FLOOR would
    turn escalate into something else -- docs/DESIGN.md §11. Seed a
    LabelPrior row whose bias, unclamped, would do exactly that; confirm the
    orchestration still escalates BELOW_FLOOR -- the clamp held end to end,
    not just in prior.py's own unit tests."""
    farm = await _farm(db_session)
    # low_confidence: paddy_blast at 0.38, FLOOR is well above 0.38 + any
    # single-digit-net-confirmation bias -- 50 confirmed vs 0 corrected is
    # far past PRIOR_FULL_CONFIDENCE_COUNT, i.e. the largest bias the system
    # can produce, and it must still not cross FLOOR.
    session_row = LabelPrior(
        region=farm.region, crop=Crop.PADDY.value, growth_stage="tillering",
        label="paddy_blast", confirmed_count=50, corrected_count=0,
    )
    db_session.add(session_row)
    await db_session.flush()

    out = await _diagnose(db_session, farm, "low_confidence")

    assert out.gate.outcome == "escalate"
    assert out.gate.reason_code == "BELOW_FLOOR"
    # The bias was applied (alternatives reflect the post-prior confidence,
    # not the raw fixture value) but stayed clamped under FLOOR.
    top1 = out.gate.alternatives[0]
    assert top1.label == "paddy_blast"
    assert top1.confidence > 0.38
    from app.config import FLOOR

    assert top1.confidence < FLOOR
