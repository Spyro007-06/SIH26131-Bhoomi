"""F14 - the confirmation loop.

OWNER: Shreekumar

Writes the Confirmation, resolves the Problem, moves the prior, and fans out
spread alerts. All four in one transaction.

Specified by: docs/DESIGN.md §11, docs/API_CONTRACT.md §13.

-----------------------------------------------------------------------------
One transaction, four effects.

    1. Write the Confirmation row.
    2. Resolve the Problem — and on `corrected`, set Problem.label to the
       corrected label. The case file should say what it actually was, not what
       the model guessed.
    3. Move the LabelPrior counters (services/prior.py).
    4. Fan out spread alerts (services/spread.py) and return the count.

They are one transaction because a half-applied confirmation is worse than none:
neighbours warned about a case that was never recorded, or a resolved problem
whose neighbours were never told. The caller commits; this function only
flushes, so a failure anywhere rolls all four back together.

Language discipline, docs/DESIGN.md §11: this is "learns from field
confirmations". Nothing here trains a model.
-----------------------------------------------------------------------------
"""

from __future__ import annotations

import uuid
from dataclasses import dataclass
from datetime import UTC, datetime

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.contracts.enums import CaseStatus, ConfirmationVerdict, ProblemStatus, TargetLabel
from app.core.models import Case, Confirmation, Diagnosis, Farm, Problem
from app.core.services import prior as prior_service
from app.core.services.spread import SpreadReport, propagate


@dataclass
class ConfirmationResult:
    confirmation: Confirmation
    case: Case
    problem: Problem
    spread: SpreadReport
    label_before: str | None
    label_after: str | None
    model_label: str | None


async def model_label_at_escalation(
    session: AsyncSession, problem_id, escalated_at
) -> str | None:
    """What the model said, from the Diagnosis current when the case was opened.

    Read here rather than derived later: on a correction Problem.label is
    overwritten with the corrected label, so the model's guess stops being
    recoverable the moment the verdict lands. Same reasoning as Alert.reason.

    Returns None when the problem has no diagnosis at all — a problem escalated
    from a follow-up rather than a photo never had a model prediction, and NULL
    says that truthfully. /officials/accuracy excludes those rows rather than
    attributing them to a guessed label.
    """
    diagnosis = (
        await session.execute(
            select(Diagnosis)
            .where(
                Diagnosis.problem_id == problem_id,
                Diagnosis.created_at <= escalated_at,
            )
            .order_by(Diagnosis.created_at.desc())
            .limit(1)
        )
    ).scalar_one_or_none()
    if diagnosis is None:
        return None

    predictions = (diagnosis.topk or {}).get("predictions") or []
    if not predictions:
        return None
    return predictions[0].get("label")


async def confirm_case(
    session: AsyncSession,
    case: Case,
    agronomist_id: uuid.UUID,
    verdict: ConfirmationVerdict,
    corrected_label: TargetLabel | None = None,
    treatment: str | None = None,
    notes: str | None = None,
) -> ConfirmationResult:
    """Apply an agronomist's verdict and everything that follows from it."""
    problem = await session.get(Problem, case.problem_id)
    if problem is None:
        raise ValueError(f"case {case.id} points at a problem that does not exist")
    farm = await session.get(Farm, problem.farm_id)
    if farm is None:
        raise ValueError(f"problem {problem.id} points at a farm that does not exist")

    label_before = problem.label.value if problem.label else None
    model_label = await model_label_at_escalation(session, problem.id, case.created_at)

    # 1. The Confirmation row. The CHECK on this table refuses a `corrected`
    #    verdict with no corrected_label — a correction that does not say what
    #    it corrected to is not a correction.
    confirmation = Confirmation(
        case_id=case.id,
        problem_id=problem.id,
        agronomist_id=agronomist_id,
        verdict=verdict,
        corrected_label=corrected_label,
        model_label=model_label,
        treatment=treatment,
        notes=notes,
    )
    session.add(confirmation)

    # 2. Resolve, and on a correction make the case file say what it was.
    if verdict == ConfirmationVerdict.CORRECTED and corrected_label is not None:
        problem.label = corrected_label
    problem.status = ProblemStatus.RESOLVED
    problem.resolved_at = datetime.now(UTC)
    case.status = CaseStatus.RESOLVED

    label_after = problem.label.value if problem.label else None
    await session.flush()

    # 3. The prior. Both counters move on a correction, on different rows.
    stage = (
        farm.growth_stage.value
        if hasattr(farm.growth_stage, "value")
        else str(farm.growth_stage)
    )
    crop = farm.crop.value if hasattr(farm.crop, "value") else str(farm.crop)
    await prior_service.record_confirmation(
        session,
        region=farm.region,
        crop=crop,
        growth_stage=stage,
        # The diagnosis-derived label where there is one; Problem.label as it
        # stood before the overwrite otherwise. Both describe what was believed
        # before the agronomist looked.
        model_label=model_label or label_before,
        corrected_label=(
            corrected_label.value
            if verdict == ConfirmationVerdict.CORRECTED and corrected_label
            else None
        ),
    )

    # 4. Fan out. Both verdicts propagate — docs/API_CONTRACT.md §13: "Only
    #    confirmed and corrected verdicts propagate." A correction is still a
    #    confirmed presence of a disease, just a different one, and the
    #    neighbours need warning about the RIGHT target.
    spread = SpreadReport()
    if problem.label is not None:
        spread = await propagate(
            session, origin=farm, target=problem.label, origin_label=label_after
        )

    await session.flush()

    return ConfirmationResult(
        confirmation=confirmation,
        case=case,
        problem=problem,
        spread=spread,
        label_before=label_before,
        label_after=label_after,
        model_label=model_label,
    )
