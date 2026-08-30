"""F12 - escalation and queue routing.

OWNER: Shreekumar

Opens a Case, assigns the next available agronomist, computes queue_position
and eta_minutes. Fires automatically from the gate as well as on request.

Specified by: docs/API_CONTRACT.md §12.

-----------------------------------------------------------------------------
`bundle` is left NULL, deliberately.

Compiling the case bundle is F12's other half and belongs to Thaariha
(`app/intelligence/bundle.py`). docs/API_CONTRACT.md §12 states that every field
in a bundle is populated from live data, with no placeholder strings, and names
this as something that "has regressed before and needs a test".

Writing a skeleton bundle here with empty arrays and blank labels would satisfy
the column and violate the contract — an agronomist opening the case would see a
history that looks empty rather than absent. NULL says "not compiled yet"
truthfully; a fake bundle lies.
-----------------------------------------------------------------------------
"""

from __future__ import annotations

import uuid

from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.config import CASE_ETA_MINUTES_PER_POSITION
from app.contracts.enums import CaseStatus, Role
from app.core.models import Case, User


async def escalate(
    session: AsyncSession, problem_id: uuid.UUID, reason: str | None = None
) -> Case:
    """Open a Case for `problem_id`, or return the one already open.

    Idempotent per problem: a farmer answering "got worse" twice, or a gate
    escalating a problem that a follow-up already escalated, must not produce
    two cases in one agronomist's queue for the same field.
    """
    existing = (
        await session.execute(
            select(Case)
            .where(Case.problem_id == problem_id, Case.status != CaseStatus.RESOLVED)
            .order_by(Case.created_at)
            .limit(1)
        )
    ).scalar_one_or_none()
    if existing is not None:
        return existing

    agronomist = (
        await session.execute(
            select(User).where(User.role == Role.AGRONOMIST).order_by(User.created_at).limit(1)
        )
    ).scalar_one_or_none()

    open_cases = await session.scalar(
        select(func.count())
        .select_from(Case)
        .where(Case.status.in_([CaseStatus.OPEN, CaseStatus.ASSIGNED]))
    )
    queue_position = int(open_cases or 0) + 1

    case = Case(
        problem_id=problem_id,
        assigned_to=agronomist.id if agronomist else None,
        status=CaseStatus.ASSIGNED if agronomist else CaseStatus.OPEN,
        queue_position=queue_position,
        eta_minutes=queue_position * CASE_ETA_MINUTES_PER_POSITION,
        # NOT a placeholder. See the module docstring.
        bundle=None,
    )
    session.add(case)
    await session.flush()
    return case
