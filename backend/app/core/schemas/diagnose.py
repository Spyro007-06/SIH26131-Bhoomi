"""POST /farms/{id}/diagnose response models. docs/API_CONTRACT.md §6.

OWNER: Shreekumar. Orchestration only — the shapes here cover exactly what
this build's orchestration produces: `escalate`, and `clarify` when no
matching DistinguishingCue exists (the only reachable path while that table
is empty). `advisory` and a populated `clarification` (a cue WAS found) are
not modelled here — those responses are never produced by this build; see
app/core/routers/diagnose.py's module docstring for why (F7's composer, F4's
question flow, both Thaariha's, both still 501).
"""

from __future__ import annotations

import uuid

from pydantic import BaseModel, Field

from app.contracts.enums import ProblemType
from app.contracts.vision import Prediction


class DiagnoseIn(BaseModel):
    """docs/API_CONTRACT.md §6. `description_asset_id` / `description_text`
    are optional supplementary context (a voice note or typed note alongside
    the photo) — unused by this build's orchestration, which does not touch
    NLU or retrieval, but accepted so a client sending them is not refused."""

    image_asset_id: uuid.UUID
    description_asset_id: uuid.UUID | None = None
    description_text: str | None = None
    lang: str


class GateOut(BaseModel):
    """Mirrors contract C3's GateDecision. Not GateDecision itself: this is
    the HTTP-facing shape, and outcome/reason_code here can differ from what
    decide() returned — see EscalationOut's docstring for the one case where
    that happens (clarify, no cue found)."""

    outcome: str
    confidence: float = Field(ge=0.0, le=1.0)
    threshold_applied: float
    reason_code: str
    alternatives: list[Prediction]
    is_stub: bool


class EscalationOut(BaseModel):
    """docs/API_CONTRACT.md §6's escalation block.

    `assigned_to` is rendered "agronomist:<slug>" from the assigned User's
    email domain (no dedicated column for this exists on User — see
    app/core/routers/diagnose.py's _agronomist_slug()). `None` when the
    queue has no agronomist to assign, honestly, not a placeholder.
    """

    case_id: uuid.UUID
    assigned_to: str | None
    queue_position: int | None
    eta_minutes: int | None


class DiagnoseOut(BaseModel):
    """docs/API_CONTRACT.md §6. `problem_type` is included on every branch —
    the frozen doc's clarify/escalate examples omit it, read as abbreviation
    rather than exclusion: Problem always has a type, and the field is
    genuinely meaningful on every branch, not conditional on gate outcome.

    `escalation` is the only populated branch field this build ever produces.
    `spoken_summary` is Shruthi's (F9) and stays null until she wires it."""

    gate: GateOut
    problem_id: uuid.UUID
    problem_type: ProblemType
    escalation: EscalationOut | None = None
    spoken_summary: None = Field(
        default=None, description="F9, owner Shruthi. Null until wired."
    )
