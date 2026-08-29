"""Contract C2 · core -> everyone. docs/DESIGN.md §4, §5.

FROZEN at hour 2. Shreekumar produces these; every other workstream reads them.

Geolocation is required at creation. docs/DESIGN.md §4: "F6 and F15 are
inoperable without it, and retrofitting geometry after seed data exists is
painful." `location` is therefore non-optional here and NOT NULL in the ORM.

This is the wire/interchange shape. The `geography(Point, 4326)` column lives on
the ORM model in app/core/models.py (Phase 1); `GeoPoint` below is how that
column crosses a module boundary.
"""

from __future__ import annotations

import uuid
from datetime import datetime

from pydantic import BaseModel, Field

from app.contracts.enums import Crop, GrowthStage

SRID = 4326
"""WGS84. The only SRID in this system. docs/DESIGN.md §5."""


class GeoPoint(BaseModel):
    """A farm's location. Serialises as {"lat": ..., "lng": ...} per §5 of the
    API contract; stored as geography(Point, 4326)."""

    lat: float = Field(ge=-90.0, le=90.0)
    lng: float = Field(ge=-180.0, le=180.0)


class Farm(BaseModel):
    """The farm shape every module may rely on."""

    id: uuid.UUID
    farmer_id: uuid.UUID
    crop: Crop
    variety: str | None = None
    growth_stage: GrowthStage
    region: str
    location: GeoPoint = Field(description="Required. NOT NULL in the schema.")
    created_at: datetime
