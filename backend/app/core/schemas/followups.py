"""Follow-up models. docs/API_CONTRACT.md §11.

OWNER: Shreekumar.
"""

from __future__ import annotations

import uuid
from datetime import datetime

from pydantic import BaseModel, Field

from app.contracts.enums import FollowupResponse, ProblemSeverity, TargetLabel


class PendingFollowUpOut(BaseModel):
    id: uuid.UUID
    problem_id: uuid.UUID
    label: TargetLabel | None = None
    severity: ProblemSeverity | None = None
    due_at: datetime
    overdue: bool


class PendingFollowUpListOut(BaseModel):
    followups: list[PendingFollowUpOut]


class FollowUpRespondIn(BaseModel):
    response: FollowupResponse
    image_asset_id: uuid.UUID | None = None


class SeverityChange(BaseModel):
    from_: ProblemSeverity | None = Field(default=None, alias="from")
    to: ProblemSeverity | None = None

    model_config = {"populate_by_name": True}


class FollowUpRespondOut(BaseModel):
    """docs/API_CONTRACT.md §11.

    `health` is F11 and belongs to Thaariha. Null, never a fabricated sentence —
    the same rule as the farm summary and for the same reason.
    """

    problem_id: uuid.UUID
    severity_change: SeverityChange | None = None
    health: None = Field(default=None, description="F11, owner Thaariha.")
    escalated: bool
    case_id: uuid.UUID | None = None
