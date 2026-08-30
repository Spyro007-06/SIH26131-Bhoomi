"""Case-file read models. docs/API_CONTRACT.md §11.

OWNER: Shreekumar.

-----------------------------------------------------------------------------
Everything optional here is `None`-by-omission, not `None`-by-placeholder.

Response models set `exclude_none=True` at the route, so a problem with no
advisory has NO `advisory` key — not `"advisory": null`, and certainly not an
empty object with blank strings in it. docs/API_CONTRACT.md §12's rule against
placeholder strings exists because this project has shipped fake copy before,
and the same discipline applies to these reads.
-----------------------------------------------------------------------------
"""

from __future__ import annotations

import uuid
from datetime import datetime
from typing import Literal

from pydantic import BaseModel, Field

from app.contracts.enums import (
    CueAnswer,
    GateOutcome,
    GateReasonCode,
    ProblemSeverity,
    ProblemStatus,
    ProblemType,
    TargetLabel,
    VerdictCode,
)
from app.contracts.vision import Prediction


class Page(BaseModel):
    """Cursor pagination envelope. docs/API_CONTRACT.md §0.

    `next_cursor` is null when exhausted — not absent, not an empty string. A
    client loops until it is null.
    """

    next_cursor: str | None = None


# --- problem list -----------------------------------------------------------


class ProblemListItem(BaseModel):
    id: uuid.UUID
    problem_type: ProblemType
    label: TargetLabel | None = None
    severity: ProblemSeverity | None = None
    status: ProblemStatus
    opened_at: datetime
    resolved_at: datetime | None = None


class ProblemListOut(Page):
    problems: list[ProblemListItem]


# --- problem detail ---------------------------------------------------------


class GateOut(BaseModel):
    outcome: GateOutcome
    confidence: float
    threshold_applied: float | None = None
    reason_code: GateReasonCode
    alternatives: list[Prediction]
    is_stub: bool


class DiagnosisOut(BaseModel):
    id: uuid.UUID
    label: TargetLabel | None = None
    gate: GateOut
    model_version: str
    image_asset_id: uuid.UUID | None = None
    created_at: datetime


class ObservationOut(BaseModel):
    id: uuid.UUID
    kind: Literal["doubt_doctor", "field_note"]
    question: str | None = None
    answer: CueAnswer | None = None
    created_at: datetime


class LadderRungOut(BaseModel):
    """A chemical rung carries dosage, PHI and re-entry or is omitted entirely.
    docs/API_CONTRACT.md §8."""

    tier: Literal["cultural", "biological", "chemical"]
    action: str
    dosage: str | None = None
    phi_days: int | None = None
    reentry_hours: int | None = None


class CitationOut(BaseModel):
    doc_id: str | None = None
    title: str
    reviewed_on: str | None = None


class AdvisoryOut(BaseModel):
    """docs/API_CONTRACT.md §8. `what_to_avoid` precedes `ladder` in the object
    and must be rendered first and loudest by clients."""

    id: uuid.UUID
    possible_issue: str
    what_to_check: str
    what_to_avoid: str
    ladder: list[LadderRungOut]
    expert_trigger: str | None = None
    citations: list[CitationOut] = Field(default_factory=list)
    created_at: datetime


class AssetOut(BaseModel):
    asset_id: uuid.UUID
    kind: str
    content_type: str
    at: datetime


class LabelCheckOut(BaseModel):
    id: uuid.UUID
    ingredient: str | None = None
    verdict: VerdictCode | None = None
    ocr_confidence: float | None = None
    at: datetime


class FollowUpOut(BaseModel):
    id: uuid.UUID
    due_at: datetime
    response: str | None = None
    responded_at: datetime | None = None


class ProblemDetailOut(BaseModel):
    """`GET /problems/{id}`.

    Optional sections are omitted when absent rather than emitted empty. A
    problem that has never been diagnosed has no `diagnosis` key.
    """

    id: uuid.UUID
    farm_id: uuid.UUID
    problem_type: ProblemType
    label: TargetLabel | None = None
    severity: ProblemSeverity | None = None
    status: ProblemStatus
    opened_at: datetime
    resolved_at: datetime | None = None

    diagnosis: DiagnosisOut | None = None
    advisory: AdvisoryOut | None = None
    observations: list[ObservationOut] = Field(default_factory=list)
    images: list[AssetOut] = Field(default_factory=list)
    label_checks: list[LabelCheckOut] = Field(default_factory=list)
    followups: list[FollowUpOut] = Field(default_factory=list)


# --- timeline ---------------------------------------------------------------


class TimelineEntry(BaseModel):
    """One dated event in the farm's case file.

    A flat, sorted stream rather than a nested tree: the app renders it as a
    list and the agronomist reads it top to bottom. `payload` carries the
    event-specific fields.
    """

    at: datetime
    kind: Literal[
        "problem_opened",
        "problem_resolved",
        "diagnosis",
        "observation",
        "advisory",
        "label_check",
        "followup_due",
        "followup_response",
        "alert_issued",
        "alert_response",
    ]
    problem_id: uuid.UUID | None = None
    summary: str
    payload: dict = Field(default_factory=dict)


class TimelineOut(Page):
    farm_id: uuid.UUID
    entries: list[TimelineEntry]
