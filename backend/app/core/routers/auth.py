"""Foundation for F1 — identity before a farm can persist.

OWNER: Shreekumar

Serves:
    POST /auth/otp/request
    POST /auth/otp/verify
    POST /auth/login

Specified by: docs/API_CONTRACT.md §2. Bearer JWT and the role claim are §0.
"""

from __future__ import annotations

from datetime import UTC, datetime, timedelta

from fastapi import APIRouter, Depends, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.config import OTP_MAX_ATTEMPTS, settings
from app.contracts.enums import Role
from app.core import security
from app.core.models import OtpRequest, User
from app.core.schemas.auth import (
    LoginIn,
    OtpRequestIn,
    OtpRequestOut,
    OtpVerifyIn,
    TokenOut,
    UserOut,
)
from app.db import get_session
from app.errors import BhoomiError, ErrorCode, Unauthenticated

router = APIRouter(prefix="/auth", tags=["auth"])


def _tokens_for(user: User) -> TokenOut:
    return TokenOut(
        access_token=security.mint_access_token(user.id, user.role),
        refresh_token=security.mint_refresh_token(user.id, user.role),
        user=UserOut(
            id=user.id, role=user.role, name=user.name, phone=user.phone, email=user.email
        ),
    )


@router.post("/otp/request", response_model=OtpRequestOut, status_code=status.HTTP_200_OK)
async def request_otp(
    payload: OtpRequestIn, session: AsyncSession = Depends(get_session)
) -> OtpRequestOut:
    """Mint a one-time code for a phone number.

    Returns the same shape whether or not the phone belongs to a known farmer.
    Telling an unauthenticated caller which numbers are registered turns this
    endpoint into a user-enumeration oracle, and the farmer-facing flow does not
    need the distinction — an unknown number simply never verifies.
    """
    code, was_fixed = security.generate_otp()
    otp = OtpRequest(
        phone=payload.phone,
        code_hash=security.hash_secret(code),
        expires_at=datetime.now(UTC) + timedelta(seconds=settings.otp_expire_seconds),
    )
    session.add(otp)
    await session.commit()
    await session.refresh(otp)

    if was_fixed:
        # Loud, because a fixed code is an authentication bypass if it ever
        # escapes local. security.generate_otp() already refuses to apply it
        # outside APP_ENV=local.
        import logging

        logging.getLogger("bhoomi.auth").warning(
            "DEV_FIXED_OTP in use for %s — local only, never a deployed environment.",
            payload.phone,
        )

    return OtpRequestOut(request_id=otp.id, expires_in=settings.otp_expire_seconds)


@router.post("/otp/verify", response_model=TokenOut)
async def verify_otp(
    payload: OtpVerifyIn, session: AsyncSession = Depends(get_session)
) -> TokenOut:
    """Exchange a code for tokens.

    The code is burned on success and attempt-capped on failure, so a captured
    request_id is not a brute-force target.
    """
    otp = await session.get(OtpRequest, payload.request_id)
    if otp is None:
        raise Unauthenticated("That code is not valid. Request a new one.")

    now = datetime.now(UTC)
    if otp.consumed_at is not None or otp.expires_at <= now:
        raise Unauthenticated("That code has expired. Request a new one.")
    if otp.attempts >= OTP_MAX_ATTEMPTS:
        raise Unauthenticated("Too many attempts. Request a new code.")

    if not security.verify_secret(payload.otp, otp.code_hash):
        otp.attempts += 1
        await session.commit()
        raise Unauthenticated("That code is not valid. Request a new one.")

    user = (
        await session.execute(select(User).where(User.phone == otp.phone))
    ).scalar_one_or_none()
    if user is None:
        # First correct code for an unknown number creates the farmer. OTP is
        # the farmer sign-up path in §2; there is no separate registration call.
        user = User(role=Role.FARMER, phone=otp.phone, name=otp.phone)
        session.add(user)

    otp.consumed_at = now
    await session.commit()
    await session.refresh(user)

    return _tokens_for(user)


@router.post("/login", response_model=TokenOut)
async def login(payload: LoginIn, session: AsyncSession = Depends(get_session)) -> TokenOut:
    """Email and password, for `agronomist` and `official`. §2.

    Farmers cannot reach this path: the app_user CHECK guarantees a farmer row
    has no password_hash, so verify_secret has nothing to match against.
    """
    user = (
        await session.execute(select(User).where(User.email == payload.email))
    ).scalar_one_or_none()

    if user is None or not user.password_hash:
        raise Unauthenticated("Email or password is not correct.")
    if not security.verify_secret(payload.password, user.password_hash):
        raise Unauthenticated("Email or password is not correct.")
    if user.role not in (Role.AGRONOMIST, Role.OFFICIAL):
        raise BhoomiError(
            ErrorCode.FORBIDDEN, "This account signs in with a phone number instead."
        )

    return _tokens_for(user)
