"""F15 - agriculture-officials dashboard.

OWNER: Santheesh (renders) + Shreekumar (data, this file)

Serves:
    GET /officials/hotspots
    GET /officials/accuracy
    GET /officials/queue

Specified by: docs/API_CONTRACT.md §15. Role `official` only.

Every figure derives from Confirmation rows at read time. docs/API_CONTRACT.md
§17 invariant 10 — only confirmed cases appear — is therefore structural: an
unconfirmed diagnosis has no confirmation row to join to and cannot reach these
responses through any filter someone might later remove.
"""

from __future__ import annotations

from datetime import date

from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession

from app.contracts.enums import Role
from app.core.schemas.officials import (
    AccuracyOut,
    AccuracyRowOut,
    AccuracyWindow,
    HotspotPointOut,
    HotspotsOut,
    QueueOut,
)
from app.core.services import aggregates
from app.db import get_session
from app.deps import Principal, require_role
from app.errors import error_response

router = APIRouter(prefix="/officials", tags=["officials"])

# One guard object for the whole router — see the note in routers/cases.py.
OFFICIAL_ONLY = Depends(require_role(Role.OFFICIAL))

# Shared by all three routes: no path params, no ownership check, just the
# role guard.
_AUTH_ONLY = {
    **error_response(401, "No, or an invalid, bearer token."),
    **error_response(403, "The caller's role is not official."),
}
# hotspots and accuracy additionally take query parameters that parse
# (region/crop/from/to); queue takes none, so it does not get this one.
_STANDARD_RESPONSES = {**_AUTH_ONLY, **error_response(422, "A query parameter did not parse.")}


@router.get("/hotspots", response_model=HotspotsOut, responses=_STANDARD_RESPONSES)
async def hotspots(
    region: str | None = Query(default=None),
    crop: str | None = Query(default=None),
    from_: date | None = Query(default=None, alias="from"),
    to: date | None = Query(default=None),
    principal: Principal = OFFICIAL_ONLY,
    session: AsyncSession = Depends(get_session),
) -> HotspotsOut:
    """Confirmed outbreaks as map points. Model output never appears here."""
    points, totals = await aggregates.hotspots(
        session, region=region, crop=crop, date_from=from_, date_to=to
    )
    return HotspotsOut(
        points=[
            HotspotPointOut(
                lat=p.lat,
                lng=p.lng,
                label=p.label,
                confirmed_count=p.confirmed_count,
                first_seen=p.first_seen,
                last_seen=p.last_seen,
            )
            for p in points
        ],
        totals_by_label=totals,
    )


@router.get("/accuracy", response_model=AccuracyOut, responses=_STANDARD_RESPONSES)
async def accuracy(
    from_: date | None = Query(default=None, alias="from"),
    to: date | None = Query(default=None),
    principal: Principal = OFFICIAL_ONLY,
    session: AsyncSession = Depends(get_session),
) -> AccuracyOut:
    """Confirmed versus corrected by label over the window."""
    rows = await aggregates.accuracy(session, date_from=from_, date_to=to)
    return AccuracyOut(
        by_label=[
            AccuracyRowOut(
                label=r.label, confirmed=r.confirmed, corrected=r.corrected,
                accuracy=r.accuracy,
            )
            for r in rows
        ],
        window=AccuracyWindow(**{"from": from_, "to": to}),
    )


@router.get("/queue", response_model=QueueOut, responses=_AUTH_ONLY)
async def queue(
    principal: Principal = OFFICIAL_ONLY,
    session: AsyncSession = Depends(get_session),
) -> QueueOut:
    """How deep the agronomist queue is, by status."""
    counts = await aggregates.queue_depth(session)
    return QueueOut(by_status=counts, total=sum(counts.values()))
