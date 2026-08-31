"""HTTP surface for ASR and TTS. docs/API_CONTRACT.md §4.

OWNER: Shruthi. Spec: docs/API_CONTRACT.md §4, docs/DESIGN.md §3, §12.

Serves:
    POST /voice/transcribe
    POST /voice/synthesize

Handlers call straight through to app.voice.asr.transcribe() and
app.voice.tts.synthesize() — S0's provider seam, stub-backed by default via
settings.asr_provider. No DB, no presigned-bytes fetch (the stub reads
nothing), no live Sarvam call.
"""

from __future__ import annotations

import uuid
from typing import Literal

from fastapi import APIRouter, Depends
from pydantic import BaseModel, Field

from app.contracts.enums import Lang
from app.deps import Principal, current_principal
from app.voice.asr import transcribe
from app.voice.tts import synthesize

router = APIRouter(prefix="/voice", tags=["voice"])


class TranscribeIn(BaseModel):
    asset_id: uuid.UUID
    lang: Lang
    context: Literal["onboarding", "doubt_doctor", "query"]


class ParsedIntentOut(BaseModel):
    field: str
    value: str


class TranscribeOut(BaseModel):
    text: str
    confidence: float | None = Field(
        default=None,
        ge=0.0,
        le=1.0,
        description=(
            "Omitted (via response_model_exclude_none) when the provider "
            "reports none — live Sarvam Saaras never does. Never a "
            "fabricated sentinel. docs/API_CONTRACT.md §4 shows this as "
            "always-numeric; live mode is a deliberate, flagged deviation."
        ),
    )
    lang: Lang
    parsed_intent: ParsedIntentOut | None = None
    needs_confirmation: bool
    is_stub: bool = Field(
        description="True -> the client must show a stub banner. docs/DESIGN.md §12."
    )


class SynthesizeIn(BaseModel):
    text: str
    lang: Lang


class SynthesizeOut(BaseModel):
    audio_url: str
    expires_in: int
    is_stub: bool = Field(
        description="True -> the client must show a stub banner. docs/DESIGN.md §12."
    )


@router.post("/transcribe", response_model=TranscribeOut, response_model_exclude_none=True)
async def transcribe_voice(
    payload: TranscribeIn,
    principal: Principal = Depends(current_principal),
) -> TranscribeOut:
    """Transcribe an uploaded audio asset. docs/API_CONTRACT.md §4.

    Below `config.ASR_FLOOR`, `parsed_intent` is omitted from the response
    entirely (not `null`) — `response_model_exclude_none` renders that;
    app.voice.asr.transcribe() decides it. `confidence` is omitted the same
    way when the provider reports none (live Sarvam Saaras never does).
    """
    result = transcribe(str(payload.asset_id), payload.lang, payload.context)
    parsed_intent = (
        ParsedIntentOut(field=result.parsed_intent.field, value=result.parsed_intent.value)
        if result.parsed_intent is not None
        else None
    )
    return TranscribeOut(
        text=result.text,
        confidence=result.confidence,
        lang=result.lang,
        parsed_intent=parsed_intent,
        needs_confirmation=result.needs_confirmation,
        is_stub=result.is_stub,
    )


@router.post("/synthesize", response_model=SynthesizeOut)
async def synthesize_voice(
    payload: SynthesizeIn,
    principal: Principal = Depends(current_principal),
) -> SynthesizeOut:
    """Render text to audio and return a presigned URL. docs/API_CONTRACT.md §4."""
    result = synthesize(payload.text, payload.lang)
    return SynthesizeOut(
        audio_url=result.audio_url,
        expires_in=result.expires_in,
        is_stub=result.is_stub,
    )
