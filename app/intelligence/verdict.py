"""Pesticide label verdict (F8) — selects a fixed string, composes nothing.

OWNER: Thaariha. Spec: docs/DESIGN.md §9, docs/API_CONTRACT.md §9.

The verdict is a TABLE LOOKUP against `registered_use`. No model is consulted and
the LLM is not in this path at all. This function chooses which VerdictCode
applies; the farmer-facing string is the frozen constant in
app.contracts.gate.VERDICT_MESSAGES and is rendered verbatim.

Safety constraints, not style (docs/API_CONTRACT.md §17, invariants 7 and 8):
  - No verdict message contains "safe", "approved", "you can use", or any other
    endorsement phrasing.
  - An ingredient absent from registered_use returns NOT_IN_RECORDS with
    escalation offered. The server never infers a verdict for an unknown chemical.
"""

from __future__ import annotations

from typing import Any


def verdict(
    extracted: Any,
    crop: str,
    target: str,
    days_to_harvest: int | None,
    matched_row: Any | None,
) -> Any:
    """Select the verdict code for a label check.

    `matched_row` is the `registered_use` row core/ looked up, or None. When it is
    None the answer is NOT_IN_RECORDS — never an inferred verdict.

    Return shape is docs/API_CONTRACT.md §9 (`verdict`): code, message,
    matched_row_id.

    Raises:
        NotImplementedError: owner Thaariha, docs/DESIGN.md §9.
    """
    raise NotImplementedError(
        "Label verdict not implemented — owner: Thaariha, docs/DESIGN.md §9. "
        "Messages come from app.contracts.gate.VERDICT_MESSAGES; do not reword them."
    )
