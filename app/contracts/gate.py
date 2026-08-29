"""Contract C3 · intelligence -> clients. docs/DESIGN.md §4, §9.

FROZEN at hour 2. Thaariha produces `GateDecision`; the Flutter app, the portal
and the dashboard all render it.

Two things live here:

1. `GateDecision` — the gate's output shape (docs/DESIGN.md §4, §6).
2. `VERDICT_MESSAGES` — the six fixed F8 verdict strings (docs/DESIGN.md §9).

On (2): the design doc assigns ownership of the verdict copy to `intelligence/`.
It is transcribed into `contracts/` because it is frozen wire text that three
clients render verbatim, and freezing it next to the other contracts is what
stops it drifting. `app/intelligence/` remains the module that decides which
code applies; it does not get to reword the string.
"""

from __future__ import annotations

from typing import Literal

from pydantic import BaseModel, Field

from app.contracts.enums import VerdictCode
from app.contracts.vision import Prediction


class GateDecision(BaseModel):
    """The choke point's output. Exactly one outcome, always with alternatives."""

    outcome: Literal["advise", "clarify", "escalate"]
    confidence: float = Field(ge=0.0, le=1.0)
    threshold_applied: float
    reason_code: str = Field(
        description="BELOW_FLOOR | AMBIGUOUS | OUT_OF_SCOPE | NO_RELEVANT_SOURCE | ABOVE_GATE"
    )
    alternatives: list[Prediction] = Field(
        description=(
            "Always populated, on every branch including advise. "
            "The farmer always sees what else was considered. "
            "docs/API_CONTRACT.md §17 invariant 3."
        )
    )


# ---------------------------------------------------------------------------
# F8 verdict copy — docs/DESIGN.md §9, docs/API_CONTRACT.md §9.
#
# Rendered verbatim by clients. The app never composes pesticide-safety copy.
#
# Note what is absent: "safe", "approved", "you can use". The vocabulary itself
# makes endorsement impossible. docs/DESIGN.md §9 calls this a review checklist
# item, not a style preference — see ENDORSEMENT_VOCABULARY below and the test
# in tests/test_contracts.py.
# ---------------------------------------------------------------------------

VERDICT_MESSAGES: dict[VerdictCode, str] = {
    VerdictCode.NO_OBJECTION_FOUND: (
        "No objection found. Follow the printed label for dosage."
    ),
    VerdictCode.NOT_REGISTERED_FOR_TARGET: (
        "This product is not registered for this pest. Do not use it here."
    ),
    VerdictCode.WRONG_CROP: "This product is not registered for paddy.",
    VerdictCode.WRONG_CLASS: "This is a fungicide. Your problem is an insect pest.",
    VerdictCode.PHI_CONFLICT: (
        "Harvest is too close. This product needs N days before harvest."
    ),
    VerdictCode.NOT_IN_RECORDS: (
        "I do not have a record of this product. Ask an expert before using it."
    ),
}

ENDORSEMENT_VOCABULARY: tuple[str, ...] = (
    "safe",
    "approved",
    "you can use",
    "recommended",
    "permitted",
    "allowed",
    "certified",
)
"""Words no verdict message may contain. docs/API_CONTRACT.md §17 invariant 7."""


def phi_conflict_message(phi_days: int) -> str:
    """The only permitted transformation of a verdict string: substituting the
    real pre-harvest interval for the literal N in PHI_CONFLICT.

    Nothing else may reword, translate-in-place or extend these strings on the
    server. Localisation happens by looking up a translation of the whole fixed
    string, not by composing new copy.
    """
    return VERDICT_MESSAGES[VerdictCode.PHI_CONFLICT].replace("N days", f"{phi_days} days")
