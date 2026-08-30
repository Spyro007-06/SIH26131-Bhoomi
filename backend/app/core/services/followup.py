"""F10 - closed-loop follow-up.

OWNER: Shreekumar

Schedules check-ins FOLLOWUP_DUE_DAYS after an advisory and promotes severity
on got_worse. APScheduler drives the due-date sweep.

Specified by: docs/DESIGN.md §1, docs/API_CONTRACT.md §11.

-----------------------------------------------------------------------------
WHO CALLS schedule_for()

By design a FollowUp is created when an Advisory is persisted — the check-in
exists because the farmer was told to do something. Advisory composition is
F7 and belongs to Thaariha (`app/intelligence/rag.py`), and it does not exist
yet.

So `schedule_for(problem_id)` is exposed here and called from the seed for now.
When F7 lands it calls this function at the point it persists an Advisory, and
the seed call goes away. Nothing else changes.
-----------------------------------------------------------------------------
"""

from __future__ import annotations

import uuid
from datetime import UTC, datetime, timedelta

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.config import FOLLOWUP_DUE_DAYS
from app.contracts.enums import FollowupResponse, ProblemSeverity
from app.core.models import FollowUp, Problem
from app.core.services.escalation import escalate

# Ordered, least severe first. Index position is the promotion step.
SEVERITY_LADDER: tuple[ProblemSeverity, ...] = (
    ProblemSeverity.EARLY,
    ProblemSeverity.MODERATE,
    ProblemSeverity.SEVERE,
)


async def schedule_for(
    session: AsyncSession, problem_id: uuid.UUID, from_time: datetime | None = None
) -> FollowUp | None:
    """Create the check-in for a problem that has just been advised.

    Returns None if an unanswered follow-up already exists for the problem —
    two pending check-ins for one problem would show the farmer the same
    question twice and count twice in the home screen's pending total.
    """
    pending = (
        await session.execute(
            select(FollowUp).where(
                FollowUp.problem_id == problem_id, FollowUp.responded_at.is_(None)
            )
        )
    ).scalars().first()
    if pending is not None:
        return None

    follow_up = FollowUp(
        problem_id=problem_id,
        due_at=(from_time or datetime.now(UTC)) + timedelta(days=FOLLOWUP_DUE_DAYS),
    )
    session.add(follow_up)
    await session.flush()
    return follow_up


def promote(severity: ProblemSeverity | None) -> ProblemSeverity:
    """One step up the ladder, saturating at severe.

    A problem with no severity recorded promotes to `moderate` rather than
    `early`: the farmer has just told us it got worse, so the floor is not the
    lowest rung.
    """
    if severity is None:
        return ProblemSeverity.MODERATE
    index = SEVERITY_LADDER.index(severity)
    return SEVERITY_LADDER[min(index + 1, len(SEVERITY_LADDER) - 1)]


async def record_response(
    session: AsyncSession,
    follow_up: FollowUp,
    response: FollowupResponse,
    image_asset_id: uuid.UUID | None = None,
) -> tuple[Problem, ProblemSeverity | None, ProblemSeverity | None, uuid.UUID | None]:
    """Apply a follow-up answer.

    Returns (problem, severity_from, severity_to, case_id).

    `got_worse` promotes severity by one step and escalates. The other two
    answers record the response and change nothing else — an `improved` answer
    is not evidence enough to resolve a problem on the farmer's word alone, and
    closing it here would remove it from the case file the agronomist reads.
    """
    problem = await session.get(Problem, follow_up.problem_id)

    follow_up.response = response
    follow_up.responded_at = datetime.now(UTC)
    if image_asset_id is not None:
        follow_up.image_asset_id = image_asset_id

    severity_from = problem.severity if problem else None
    severity_to = severity_from
    case_id: uuid.UUID | None = None

    if response == FollowupResponse.GOT_WORSE and problem is not None:
        severity_to = promote(severity_from)
        problem.severity = severity_to
        case = await escalate(session, problem.id, reason="follow-up reported got_worse")
        case_id = case.id

    await session.flush()
    return problem, severity_from, severity_to, case_id


async def due_followups(session: AsyncSession, now: datetime | None = None) -> list[FollowUp]:
    """Unanswered check-ins whose due date has passed. Read by the scheduler."""
    return list(
        (
            await session.execute(
                select(FollowUp)
                .where(
                    FollowUp.responded_at.is_(None),
                    FollowUp.due_at <= (now or datetime.now(UTC)),
                )
                .order_by(FollowUp.due_at)
            )
        ).scalars().all()
    )
