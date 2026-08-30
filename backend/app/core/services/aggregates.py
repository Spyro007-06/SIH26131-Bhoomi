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

    Grouped on `Confirmation.model_label` — what the model actually predicted,
    frozen at confirm time by migration 0006.

    This previously grouped on `Problem.label`, which on a correction has already
    been overwritten with the corrected label. A case where the model said blast
    and the agronomist corrected it to brown_spot was reported as a correction
    against BROWN_SPOT: the label the model never predicted carried the penalty,
    and the label it got wrong looked clean. F15's headline metric read the
    inverse of the truth.

    The question this answers is "of the times the model said X, how often was it
    right". A correction therefore counts against the model's label ONLY. It does
    not add a confirmation to the corrected label, because the model never
    predicted that label and crediting it there would inflate its accuracy with a
    case it had no part in.

    `LabelPrior` records both facts — the model was wrong about X and the truth
    was Y — because the prior is a record of what has been seen in a place. This
    view is a record of model performance. They are different questions and it is
    correct that they count differently.

    Rows with a NULL model_label are EXCLUDED, not bucketed. Those are
    confirmations on problems that never had a diagnosis (escalated from a
    follow-up rather than a photo) or that migration 0006 refused to guess. A
    case the model never saw is not evidence about the model.
    """
    statement = (
        select(
            Confirmation.model_label,
            Confirmation.verdict,
            func.count(Confirmation.id),
        )
        .select_from(Confirmation)
        .join(Problem, Problem.id == Confirmation.problem_id)
        .where(Confirmation.model_label.is_not(None))
        .group_by(Confirmation.model_label, Confirmation.verdict)
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
