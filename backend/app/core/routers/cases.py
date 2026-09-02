"""F12 - expert validation and the case bundle.

OWNER: split, deliberately. See docs/API_CONTRACT.md §13, ownership note.

    POST /cases/{id}/confirm         Shreekumar  (this file)
    GET  /agronomist/case-queue      Shreekumar  (this file)
    GET  /cases/{id}                 Thaariha    (NOT here - still 501)
    POST /cases/{id}/request-info     Thaariha    (NOT here - still 501)

docs/API_CONTRACT.md §16 lists the whole of §12/§13 as Thaariha's. §13's confirm
endpoint has no intelligence in it: it takes a verdict, writes a Confirmation,
and its four downstream effects — problem resolution, the prior, the spread
fan-out, the F15 aggregates — are all core features. Bundle compilation is the
part with reasoning in it and stays hers.

Specified by: docs/API_CONTRACT.md §12 and §13.
"""

from __future__ import annotations

import uuid

from fastapi import APIRouter, Depends, Query
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.contracts.enums import CaseStatus, Role
from app.core.models import Case, Farm, Problem
from app.core.schemas.cases import CaseQueueItem, CaseQueueOut, ConfirmIn, ConfirmOut
from app.core.services.confirmation import confirm_case
from app.db import get_session
from app.deps import Principal, require_role
from app.errors import BhoomiError, ErrorCode, NotFound, error_response

router = APIRouter(tags=["agronomist"])

# Built once at import rather than per request. Calling require_role() inside a
# Depends() default constructs a fresh guard on every call, which works but
# makes the dependency non-identical between routes and defeats FastAPI's
# per-request dependency caching.
AGRONOMIST_ONLY = Depends(require_role(Role.AGRONOMIST))

_UNAUTHENTICATED = error_response(401, "No, or an invalid, bearer token.")
_NOT_AN_AGRONOMIST = error_response(403, "The caller's role is not agronomist.")


@router.get(
    "/agronomist/case-queue",
    response_model=CaseQueueOut,
    responses={
        **_UNAUTHENTICATED,
        **_NOT_AN_AGRONOMIST,
        **error_response(422, "`status` is not a recognised case_status value."),
    },
)
async def case_queue(
    status: CaseStatus = Query(default=CaseStatus.ASSIGNED),
    principal: Principal = AGRONOMIST_ONLY,
    session: AsyncSession = Depends(get_session),
) -> CaseQueueOut:
    """Cases for this agronomist, oldest first. docs/API_CONTRACT.md §13.

    Oldest first, not highest severity first: a queue ordered by urgency starves
    its tail, and the farmer whose case has waited longest is the one most
    likely to have stopped trusting that anyone is coming.
    """
    rows = (
        await session.execute(
            select(Case, Problem, Farm)
            .join(Problem, Problem.id == Case.problem_id)
            .join(Farm, Farm.id == Problem.farm_id)
            .where(Case.status == status)
            .order_by(Case.created_at)
        )
    ).all()

    return CaseQueueOut(
        cases=[
            CaseQueueItem(
                case_id=case.id,
                problem_id=problem.id,
                farm_id=farm.id,
                region=farm.region,
                label=problem.label,
                status=case.status,
                queue_position=position,
                eta_minutes=case.eta_minutes,
                created_at=case.created_at,
            )
            # queue_position is recomputed from the live ordering rather than
            # read off the row: the stored value was correct when the case was
            # opened and is stale the moment anything ahead of it resolves.
            for position, (case, problem, farm) in enumerate(rows, start=1)
        ]
    )


@router.post(
    "/cases/{case_id}/confirm",
    response_model=ConfirmOut,
    responses={
        **_UNAUTHENTICATED,
        **_NOT_AN_AGRONOMIST,
        **error_response(404, "That case does not exist."),
        **error_response(
            422,
            "The request body did not parse (including corrected_label "
            "required/forbidden per verdict, ConfirmIn's own rule), OR that "
            "case has already been resolved.",
        ),
    },
)
async def confirm(
    case_id: uuid.UUID,
    payload: ConfirmIn,
    principal: Principal = AGRONOMIST_ONLY,
    session: AsyncSession = Depends(get_session),
) -> ConfirmOut:
    """Record the agronomist's verdict and everything that follows.

    `spread_alerts_issued` is the F6 fan-out count — the moment one confirmation
    becomes a village-wide warning, and the most demonstrable thing in the
    product. It counts upgraded alerts as well as new ones: a farm whose
    existing weather card was upgraded to `combined` has been warned.
    """
    case = await session.get(Case, case_id)
    if case is None:
        raise NotFound("That case does not exist.")
    if case.status == CaseStatus.RESOLVED:
        raise BhoomiError(
            ErrorCode.VALIDATION_FAILED, "That case has already been resolved."
        )

    result = await confirm_case(
        session,
        case=case,
        agronomist_id=principal.subject,
        verdict=payload.verdict,
        corrected_label=payload.corrected_label,
        treatment=payload.treatment,
        notes=payload.notes,
    )
    await session.commit()

    return ConfirmOut(
        case_id=case.id,
        status=result.case.status,
        problem_status=result.problem.status,
        confirmation_id=result.confirmation.id,
        spread_alerts_issued=result.spread.total,
    )
