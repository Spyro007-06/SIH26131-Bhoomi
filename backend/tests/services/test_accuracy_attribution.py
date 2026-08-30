"""A correction must count against the label the MODEL got wrong.

This is F15's headline metric and it was reporting the inverse. /officials/accuracy
grouped on Problem.label, which a correction has already overwritten with the
corrected label — so a model that said blast and was corrected to brown_spot
showed brown_spot carrying the penalty and blast looking clean.

Migration 0006 freezes Confirmation.model_label at confirm time. These tests pin
the attribution so the bug cannot come back quietly.
"""

from __future__ import annotations

import uuid
from datetime import UTC, datetime, timedelta

from sqlalchemy import select

from app.contracts.enums import (
    ConfirmationVerdict,
    Crop,
    GateOutcome,
    GateReasonCode,
    GrowthStage,
    ProblemType,
    Role,
    TargetLabel,
)
from app.core.models import Case, Confirmation, Diagnosis, Farm, LabelPrior, Problem, User
from app.core.services import aggregates
from app.core.services.confirmation import confirm_case, model_label_at_escalation


async def _setup(session, region: str, model_says=TargetLabel.BLAST, diagnoses: int = 1):
    """A farm, a problem the model labelled `model_says`, and an assigned case."""
    farmer = User(role=Role.FARMER, phone=f"+9196{uuid.uuid4().int % 10**9:09d}", name="probe")
    agronomist = User(
        role=Role.AGRONOMIST, email=f"a{uuid.uuid4().hex[:8]}@kvk.example",
        name="probe", password_hash="x",
    )
    session.add_all([farmer, agronomist])
    await session.flush()

    farm = Farm(
        farmer_id=farmer.id, crop=Crop.PADDY, growth_stage=GrowthStage.TILLERING,
        region=region, location="SRID=4326;POINT(-45.0 -30.0)",
    )
    session.add(farm)
    await session.flush()

    problem = Problem(farm_id=farm.id, problem_type=ProblemType.DISEASE, label=model_says)
    session.add(problem)
    await session.flush()

    opened = datetime.now(UTC) - timedelta(hours=2)
    for index in range(diagnoses):
        session.add(
            Diagnosis(
                problem_id=problem.id,
                topk={"predictions": [{"label": model_says.value, "confidence": 0.58}]},
                gate_outcome=GateOutcome.CLARIFY, gate_confidence=0.58,
                reason_code=GateReasonCode.AMBIGUOUS, model_version="probe",
                is_stub=False, created_at=opened + timedelta(minutes=index),
            )
        )
    await session.flush()

    case = Case(
        problem_id=problem.id, assigned_to=agronomist.id,
        created_at=datetime.now(UTC) - timedelta(hours=1),
    )
    session.add(case)
    await session.flush()
    return farm, problem, case, agronomist


# ===========================================================================
# The attribution
# ===========================================================================


async def test_a_correction_counts_against_the_models_label(db_session) -> None:
    """The bug, pinned. Model said blast, agronomist said brown_spot.

    blast must carry the correction. brown_spot must NOT appear in the accuracy
    view at all — the model never predicted it, and crediting it there would
    inflate its accuracy with a case it had no part in.
    """
    region = f"Probe-{uuid.uuid4().hex[:8]}"
    _, _, case, agronomist = await _setup(db_session, region, model_says=TargetLabel.BLAST)

    result = await confirm_case(
        db_session, case=case, agronomist_id=agronomist.id,
        verdict=ConfirmationVerdict.CORRECTED, corrected_label=TargetLabel.BROWN_SPOT,
    )
    assert result.model_label == "blast"

    rows = {r.label: r for r in await aggregates.accuracy(db_session)}
    assert rows["blast"].corrected >= 1, "the correction belongs to the model's label"

    # Scoped to this run: other tests and the seed share the database.
    confirmation = (
        await db_session.execute(
            select(Confirmation).where(Confirmation.case_id == case.id)
        )
    ).scalar_one()
    assert confirmation.model_label == TargetLabel.BLAST
    assert confirmation.corrected_label == TargetLabel.BROWN_SPOT


async def test_the_prior_still_records_both_facts(db_session) -> None:
    """LabelPrior and the accuracy view answer different questions and count
    differently, on purpose.

        prior     what has been seen here     -> blast wrong AND brown_spot right
        accuracy  how good is the model       -> blast wrong, brown_spot silent
    """
    region = f"Probe-{uuid.uuid4().hex[:8]}"
    _, _, case, agronomist = await _setup(db_session, region, model_says=TargetLabel.BLAST)

    await confirm_case(
        db_session, case=case, agronomist_id=agronomist.id,
        verdict=ConfirmationVerdict.CORRECTED, corrected_label=TargetLabel.BROWN_SPOT,
    )

    priors = {
        (r.label.value if hasattr(r.label, "value") else r.label): r
        for r in (
            await db_session.execute(select(LabelPrior).where(LabelPrior.region == region))
        ).scalars().all()
    }
    assert priors["blast"].corrected_count == 1, "the model was wrong about blast"
    assert priors["blast"].confirmed_count == 0
    assert priors["brown_spot"].confirmed_count == 1, "brown_spot was what it actually was"
    assert priors["brown_spot"].corrected_count == 0


async def test_a_confirmation_counts_for_the_models_label(db_session) -> None:
    """The control. A confirmed verdict credits the label the model predicted."""
    region = f"Probe-{uuid.uuid4().hex[:8]}"
    _, _, case, agronomist = await _setup(
        db_session, region, model_says=TargetLabel.YELLOW_STEM_BORER
    )

    result = await confirm_case(
        db_session, case=case, agronomist_id=agronomist.id,
        verdict=ConfirmationVerdict.CONFIRMED,
    )
    assert result.model_label == "yellow_stem_borer"

    rows = {r.label: r for r in await aggregates.accuracy(db_session)}
    assert rows["yellow_stem_borer"].confirmed >= 1


# ===========================================================================
# model_label is frozen, not derived
# ===========================================================================


async def test_model_label_survives_the_problem_label_being_overwritten(
    db_session,
) -> None:
    """The whole point of the column. After a correction Problem.label is the
    corrected value, and the model's guess is only still knowable because it was
    written down at the time."""
    region = f"Probe-{uuid.uuid4().hex[:8]}"
    _, problem, case, agronomist = await _setup(
        db_session, region, model_says=TargetLabel.BLAST
    )

    result = await confirm_case(
        db_session, case=case, agronomist_id=agronomist.id,
        verdict=ConfirmationVerdict.CORRECTED,
        corrected_label=TargetLabel.BACTERIAL_LEAF_BLIGHT,
    )

    assert problem.label == TargetLabel.BACTERIAL_LEAF_BLIGHT, "case file says what it was"
    assert result.confirmation.model_label == TargetLabel.BLAST, "and what the model said"


async def test_model_label_is_read_from_the_diagnosis_current_at_escalation(
    db_session,
) -> None:
    region = f"Probe-{uuid.uuid4().hex[:8]}"
    _, problem, case, _ = await _setup(db_session, region, model_says=TargetLabel.BROWN_SPOT)

    found = await model_label_at_escalation(db_session, problem.id, case.created_at)
    assert found == "brown_spot"


async def test_model_label_is_null_when_the_problem_never_had_a_diagnosis(
    db_session,
) -> None:
    """A problem escalated from a follow-up rather than a photo. NULL says that
    truthfully; the accuracy view excludes it rather than guessing."""
    region = f"Probe-{uuid.uuid4().hex[:8]}"
    _, _, case, agronomist = await _setup(db_session, region, diagnoses=0)

    result = await confirm_case(
        db_session, case=case, agronomist_id=agronomist.id,
        verdict=ConfirmationVerdict.CONFIRMED,
    )
    assert result.model_label is None
    assert result.confirmation.model_label is None


async def test_rows_with_no_model_label_are_excluded_from_accuracy(db_session) -> None:
    """A case the model never saw is not evidence about the model."""
    region = f"Probe-{uuid.uuid4().hex[:8]}"
    _, _, case, agronomist = await _setup(
        db_session, region, model_says=TargetLabel.BROWN_PLANTHOPPER, diagnoses=0
    )

    before = {r.label: (r.confirmed, r.corrected) for r in await aggregates.accuracy(db_session)}
    await confirm_case(
        db_session, case=case, agronomist_id=agronomist.id,
        verdict=ConfirmationVerdict.CONFIRMED,
    )
    after = {r.label: (r.confirmed, r.corrected) for r in await aggregates.accuracy(db_session)}

    assert after.get("brown_planthopper") == before.get("brown_planthopper"), (
        "a confirmation with no model_label must not move any accuracy row"
    )


async def test_accuracy_no_longer_reads_problem_label(db_session) -> None:
    """Structural guard against the regression. If accuracy() starts grouping on
    Problem.label again, the inversion is back."""
    import ast
    import inspect

    tree = ast.parse(inspect.getsource(aggregates.accuracy))
    grouped = {
        node.attr
        for node in ast.walk(tree)
        if isinstance(node, ast.Attribute) and isinstance(node.value, ast.Name)
        and node.value.id == "Confirmation"
    }
    assert "model_label" in grouped, "accuracy() must group on Confirmation.model_label"
