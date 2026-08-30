"""Alert models. docs/API_CONTRACT.md §10.

OWNER: Shreekumar.
"""

from __future__ import annotations

import uuid
from datetime import datetime

from pydantic import BaseModel, Field

from app.contracts.enums import AlertOutcome, AlertTrigger, TargetLabel
from app.core.schemas.problems import Page


class AlertOut(BaseModel):
    """`inspection_tasks` is never empty — the CHECK constraint refuses to store
    an alert without at least one. docs/API_CONTRACT.md §17 invariant 6."""

    id: uuid.UUID
    trigger_type: AlertTrigger
    target: TargetLabel
    risk_level: str
    reason: str
    inspection_tasks: list[str]
    issued_at: datetime
    outcome: AlertOutcome | None = None
    spoken_summary: None = Field(
        default=None,
        description="F9, owner Shruthi. Null until TTS text exists in-language.",
    )


class AlertListOut(Page):
    alerts: list[AlertOut]


class AlertRespondIn(BaseModel):
    outcome: AlertOutcome
    image_asset_id: uuid.UUID | None = None


class AlertRespondOut(BaseModel):
    alert_id: uuid.UUID
    outcome: AlertOutcome
    diagnose_suggested: bool
