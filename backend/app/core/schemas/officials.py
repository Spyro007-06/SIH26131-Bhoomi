"""Officials dashboard models. docs/API_CONTRACT.md §15.

OWNER: Shreekumar (data); Santheesh renders these.

Shapes match §15 exactly so the Leaflet layer and the charts bind without
translation.
"""

from __future__ import annotations

from datetime import date

from pydantic import BaseModel, Field


class HotspotPointOut(BaseModel):
    lat: float
    lng: float
    label: str
    confirmed_count: int
    first_seen: date
    last_seen: date


class HotspotsOut(BaseModel):
    """Only confirmed cases appear. docs/API_CONTRACT.md §17 invariant 10."""

    points: list[HotspotPointOut]
    totals_by_label: dict[str, int] = Field(default_factory=dict)


class AccuracyRowOut(BaseModel):
    label: str
    confirmed: int
    corrected: int
    accuracy: float | None = Field(
        default=None,
        description="Null when nothing has been reviewed — not 0.0, which would "
        "read as a model that is wrong every time.",
    )


class AccuracyWindow(BaseModel):
    from_: date | None = Field(default=None, alias="from")
    to: date | None = None
    model_config = {"populate_by_name": True}


class AccuracyOut(BaseModel):
    by_label: list[AccuracyRowOut]
    window: AccuracyWindow


class QueueOut(BaseModel):
    by_status: dict[str, int]
    total: int
