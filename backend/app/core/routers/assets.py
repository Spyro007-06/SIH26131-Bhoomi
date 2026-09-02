"""Foundation for F3, F8, F9 and F10 — every photo and voice note.

OWNER: Shreekumar

Serves:
    POST /assets/presign

Specified by: docs/API_CONTRACT.md §3. Presigned uploads only: the API never
receives raw bytes.
"""

from __future__ import annotations

import uuid
from functools import lru_cache

import boto3
from botocore.config import Config
from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from app.config import settings
from app.core.models import Asset
from app.core.schemas.assets import PresignIn, PresignOut
from app.db import get_session
from app.deps import Principal, current_principal
from app.errors import NotFound, error_response

router = APIRouter(prefix="/assets", tags=["assets"])


@lru_cache
def _s3():
    """One S3 client for the process.

    signature_version s3v4 is required by both MinIO and Supabase Storage for
    presigned PUTs; the boto3 default would produce URLs they reject.
    """
    return boto3.client(
        "s3",
        endpoint_url=settings.s3_endpoint_url,
        aws_access_key_id=settings.s3_access_key,
        aws_secret_access_key=settings.s3_secret_key,
        region_name=settings.s3_region,
        config=Config(signature_version="s3v4"),
    )


@router.post(
    "/presign",
    response_model=PresignOut,
    responses={
        **error_response(401, "No, or an invalid, bearer token."),
        **error_response(404, "`farm_id` was given but that farm does not exist."),
        **error_response(422, "The request body did not parse."),
    },
)
async def presign(
    payload: PresignIn,
    principal: Principal = Depends(current_principal),
    session: AsyncSession = Depends(get_session),
) -> PresignOut:
    """Mint an Asset row and return a presigned PUT URL.

    The row is written before the bytes exist. `uploaded_at` stays null until
    something confirms the upload, so an asset the client abandoned is
    distinguishable from one it completed — rather than a dangling id that looks
    identical to a real photo.
    """
    from app.core.models import Farm  # local: avoids a cycle at module import

    if payload.farm_id is not None and await session.get(Farm, payload.farm_id) is None:
        raise NotFound("That farm does not exist.")

    asset_id = uuid.uuid4()
    extension = {"image/jpeg": "jpg", "image/png": "png", "audio/mpeg": "mp3",
                 "audio/wav": "wav", "audio/webm": "webm"}.get(payload.content_type, "bin")
    object_key = f"{payload.kind.value}/{asset_id}.{extension}"

    asset = Asset(
        id=asset_id,
        kind=payload.kind,
        content_type=payload.content_type,
        object_key=object_key,
        farm_id=payload.farm_id,
    )
    session.add(asset)
    await session.commit()

    upload_url = _s3().generate_presigned_url(
        "put_object",
        Params={
            "Bucket": settings.s3_bucket,
            "Key": object_key,
            "ContentType": payload.content_type,
        },
        ExpiresIn=settings.presign_expiry_seconds,
    )

    return PresignOut(
        asset_id=asset_id,
        upload_url=upload_url,
        method="PUT",
        expires_in=settings.presign_expiry_seconds,
    )
