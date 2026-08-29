"""Contract C1 · vision -> intelligence. docs/DESIGN.md §4.

FROZEN at hour 2. Suchit produces these; Thaariha's gate consumes them.

Transcribed from the design doc. Field names are not negotiable — do not rename
`out_of_scope`, `model_version` or `is_stub`, and do not add fields here without
a team decision.
"""

from __future__ import annotations

from pydantic import BaseModel, Field, model_validator

TOPK_SIZE = 3
"""Exactly three predictions. Not "at least" and not "up to"."""


class Prediction(BaseModel):
    """One candidate from the bounded label set."""

    label: str = Field(description="Pest species or disease, from the bounded set")
    confidence: float = Field(ge=0.0, le=1.0)


class TopK(BaseModel):
    """The classifier's output, and the only thing the gate is allowed to see."""

    predictions: list[Prediction] = Field(
        description="Exactly 3, descending by confidence",
        min_length=TOPK_SIZE,
        max_length=TOPK_SIZE,
    )
    out_of_scope: bool = Field(
        description="True if the crop or target lies outside the bounded set"
    )
    model_version: str
    is_stub: bool = Field(
        description="True -> the UI must show a stub banner. docs/DESIGN.md §12."
    )

    @model_validator(mode="after")
    def _descending_by_confidence(self) -> TopK:
        """The design doc says descending; enforce it rather than trusting callers.

        The gate reads predictions[0] and predictions[1] as top-1 and top-2. If a
        producer ever hands back an unsorted list, every downstream threshold
        comparison is silently wrong, which is the failure mode this contract
        exists to prevent.
        """
        confidences = [p.confidence for p in self.predictions]
        if confidences != sorted(confidences, reverse=True):
            raise ValueError(
                f"TopK.predictions must be descending by confidence, got {confidences}"
            )
        return self
