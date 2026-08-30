"""F1 — farm persistent memory.

OWNER: Shreekumar

Serves:
    POST /farms
    GET /farms/{id}
    PATCH /farms/{id}
    GET /farms/{id}/summary

Specified by: docs/API_CONTRACT.md §5. Farm shape is contract C2, docs/DESIGN.md §4.
"""

from __future__ import annotations

import uuid

from fastapi import APIRouter, Depends, status
from geoalchemy2.shape import to_shape
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.contracts.farm import SRID, GeoPoint
from app.core.models import Alert, Farm, FollowUp, Problem
from app.core.schemas.farms import (
    FarmCreate,
    FarmOut,
    FarmSummaryOut,
    FarmUpdate,
    HomeSummaryOut,
)
from app.db import get_session
from app.deps import Principal, current_principal
from app.errors import Forbidden, NotFound

router = APIRouter(prefix="/farms", tags=["farms"])


def _point_wkt(location: GeoPoint) -> str:
    """POINT(lng lat) — longitude first. Reversing this puts a Nashik farm in
    the Indian Ocean and every ST_DWithin result silently becomes empty."""
    return f"SRID={SRID};POINT({location.lng} {location.lat})"


def _to_geopoint(location) -> GeoPoint:
    shape = to_shape(location)
    return GeoPoint(lat=shape.y, lng=shape.x)


def _as_farm_out(farm: Farm) -> FarmOut:
    return FarmOut(
        id=farm.id,
        farmer_id=farm.farmer_id,
        crop=farm.crop,
        variety=farm.variety,
        growth_stage=farm.growth_stage,
        region=farm.region,
        sowing_date=farm.sowing_date,
        location=_to_geopoint(farm.location),
        created_at=farm.created_at,
    )


async def _load_owned(
    farm_id: uuid.UUID, principal: Principal, session: AsyncSession
) -> Farm:
    """Fetch a farm the caller is allowed to see.

    A farmer sees only their own. Agronomists and officials see any farm — they
    work cases and hotspots across a district by definition.
    """
    farm = await session.get(Farm, farm_id)
    if farm is None:
        raise NotFound("That farm does not exist.")
    if principal.role == "farmer" and farm.farmer_id != principal.subject:
        raise Forbidden("That farm belongs to a different account.")
    return farm


@router.post("", response_model=FarmSummaryOut, status_code=status.HTTP_201_CREATED)
async def create_farm(
    payload: FarmCreate,
    principal: Principal = Depends(current_principal),
    session: AsyncSession = Depends(get_session),
) -> FarmSummaryOut:
    """Create a farm. `location` is required — see FarmCreate."""
    farm = Farm(
        farmer_id=principal.subject,
        crop=payload.crop,
        variety=payload.variety,
        growth_stage=payload.growth_stage,
        region=payload.region,
        sowing_date=payload.sowing_date,
        location=_point_wkt(payload.location),
    )
    session.add(farm)
    await session.commit()
    await session.refresh(farm)

    return FarmSummaryOut(
        id=farm.id, crop=farm.crop, growth_stage=farm.growth_stage, region=farm.region
    )


@router.get("/{farm_id}", response_model=FarmOut)
async def get_farm(
    farm_id: uuid.UUID,
    principal: Principal = Depends(current_principal),
    session: AsyncSession = Depends(get_session),
) -> FarmOut:
    return _as_farm_out(await _load_owned(farm_id, principal, session))


@router.patch("/{farm_id}", response_model=FarmOut)
async def update_farm(
    farm_id: uuid.UUID,
    payload: FarmUpdate,
    principal: Principal = Depends(current_principal),
    session: AsyncSession = Depends(get_session),
) -> FarmOut:
    """Update onboarding fields. Location is not one of them — see FarmUpdate."""
    farm = await _load_owned(farm_id, principal, session)
    for field, value in payload.model_dump(exclude_unset=True).items():
        setattr(farm, field, value)
    await session.commit()
    await session.refresh(farm)
    return _as_farm_out(farm)


@router.get("/{farm_id}/summary", response_model=HomeSummaryOut)
async def farm_summary(
    farm_id: uuid.UUID,
    principal: Principal = Depends(current_principal),
    session: AsyncSession = Depends(get_session),
) -> HomeSummaryOut:
    """The home screen in one call. docs/API_CONTRACT.md §5.

    The three counts are real queries. `health` and `spoken_summary` are null,
    not invented — see HomeSummaryOut for who owns them.
    """
    farm = await _load_owned(farm_id, principal, session)

    open_problems = await session.scalar(
        select(func.count())
        .select_from(Problem)
        .where(Problem.farm_id == farm.id, Problem.status == "open")
    )
    pending_followups = await session.scalar(
        select(func.count())
        .select_from(FollowUp)
        .join(Problem, Problem.id == FollowUp.problem_id)
        .where(Problem.farm_id == farm.id, FollowUp.responded_at.is_(None))
    )
    active_alerts = await session.scalar(
        select(func.count())
        .select_from(Alert)
        .where(Alert.farm_id == farm.id, Alert.outcome.is_(None))
    )

    return HomeSummaryOut(
        farm=FarmSummaryOut(
            id=farm.id, crop=farm.crop, growth_stage=farm.growth_stage, region=farm.region
        ),
        open_problems=open_problems or 0,
        pending_followups=pending_followups or 0,
        active_alerts=active_alerts or 0,
    )
