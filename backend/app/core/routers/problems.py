"""F1 case file, F11 farm health.

OWNER: Shreekumar

Serves:
    GET /problems/{id}
    GET /farms/{id}/problems
    GET /farms/{id}/timeline

Specified by: docs/API_CONTRACT.md §11.

-----------------------------------------------------------------------------
Audience: these are the farmer's own case file. A farmer reads only their own
farms. `agronomist` and `official` are refused with 403 rather than being
silently handed an empty list — an agronomist works from the case bundle
(§12) and an official from the aggregates (§15), and a quietly-empty response
would read to either of them as "this farm has no history", which is a
different and wrong statement.

Nothing here is fabricated. On `GET /problems/{id}` a problem with no advisory
has no `advisory` key at all — that route sets response_model_exclude_none.
The two paginated routes deliberately do NOT, because §0 requires next_cursor to
be present and null when exhausted.
-----------------------------------------------------------------------------
"""

from __future__ import annotations

import uuid
from datetime import datetime
from typing import Any

from fastapi import APIRouter, Depends, Query
from sqlalchemy import or_, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.contracts.enums import ProblemStatus, ProblemType, Role
from app.core.models import (
    Advisory,
    Alert,
    Asset,
    Diagnosis,
    Farm,
    FollowUp,
    LabelCheck,
    Observation,
    Problem,
)
from app.core.pagination import clamp_limit, decode_cursor, encode_cursor
from app.core.schemas.problems import (
    AdvisoryOut,
    AssetOut,
    DiagnosisOut,
    FollowUpOut,
    GateOut,
    LabelCheckOut,
    ObservationOut,
    ProblemDetailOut,
    ProblemListItem,
    ProblemListOut,
    TimelineEntry,
    TimelineOut,
)
from app.db import get_session
from app.deps import Principal, current_principal
from app.errors import Forbidden, NotFound

router = APIRouter(tags=["case file"])


def _require_farmer(principal: Principal) -> None:
    """This case file is the farmer's own. See the module docstring."""
    if principal.role != Role.FARMER:
        raise Forbidden(
            "This case file is read by the farmer who owns it.",
            details={
                "actual": str(principal.role),
                "agronomist": "GET /cases/{id} carries the case bundle",
                "official": "GET /officials/hotspots carries the aggregates",
            },
        )


async def _owned_farm(
    farm_id: uuid.UUID, principal: Principal, session: AsyncSession
) -> Farm:
    _require_farmer(principal)
    farm = await session.get(Farm, farm_id)
    if farm is None:
        raise NotFound("That farm does not exist.")
    if farm.farmer_id != principal.subject:
        raise Forbidden("That farm belongs to a different account.")
    return farm


async def _owned_problem(
    problem_id: uuid.UUID, principal: Principal, session: AsyncSession
) -> tuple[Problem, Farm]:
    _require_farmer(principal)
    problem = await session.get(Problem, problem_id)
    if problem is None:
        raise NotFound("That problem does not exist.")
    farm = await session.get(Farm, problem.farm_id)
    if farm is None or farm.farmer_id != principal.subject:
        # Same message and status as a missing problem: telling a caller that a
        # problem exists but belongs to someone else leaks the id space.
        raise NotFound("That problem does not exist.")
    return problem, farm


def _gate_from(diagnosis: Diagnosis) -> GateOut:
    topk: dict[str, Any] = diagnosis.topk or {}
    return GateOut(
        outcome=diagnosis.gate_outcome,
        confidence=float(diagnosis.gate_confidence),
        threshold_applied=topk.get("threshold_applied"),
        reason_code=diagnosis.reason_code,
        alternatives=topk.get("predictions", []),
        is_stub=diagnosis.is_stub,
    )


# ---------------------------------------------------------------------------
# GET /farms/{id}/problems
# ---------------------------------------------------------------------------


@router.get(
    "/farms/{farm_id}/problems",
    response_model=ProblemListOut,
    # NOT exclude_none. docs/API_CONTRACT.md §0 requires next_cursor to be
    # present and null when exhausted — a client loops until it sees null, and
    # omitting the key entirely breaks that loop. The omit-what-is-absent rule
    # applies to the detail endpoint, not to this envelope.
)
async def list_problems(
    farm_id: uuid.UUID,
    status: ProblemStatus | None = Query(default=None),
    type: ProblemType | None = Query(default=None, alias="type"),
    limit: int | None = Query(default=None, ge=1),
    cursor: str | None = Query(default=None),
    principal: Principal = Depends(current_principal),
    session: AsyncSession = Depends(get_session),
) -> ProblemListOut:
    """Filtered, paginated problem list. Newest first."""
    farm = await _owned_farm(farm_id, principal, session)

    page_size = clamp_limit(limit)
    keyset = decode_cursor(cursor)

    statement = select(Problem).where(Problem.farm_id == farm.id)
    if status is not None:
        statement = statement.where(Problem.status == status)
    if type is not None:
        statement = statement.where(Problem.problem_type == type)
    if keyset is not None:
        at, row_id = keyset
        statement = statement.where(
            or_(
                Problem.opened_at < at,
                (Problem.opened_at == at) & (Problem.id < row_id),
            )
        )

    # One extra row tells us whether a next page exists without a second COUNT.
    statement = statement.order_by(Problem.opened_at.desc(), Problem.id.desc()).limit(
        page_size + 1
    )
    rows = list((await session.execute(statement)).scalars().all())

    has_more = len(rows) > page_size
    rows = rows[:page_size]

    return ProblemListOut(
        problems=[
            ProblemListItem(
                id=p.id,
                problem_type=p.problem_type,
                label=p.label,
                severity=p.severity,
                status=p.status,
                opened_at=p.opened_at,
                resolved_at=p.resolved_at,
            )
            for p in rows
        ],
        next_cursor=encode_cursor(rows[-1].opened_at, rows[-1].id) if has_more else None,
    )


# ---------------------------------------------------------------------------
# GET /problems/{id}
# ---------------------------------------------------------------------------


@router.get(
    "/problems/{problem_id}",
    response_model=ProblemDetailOut,
    response_model_exclude_none=True,
)
async def get_problem(
    problem_id: uuid.UUID,
    principal: Principal = Depends(current_principal),
    session: AsyncSession = Depends(get_session),
) -> ProblemDetailOut:
    """Detail with photos, observations and advisory.

    Returns whatever exists and omits what does not. No section is emitted
    empty-but-present, and nothing is invented to fill a shape.
    """
    problem, _ = await _owned_problem(problem_id, principal, session)

    diagnosis = (
        await session.execute(
            select(Diagnosis)
            .where(Diagnosis.problem_id == problem.id)
            .order_by(Diagnosis.created_at.desc())
            .limit(1)
        )
    ).scalar_one_or_none()

    advisory = (
        await session.execute(
            select(Advisory)
            .where(Advisory.problem_id == problem.id)
            .order_by(Advisory.created_at.desc())
            .limit(1)
        )
    ).scalar_one_or_none()

    observations = list(
        (
            await session.execute(
                select(Observation)
                .where(Observation.problem_id == problem.id)
                .order_by(Observation.created_at)
            )
        ).scalars().all()
    )
    label_checks = list(
        (
            await session.execute(
                select(LabelCheck)
                .where(LabelCheck.problem_id == problem.id)
                .order_by(LabelCheck.created_at)
            )
        ).scalars().all()
    )
    followups = list(
        (
            await session.execute(
                select(FollowUp)
                .where(FollowUp.problem_id == problem.id)
                .order_by(FollowUp.due_at)
            )
        ).scalars().all()
    )

    asset_ids = [
        a
        for a in (
            [diagnosis.image_asset_id] if diagnosis else []
        )
        + [lc.image_asset_id for lc in label_checks]
        + [f.image_asset_id for f in followups]
        if a is not None
    ]
    images: list[AssetOut] = []
    if asset_ids:
        assets = (
            await session.execute(select(Asset).where(Asset.id.in_(asset_ids)))
        ).scalars().all()
        images = [
            AssetOut(
                asset_id=a.id,
                kind=a.kind.value if hasattr(a.kind, "value") else str(a.kind),
                content_type=a.content_type,
                at=a.uploaded_at or a.created_at,
            )
            for a in assets
        ]

    return ProblemDetailOut(
        id=problem.id,
        farm_id=problem.farm_id,
        problem_type=problem.problem_type,
        label=problem.label,
        severity=problem.severity,
        status=problem.status,
        opened_at=problem.opened_at,
        resolved_at=problem.resolved_at,
        diagnosis=(
            DiagnosisOut(
                id=diagnosis.id,
                label=problem.label,
                gate=_gate_from(diagnosis),
                model_version=diagnosis.model_version,
                image_asset_id=diagnosis.image_asset_id,
                created_at=diagnosis.created_at,
            )
            if diagnosis
            else None
        ),
        advisory=(
            AdvisoryOut(
                id=advisory.id,
                possible_issue=advisory.possible_issue,
                what_to_check=advisory.what_to_check,
                what_to_avoid=advisory.what_to_avoid,
                ladder=advisory.ladder,
                expert_trigger=advisory.expert_trigger,
                citations=advisory.citations or [],
                created_at=advisory.created_at,
            )
            if advisory
            else None
        ),
        observations=[
            ObservationOut(
                id=o.id,
                kind=o.kind,
                question=o.question,
                answer=o.answer,
                created_at=o.created_at,
            )
            for o in observations
        ],
        images=images,
        label_checks=[
            LabelCheckOut(
                id=lc.id,
                ingredient=(lc.extracted or {}).get("active_ingredient"),
                verdict=lc.verdict_code,
                ocr_confidence=float(lc.ocr_confidence) if lc.ocr_confidence else None,
                at=lc.created_at,
            )
            for lc in label_checks
        ],
        followups=[
            FollowUpOut(
                id=f.id,
                due_at=f.due_at,
                response=f.response.value if f.response else None,
                responded_at=f.responded_at,
            )
            for f in followups
        ],
    )


# ---------------------------------------------------------------------------
# GET /farms/{id}/timeline
# ---------------------------------------------------------------------------


def _entry(at: datetime, kind: str, summary: str, problem_id, **payload) -> TimelineEntry:
    """Build one timeline entry.

    Payload keys must not collide with this signature. A payload named `kind` or
    `summary` binds to the parameter instead and raises TypeError at request
    time, not import time — so it is asserted here where the message is obvious.
    """
    collisions = {"at", "kind", "summary", "problem_id"} & set(payload)
    assert not collisions, f"payload keys shadow _entry parameters: {sorted(collisions)}"
    return TimelineEntry(
        at=at, kind=kind, summary=summary, problem_id=problem_id, payload=payload
    )


@router.get(
    "/farms/{farm_id}/timeline",
    response_model=TimelineOut,
    # NOT exclude_none — see list_problems above, §0's next_cursor rule.
)
async def farm_timeline(
    farm_id: uuid.UUID,
    limit: int | None = Query(default=None, ge=1),
    cursor: str | None = Query(default=None),
    principal: Principal = Depends(current_principal),
    session: AsyncSession = Depends(get_session),
) -> TimelineOut:
    """Chronological case file, newest first.

    Assembled in Python from six tables rather than as a UNION: the row shapes
    have almost nothing in common, and a UNION would need every column widened
    to text. The volume is one farm's history, which is small by construction.
    """
    farm = await _owned_farm(farm_id, principal, session)
    page_size = clamp_limit(limit)
    keyset = decode_cursor(cursor)

    problems = list(
        (
            await session.execute(select(Problem).where(Problem.farm_id == farm.id))
        ).scalars().all()
    )
    problem_ids = [p.id for p in problems]

    entries: list[TimelineEntry] = []

    for p in problems:
        entries.append(
            _entry(
                p.opened_at, "problem_opened", f"Problem opened: {p.problem_type.value}",
                p.id, label=p.label.value if p.label else None, severity=
                p.severity.value if p.severity else None,
            )
        )
        if p.resolved_at:
            entries.append(
                _entry(p.resolved_at, "problem_resolved", "Problem resolved", p.id)
            )

    if problem_ids:
        for d in (
            await session.execute(select(Diagnosis).where(Diagnosis.problem_id.in_(problem_ids)))
        ).scalars().all():
            entries.append(
                _entry(
                    d.created_at, "diagnosis",
                    f"Diagnosis: gate {d.gate_outcome.value} ({d.reason_code.value})",
                    d.problem_id, gate_outcome=d.gate_outcome.value,
                    reason_code=d.reason_code.value,
                    confidence=float(d.gate_confidence), is_stub=d.is_stub,
                    model_version=d.model_version,
                )
            )

        for o in (
            await session.execute(
                select(Observation).where(Observation.problem_id.in_(problem_ids))
            )
        ).scalars().all():
            entries.append(
                _entry(
                    o.created_at, "observation",
                    o.question or "Field observation recorded", o.problem_id,
                    # NOT `kind=` — that is _entry's own parameter and a payload
                    # key of the same name binds to it instead.
                    observation_kind=o.kind,
                    answer=o.answer.value if o.answer else None,
                )
            )

        for a in (
            await session.execute(select(Advisory).where(Advisory.problem_id.in_(problem_ids)))
        ).scalars().all():
            entries.append(
                _entry(a.created_at, "advisory", a.possible_issue, a.problem_id,
                       what_to_avoid=a.what_to_avoid, rungs=len(a.ladder or []))
            )

        for lc in (
            await session.execute(
                select(LabelCheck).where(LabelCheck.problem_id.in_(problem_ids))
            )
        ).scalars().all():
            ingredient = (lc.extracted or {}).get("active_ingredient")
            entries.append(
                _entry(
                    lc.created_at, "label_check",
                    f"Label check: {ingredient or 'unreadable'}", lc.problem_id,
                    verdict=lc.verdict_code.value if lc.verdict_code else None,
                )
            )

        for f in (
            await session.execute(select(FollowUp).where(FollowUp.problem_id.in_(problem_ids)))
        ).scalars().all():
            entries.append(
                _entry(f.due_at, "followup_due", "Follow-up check-in due", f.problem_id)
            )
            if f.responded_at:
                entries.append(
                    _entry(
                        f.responded_at, "followup_response",
                        f"Follow-up: {f.response.value if f.response else 'answered'}",
                        f.problem_id,
                    )
                )

    for al in (
        await session.execute(select(Alert).where(Alert.farm_id == farm.id))
    ).scalars().all():
        entries.append(
            _entry(
                al.issued_at, "alert_issued",
                f"{al.risk_level} risk alert: {al.target.value}", None,
                trigger_type=al.trigger_type.value, reason=al.reason,
                inspection_tasks=al.inspection_tasks,
                outcome=al.outcome.value if al.outcome else None,
            )
        )

    entries.sort(key=lambda e: e.at, reverse=True)

    if keyset is not None:
        at, _ = keyset
        entries = [e for e in entries if e.at < at]

    has_more = len(entries) > page_size
    page = entries[:page_size]

    return TimelineOut(
        farm_id=farm.id,
        entries=page,
        next_cursor=(
            encode_cursor(page[-1].at, page[-1].problem_id or farm.id) if has_more else None
        ),
    )
