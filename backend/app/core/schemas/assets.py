"""Presigned upload models. docs/API_CONTRACT.md §3.

OWNER: Shreekumar.

The API never receives raw bytes. The client PUTs to `upload_url` and then
references `asset_id` downstream.
"""

from __future__ import annotations

import uuid

from pydantic import BaseModel, Field

from app.contracts.enums import AssetKind


class PresignIn(BaseModel):
    kind: AssetKind
    content_type: str = Field(max_length=127, examples=["image/jpeg"])
    farm_id: uuid.UUID | None = None


class PresignOut(BaseModel):
    asset_id: uuid.UUID
    upload_url: str
    method: str = "PUT"
    expires_in: int
