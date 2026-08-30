"""F6 - nearby-farm spread alerts.

OWNER: Shreekumar

PostGIS ST_DWithin fan-out over same-crop farms within SPREAD_RADIUS_M.
Only confirmed diagnoses propagate.

Specified by: docs/DESIGN.md §10.

-----------------------------------------------------------------------------
Only confirmed diagnoses propagate.

docs/DESIGN.md §10: "An unconfirmed model output must not trigger village-wide
alarm — that is how a system loses trust in one afternoon." This module is only
ever called from services/confirmation.py, after a Confirmation row exists.
There is no path from a Diagnosis to here, and a test asserts a problem with a
diagnosis and no confirmation produces zero alerts.

-----------------------------------------------------------------------------
THE COLLISION WITH PHASE 3's UNIQUENESS CONSTRAINT

Migration 0004 puts a unique index on (farm_id, target, issued-on-date) so the
nightly risk job cannot stack duplicates. That constraint would silently
suppress the single most important alert this system can send: a neighbour who
already received a humidity-band alert for blast this morning would get NOTHING
when a confirmed case appears 1.5 km away.

A confirmed case next door is strictly stronger information than a weather
window. So the existing row is UPGRADED in place rather than skipped:

    trigger_type      -> combined   (the enum carries it for exactly this)
    risk_level        -> the higher of the two
    reason            -> the spread clause APPENDED, not replacing the original
    inspection_tasks  -> union of both sets, order-preserving, deduplicated
    outcome           -> reset to NULL

The outcome reset is the one worth pausing on. If the farmer already answered
"nothing found" this morning, that answer was about a weather forecast. It is
not an answer to "a confirmed case has been found next door" — so the card
becomes live again and demands a fresh look.

An upgrade counts toward `spread_alerts_issued`. The agronomist asked how many
farms were warned, and an upgraded card warns a farm.
-----------------------------------------------------------------------------
"""

from __future__ import annotations

import uuid
from dataclasses import dataclass, field

from sqlalchemy import func, select, text
from sqlalchemy.ext.asyncio import AsyncSession

from app.config import RISK_LEVELS, SPREAD_RADIUS_M
from app.contracts.enums import AlertTrigger, TargetLabel
from app.core.models import Alert, Farm
from app.core.services.risk import load_inspection_tasks


@dataclass
class SpreadReport:
    issued: int = 0
    upgraded: int = 0
    neighbours: int = 0
    farm_ids: list[uuid.UUID] = field(default_factory=list)

    @property
    def total(self) -> int:
        """What `spread_alerts_issued` returns: farms warned, however warned."""
        return self.issued + self.upgraded


def _higher(a: str, b: str) -> str:
    return a if RISK_LEVELS.index(a) >= RISK_LEVELS.index(b) else b


def _merge_tasks(existing: list[str], incoming: list[str]) -> list[str]:
    """Union, order-preserving, deduplicated.

    dict.fromkeys rather than a set: the tasks are ordered instructions and
    shuffling them would move "photograph what you find" above "walk the field".
    """
    return list(dict.fromkeys([*existing, *incoming]))


async def neighbours_within_radius(
    session: AsyncSession, origin: Farm, radius_m: int = SPREAD_RADIUS_M
) -> list[Farm]:
    """docs/DESIGN.md §10's query, verbatim in intent.

        SELECT id FROM farm
        WHERE crop = :crop AND id != :origin
          AND ST_DWithin(location, :origin_point, :radius)

    Crop-scoped: a confirmed blast case does not warrant warning a neighbouring
    field of a different crop, and the frozen label set is paddy-only anyway.
    """
    # The origin point is taken from the database by id rather than from
    # origin.location. On a freshly-flushed ORM instance that attribute still
    # holds the raw 'SRID=4326;POINT(..)' string it was assigned, so PostGIS
    # sees ST_DWithin(geography, varchar, integer) and reports no such function.
    # A scalar subquery is always correctly typed, whatever state the instance
    # is in.
    origin_point = select(Farm.location).where(Farm.id == origin.id).scalar_subquery()

    statement = (
        select(Farm)
        .where(
            Farm.crop == origin.crop,
            Farm.id != origin.id,
            func.ST_DWithin(Farm.location, origin_point, radius_m),
        )
        .order_by(Farm.region, Farm.id)
    )
    return list((await session.execute(statement)).scalars().all())


async def propagate(
    session: AsyncSession,
    origin: Farm,
    target: TargetLabel,
    origin_label: str | None = None,
    radius_m: int = SPREAD_RADIUS_M,
) -> SpreadReport:
    """Fan a confirmed case out to same-crop farms within the radius.

    Call ONLY from services/confirmation.py, after the Confirmation row exists.
    """
    report = SpreadReport()
    tasks_by_target = load_inspection_tasks()
    tasks = tasks_by_target.get(target.value, [])
    if not tasks:
        # Unreachable while the seed file is validated at load, but an alert
        # with no task cannot be stored (the CHECK) and must not be attempted.
        return report

    label = origin_label or target.value
    spread_clause = (
        f"A case of {label.replace('_', ' ')} was confirmed by an agronomist on a "
        f"nearby {origin.crop.value if hasattr(origin.crop, 'value') else origin.crop} "
        f"farm within {radius_m / 1000:g} km."
    )

    neighbours = await neighbours_within_radius(session, origin, radius_m)
    report.neighbours = len(neighbours)

    for farm in neighbours:
        existing = (
            await session.execute(
                select(Alert)
                .where(
                    Alert.farm_id == farm.id,
                    Alert.target == target,
                    text(
                        "(alert.issued_at AT TIME ZONE 'UTC')::date "
                        "= (now() AT TIME ZONE 'UTC')::date"
                    ),
                )
                .limit(1)
            )
        ).scalar_one_or_none()

        if existing is not None:
            existing.trigger_type = AlertTrigger.COMBINED
            existing.risk_level = _higher(existing.risk_level, "high")
            if spread_clause not in (existing.reason or ""):
                existing.reason = f"{existing.reason} {spread_clause}".strip()
            existing.inspection_tasks = _merge_tasks(existing.inspection_tasks, tasks)
            # New information invalidates an answer given about the old.
            existing.outcome = None
            report.upgraded += 1
        else:
            session.add(
                Alert(
                    farm_id=farm.id,
                    trigger_type=AlertTrigger.SPREAD,
                    target=target,
                    risk_level="high",
                    reason=spread_clause,
                    inspection_tasks=tasks,
                )
            )
            report.issued += 1

        report.farm_ids.append(farm.id)

    await session.flush()
    return report
