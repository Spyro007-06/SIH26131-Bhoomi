"""Farm request and response models. docs/API_CONTRACT.md §5.

OWNER: Shreekumar.

`GeoPoint`, `Crop` and `GrowthStage` come from app/contracts/ and are not
redeclared here — contract C2 is the farm shape and it is frozen.
"""

from __future__ import annotations

import uuid
from datetime import datetime

from pydantic import BaseModel, Field

from app.contracts.enums import Crop, GrowthStage
from app.contracts.farm import GeoPoint


class FarmCreate(BaseModel):
    """`location` is required. docs/API_CONTRACT.md §5: "Spread alerts and the
    hotspot map are inoperable without it." Omitting it is a 422 through the
    error envelope, not a null column."""

    crop: Crop = Crop.PADDY
    variety: str | None = Field(default=None, max_length=120)
    growth_stage: GrowthStage
    region: str = Field(min_length=1, max_length=120)
    location: GeoPoint


class FarmUpdate(BaseModel):
    """PATCH — onboarding fields only.

    `location` is deliberately absent. Moving a farm invalidates every spread
    alert already issued against its coordinates, so it is not an onboarding
    edit; it would need its own endpoint and a decision about those alerts.
    """

    variety: str | None = Field(default=None, max_length=120)
    growth_stage: GrowthStage | None = None
    region: str | None = Field(default=None, min_length=1, max_length=120)


class FarmSummaryOut(BaseModel):
    """The `farm` sub-object of §5's create and summary responses."""

    id: uuid.UUID
    crop: Crop
    growth_stage: GrowthStage
    region: str


class FarmOut(BaseModel):
    """Full profile — `GET /farms/{id}`."""

    id: uuid.UUID
    farmer_id: uuid.UUID
    crop: Crop
    variety: str | None
    growth_stage: GrowthStage
    region: str
    location: GeoPoint
    created_at: datetime


class HomeSummaryOut(BaseModel):
    """`GET /farms/{id}/summary` — the home screen in one call, §5.

    `health` is F11 and belongs to **Thaariha**. It is null here, not a
    fabricated sentence: docs/API_CONTRACT.md §12's rule against placeholder
    strings exists because this project has shipped fake copy before, and
    docs/API_CONTRACT.md §5 is explicit that health is a sentence and a trend,
    with no numeric score field. Inventing either would be the same mistake.

    `spoken_summary` is likewise null until F9 (Shruthi) can produce it in the
    farmer's language. An English placeholder read aloud in Marathi is worse
    than silence.
    """

    farm: FarmSummaryOut
    health: None = Field(
        default=None,
        description="F11, owner Thaariha. Null until implemented — never a placeholder.",
    )
    open_problems: int
    pending_followups: int
    active_alerts: int
    spoken_summary: None = Field(
        default=None,
        description="F9, owner Shruthi. Null until TTS text is available in-language.",
    )
