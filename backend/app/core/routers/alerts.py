"""F5 weather and seasonal risk; F6 spread alerts surface here too.

OWNER: Shreekumar

Serves:
    GET /farms/{id}/alerts
    POST /alerts/{id}/respond

Specified by: docs/API_CONTRACT.md §10, docs/DESIGN.md §10.
"""

from __future__ import annotations

import uuid

from fastapi import APIRouter, Depends, Query
from sqlalchemy import or_, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.contracts.enums import AlertOutcome, Role
from app.core.models import Alert, Farm
from app.core.pagination import clamp_limit, decode_cursor, encode_cursor
from app.core.schemas.alerts import (
    AlertListOut,
    AlertOut,
    AlertRespondIn,
    AlertRespondOut,
)
from app.db import get_session
from app.deps import Principal, current_principal
from app.errors import Forbidden, NotFound

router = APIRouter(tags=["alerts"])


async def _owned_farm(
    farm_id: uuid.UUID, principal: Principal, session: AsyncSession
) -> Farm:
    farm = await session.get(Farm, farm_id)
    if farm is None:
        raise NotFound("That farm does not exist.")
    if principal.role == Role.FARMER and farm.farmer_id != principal.subject:
        raise Forbidden("That farm belongs to a different account.")
    return farm


def _as_out(alert: Alert) -> AlertOut:
    return AlertOut(
        id=alert.id,
        trigger_type=alert.trigger_type,
        target=alert.target,
        risk_level=alert.risk_level,
        reason=alert.reason,
        inspection_tasks=alert.inspection_tasks,
        issued_at=alert.issued_at,
        outcome=alert.outcome,
    )


@router.get("/farms/{farm_id}/alerts", response_model=AlertListOut)
async def list_alerts(
    farm_id: uuid.UUID,
    outcome: AlertOutcome | None = Query(default=None),
    unanswered: bool = Query(
        default=False, description="Only alerts the farmer has not responded to yet"
    ),
    limit: int | None = Query(default=None, ge=1),
    cursor: str | None = Query(default=None),
    principal: Principal = Depends(current_principal),
    session: AsyncSession = Depends(get_session),
) -> AlertListOut:
    """Alerts for a farm, newest first.

    Clients keep an alert card non-dismissible until `/respond` is called
    (docs/API_CONTRACT.md §10), so `?unanswered=true` is what the home screen
    asks for.
    """
    farm = await _owned_farm(farm_id, principal, session)
    page_size = clamp_limit(limit)
    keyset = decode_cursor(cursor)

    statement = select(Alert).where(Alert.farm_id == farm.id)
    if outcome is not None:
        statement = statement.where(Alert.outcome == outcome)
    if unanswered:
        statement = statement.where(Alert.outcome.is_(None))
    if keyset is not None:
        at, row_id = keyset
        statement = statement.where(
            or_(Alert.issued_at < at, (Alert.issued_at == at) & (Alert.id < row_id))
        )

    statement = statement.order_by(Alert.issued_at.desc(), Alert.id.desc()).limit(
        page_size + 1
    )
    rows = list((await session.execute(statement)).scalars().all())
    has_more = len(rows) > page_size
    rows = rows[:page_size]

    return AlertListOut(
        alerts=[_as_out(a) for a in rows],
        next_cursor=encode_cursor(rows[-1].issued_at, rows[-1].id) if has_more else None,
    )


@router.post("/alerts/{alert_id}/respond", response_model=AlertRespondOut)
async def respond_to_alert(
    alert_id: uuid.UUID,
    payload: AlertRespondIn,
    principal: Principal = Depends(current_principal),
    session: AsyncSession = Depends(get_session),
) -> AlertRespondOut:
    """Record what the farmer found. This is what makes the card dismissible.

    `found` returns `diagnose_suggested: true` — the farmer has a photo of
    something and the next step is the gated diagnose path, not a treatment
    recommendation from this endpoint. F5 tells you where to look; it does not
    tell you what you found.
    """
    alert = await session.get(Alert, alert_id)
    if alert is None:
        raise NotFound("That alert does not exist.")
    await _owned_farm(alert.farm_id, principal, session)

    alert.outcome = payload.outcome
    await session.commit()

    return AlertRespondOut(
        alert_id=alert.id,
        outcome=payload.outcome,
        diagnose_suggested=payload.outcome == AlertOutcome.FOUND,
    )
