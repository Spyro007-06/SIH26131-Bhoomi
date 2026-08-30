"""F15 - dashboard aggregates.

OWNER: Shreekumar

Hotspot points and confirmed-versus-corrected accuracy windows. Only confirmed
cases appear; model output alone never renders on an official's map.

Specified by: docs/API_CONTRACT.md §15.

-----------------------------------------------------------------------------
Derived from Confirmation rows on read. No counter table.

The Phase 1 decision, recorded in docs/DATA_MODEL_ADDENDUM.md Part A: "A
maintained counter can drift from its source; a query cannot." It also makes
§15's own rule — only confirmed cases appear — structurally true rather than
something a writer has to remember, because the aggregate IS the confirmation
rows. There is no path by which an unconfirmed diagnosis reaches this module.
-----------------------------------------------------------------------------
"""

from __future__ import annotations

from dataclasses import dataclass
from datetime import date

from geoalchemy2.shape import to_shape
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.contracts.enums import CaseStatus, ConfirmationVerdict
from app.core.models import Case, Confirmation, Farm, Problem


@dataclass
class HotspotPoint:
    lat: float
    lng: float
    label: str
    confirmed_count: int
    first_seen: date
    last_seen: date


@dataclass
class AccuracyRow:
    label: str
    confirmed: int
    corrected: int

    @property
    def accuracy(self) -> float | None:
        """None, not 0.0, when nothing has been reviewed for this label.

        A label with no verdicts has undefined accuracy. Rendering it as 0.0
        would put a bar at the bottom of Santheesh's chart implying the model is
        wrong every time, when in fact nobody has looked yet.
        """
        total = self.confirmed + self.corrected
        if total == 0:
            return None
        return round(self.confirmed / total, 2)


async def hotspots(
    session: AsyncSession,
    region: str | None = None,
    crop: str | None = None,
    date_from: date | None = None,
    date_to: date | None = None,
) -> tuple[list[HotspotPoint], dict[str, int]]:
    """Confirmed cases as map points, grouped by farm location and label.

    The join to Confirmation is what enforces §15's rule. A Problem with a
    Diagnosis and no Confirmation has no row here to join to, so it contributes
    nothing — not by a filter someone could remove, but because the aggregate is
    built from confirmations.
    """
    statement = (
        select(
            Farm.location,
            Problem.label,
            func.count(Confirmation.id).label("confirmed_count"),
            func.min(Confirmation.created_at).label("first_seen"),
            func.max(Confirmation.created_at).label("last_seen"),
        )
        .select_from(Confirmation)
        .join(Problem, Problem.id == Confirmation.problem_id)
        .join(Farm, Farm.id == Problem.farm_id)
        .where(Problem.label.is_not(None))
        .group_by(Farm.location, Problem.label)
    )
    if region:
        statement = statement.where(Farm.region == region)
    if crop:
        statement = statement.where(Farm.crop == crop)
    if date_from:
        statement = statement.where(func.date(Confirmation.created_at) >= date_from)
    if date_to:
        statement = statement.where(func.date(Confirmation.created_at) <= date_to)

    points: list[HotspotPoint] = []
    totals: dict[str, int] = {}
    for location, label, count, first_seen, last_seen in (
        await session.execute(statement)
    ).all():
        shape = to_shape(location)
        value = label.value if hasattr(label, "value") else str(label)
        points.append(
            HotspotPoint(
                lat=round(shape.y, 5),
                lng=round(shape.x, 5),
                label=value,
                confirmed_count=int(count),
                first_seen=first_seen.date(),
                last_seen=last_seen.date(),
            )
        )
        totals[value] = totals.get(value, 0) + int(count)

    return points, totals


async def accuracy(
    session: AsyncSession, date_from: date | None = None, date_to: date | None = None
) -> list[AccuracyRow]:
    """Confirmed vs corrected per label over a window.

    Grouped on the MODEL's label, which for a corrected row is what the label was
    before the agronomist changed it. Grouping on the current Problem.label would
    credit every correction to the label it was corrected TO, and the chart would
    show a model that is never wrong.

    Confirmation.corrected_label is that pre-correction anchor: on a corrected
    row it holds the truth and Problem.label now equals it, so the model's
    original guess is only recoverable from... nothing, once Problem.label is
    overwritten. So this groups by verdict against the CURRENT label and counts
    corrections against it, which is the honest reading available from the
    schema: "of the cases finally labelled X, how many did the model get right
    first time".
    """
    statement = (
        select(
            Problem.label,
            Confirmation.verdict,
            func.count(Confirmation.id),
        )
        .select_from(Confirmation)
        .join(Problem, Problem.id == Confirmation.problem_id)
        .where(Problem.label.is_not(None))
        .group_by(Problem.label, Confirmation.verdict)
    )
    if date_from:
        statement = statement.where(func.date(Confirmation.created_at) >= date_from)
    if date_to:
        statement = statement.where(func.date(Confirmation.created_at) <= date_to)

    tally: dict[str, AccuracyRow] = {}
    for label, verdict, count in (await session.execute(statement)).all():
        value = label.value if hasattr(label, "value") else str(label)
        row = tally.setdefault(value, AccuracyRow(label=value, confirmed=0, corrected=0))
        if verdict == ConfirmationVerdict.CONFIRMED:
            row.confirmed += int(count)
        else:
            row.corrected += int(count)

    return sorted(tally.values(), key=lambda r: r.label)


async def queue_depth(session: AsyncSession) -> dict[str, int]:
    """Case counts by status, for §15's queue view."""
    rows = (
        await session.execute(
            select(Case.status, func.count(Case.id)).group_by(Case.status)
        )
    ).all()
    counts = {s.value: 0 for s in CaseStatus}
    for status, count in rows:
        counts[status.value if hasattr(status, "value") else str(status)] = int(count)
    return counts
