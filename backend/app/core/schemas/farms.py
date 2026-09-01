"""Farm request and response models. docs/API_CONTRACT.md §5.

OWNER: Shreekumar.

`GeoPoint` and `Crop` come from app/contracts/ and are not
redeclared here — contract C2 is the farm shape and it is frozen.
"""

from __future__ import annotations

import uuid
from datetime import date, datetime
from typing import Literal

from pydantic import BaseModel, Field, model_validator

from app.contracts.enums import Crop, GrowthStageKey
from app.contracts.farm import GeoPoint

# Read-back guarantee, structural rather than client convention. PRD F9: a
# voice-derived consequential value must be read back and confirmed before it
# is saved. Whole-request granularity, not per-field -- if anything in the
# payload came from voice, the client marks the whole request voice, and
# everything in it needs confirmation before it saves; a farmer editing a
# spoken value before saving makes it a typed correction, sent as "typed" (or
# omitted). `input_source` and `confirmed` are validated here and travel no
# further: neither is a column on Farm. The guarantee lives at the write
# boundary -- an unconfirmed voice value cannot be persisted, so recording
# that a persisted one WAS confirmed adds state without adding information.
# Same reasoning as not storing sowing_date's derived days-after-sowing,
# above.
VOICE_CONFIRMATION_FIELDS = frozenset({"input_source", "confirmed"})


class _VoiceConfirmationMixin(BaseModel):
    input_source: Literal["typed", "voice"] = "typed"
    confirmed: bool = False

    @model_validator(mode="after")
    def _voice_input_must_be_confirmed(self) -> _VoiceConfirmationMixin:
        if self.input_source == "voice" and not self.confirmed:
            raise ValueError(
                "input_source is 'voice' but confirmed is not true -- read the "
                "value back to the farmer and confirm it before saving."
            )
        return self


class FarmCreate(_VoiceConfirmationMixin):
    """`location` is required. docs/API_CONTRACT.md §5: "Spread alerts and the
    hotspot map are inoperable without it." Omitting it is a 422 through the
    error envelope, not a null column."""

    crop: Crop = Crop.PADDY
    """Defaults to paddy for v2 clients that predate the four-crop scope. A
    client sending no crop gets the crop the whole v2 product was."""
    variety: str | None = Field(default=None, max_length=120)
    growth_stage: GrowthStageKey
    region: str = Field(min_length=1, max_length=120)
    sowing_date: date | None = Field(
        default=None,
        description=(
            "Optional. The F5 phenology branch derives days-after-sowing from "
            "this on read; nothing stores that integer, because it would be "
            "wrong the next morning."
        ),
    )
    location: GeoPoint


class FarmUpdate(_VoiceConfirmationMixin):
    """PATCH — onboarding fields only.

    `location` is deliberately absent. Moving a farm invalidates every spread
    alert already issued against its coordinates, so it is not an onboarding
    edit; it would need its own endpoint and a decision about those alerts.
    """

    variety: str | None = Field(default=None, max_length=120)
    growth_stage: GrowthStageKey | None = None
    region: str | None = Field(default=None, min_length=1, max_length=120)
    sowing_date: date | None = None


class FarmSummaryOut(BaseModel):
    """The `farm` sub-object of §5's create and summary responses."""

    id: uuid.UUID
    crop: Crop
    growth_stage: GrowthStageKey
    region: str


class FarmOut(BaseModel):
    """Full profile — `GET /farms/{id}`."""

    id: uuid.UUID
    farmer_id: uuid.UUID
    crop: Crop
    variety: str | None
    growth_stage: GrowthStageKey
    region: str
    sowing_date: date | None
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
