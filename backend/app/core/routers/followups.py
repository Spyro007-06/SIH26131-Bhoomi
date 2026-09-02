"""F10 - closed-loop follow-up.

OWNER: Shreekumar

Serves:
    GET /farms/{id}/followups/pending
    POST /followups/{id}/respond

Specified by: docs/API_CONTRACT.md §11.
"""

from __future__ import annotations

import uuid
from datetime import UTC, datetime

from fastapi import APIRouter, Depends
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.contracts.enums import FollowupResponse, Role
from app.core.models import Farm, FollowUp, Problem
from app.core.schemas.followups import (
    FollowUpRespondIn,
    FollowUpRespondOut,
    PendingFollowUpListOut,
    PendingFollowUpOut,
    SeverityChange,
)
from app.core.services import followup as followup_service
from app.db import get_session
from app.deps import Principal, current_principal
from app.errors import Forbidden, NotFound, error_response

router = APIRouter(tags=["follow-up"])

_UNAUTHENTICATED = error_response(401, "No, or an invalid, bearer token.")
_MALFORMED = error_response(422, "A path, query or body parameter did not parse.")
_FARM_NOT_FOUND_OR_FORBIDDEN = {
    **error_response(404, "That farm does not exist."),
    **error_response(
        403, "The caller is a farmer and that farm belongs to a different account."
    ),
}


async def _owned_farm(
    farm_id: uuid.UUID, principal: Principal, session: AsyncSession
) -> Farm:
    farm = await session.get(Farm, farm_id)
    if farm is None:
        raise NotFound("That farm does not exist.")
    if principal.role == Role.FARMER and farm.farmer_id != principal.subject:
        raise Forbidden("That farm belongs to a different account.")
    return farm


@router.get(
    "/farms/{farm_id}/followups/pending",
    response_model=PendingFollowUpListOut,
    responses={**_UNAUTHENTICATED, **_FARM_NOT_FOUND_OR_FORBIDDEN, **_MALFORMED},
)
async def pending_followups(
    farm_id: uuid.UUID,
    principal: Principal = Depends(current_principal),
    session: AsyncSession = Depends(get_session),
) -> PendingFollowUpListOut:
    """Unanswered check-ins for this farm, soonest first.

    Returns everything unanswered, not only what is already due. A farmer opening
    the app the day before a check-in should see it coming; hiding it until the
    due date makes the app look empty on the day something is happening.
    `overdue` is the flag the client renders differently.
    """
    farm = await _owned_farm(farm_id, principal, session)
    now = datetime.now(UTC)

    rows = list(
        (
            await session.execute(
                select(FollowUp, Problem)
                .join(Problem, Problem.id == FollowUp.problem_id)
                .where(Problem.farm_id == farm.id, FollowUp.responded_at.is_(None))
                .order_by(FollowUp.due_at)
            )
        ).all()
    )

    return PendingFollowUpListOut(
        followups=[
            PendingFollowUpOut(
                id=f.id,
                problem_id=p.id,
                label=p.label,
                severity=p.severity,
                due_at=f.due_at,
                overdue=f.due_at <= now,
            )
            for f, p in rows
        ]
    )


@router.post(
    "/followups/{followup_id}/respond",
    response_model=FollowUpRespondOut,
    responses={
        **_UNAUTHENTICATED,
        **error_response(404, "That follow-up does not exist, or its problem does not."),
        **error_response(
            403,
            "Either that follow-up's farm belongs to a different farmer's "
            "account, or this check-in has already been answered.",
        ),
        **_MALFORMED,
    },
)
async def respond_to_followup(
    followup_id: uuid.UUID,
    payload: FollowUpRespondIn,
    principal: Principal = Depends(current_principal),
    session: AsyncSession = Depends(get_session),
) -> FollowUpRespondOut:
    """Answer a check-in.

    `got_worse` promotes severity one step and auto-escalates to an agronomist.
    The created Case carries status, queue_position and eta_minutes, and its
    `bundle` is NULL — compiling that is Thaariha's F12, and a placeholder
    bundle on a live case is the failure docs/API_CONTRACT.md §12 names.
    """
    follow_up = await session.get(FollowUp, followup_id)
    if follow_up is None:
        raise NotFound("That follow-up does not exist.")

    problem = await session.get(Problem, follow_up.problem_id)
    if problem is None:
        raise NotFound("That follow-up does not exist.")
    await _owned_farm(problem.farm_id, principal, session)

    if follow_up.responded_at is not None:
        raise Forbidden("That check-in has already been answered.")

    problem, severity_from, severity_to, case_id = await followup_service.record_response(
        session, follow_up, payload.response, payload.image_asset_id
    )
    await session.commit()

    change = (
        SeverityChange(**{"from": severity_from, "to": severity_to})
        if severity_from != severity_to
        else None
    )

    return FollowUpRespondOut(
        problem_id=problem.id,
        severity_change=change,
        escalated=payload.response == FollowupResponse.GOT_WORSE and case_id is not None,
        case_id=case_id,
    )
