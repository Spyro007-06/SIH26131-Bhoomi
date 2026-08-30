"""Password hashing, OTP generation and JWT minting.

OWNER: Shreekumar. Spec: docs/API_CONTRACT.md §0 and §2.

Deliberately not in core/services/ — those modules are one-per-feature and this
is shared plumbing under all three auth endpoints.
"""

from __future__ import annotations

import secrets
import uuid
from datetime import UTC, datetime, timedelta

import bcrypt
import jwt

from app.config import OTP_LENGTH, settings
from app.contracts.enums import Role

# ---------------------------------------------------------------------------
# Hashing
#
# bcrypt directly rather than through passlib: passlib 1.7.4 reads
# bcrypt.__about__, which bcrypt 4.x removed, and the resulting warning on every
# hash call is noise that trains people to ignore warnings.
# ---------------------------------------------------------------------------


def hash_secret(raw: str) -> str:
    """Hash a password or a one-time code."""
    return bcrypt.hashpw(raw.encode("utf-8"), bcrypt.gensalt()).decode("utf-8")


def verify_secret(raw: str, hashed: str) -> bool:
    """Constant-time comparison of a candidate against a stored hash."""
    try:
        return bcrypt.checkpw(raw.encode("utf-8"), hashed.encode("utf-8"))
    except (ValueError, TypeError):
        # A malformed stored hash must read as "wrong password", never as an
        # exception that a caller might treat as a different branch.
        return False


# ---------------------------------------------------------------------------
# One-time codes
# ---------------------------------------------------------------------------


def generate_otp() -> tuple[str, bool]:
    """Return (code, was_fixed).

    `DEV_FIXED_OTP` short-circuits generation only when BOTH conditions hold:
    the app is running with APP_ENV=local, and the value is actually set. There
    is no default and no fallback — an unset value means a real random code, in
    every environment including local. A fixed OTP that leaks into a deployed
    environment is an authentication bypass, so the check is explicit rather
    than a `getattr(..., "000000")`.
    """
    fixed = settings.dev_fixed_otp
    if settings.app_env == "local" and fixed:
        return fixed, True

    code = "".join(secrets.choice("0123456789") for _ in range(OTP_LENGTH))
    return code, False


# ---------------------------------------------------------------------------
# Tokens — docs/API_CONTRACT.md §0: Bearer JWT carrying a role claim
# ---------------------------------------------------------------------------


def _encode(subject: uuid.UUID, role: Role, expires: timedelta, token_type: str) -> str:
    now = datetime.now(UTC)
    payload = {
        "sub": str(subject),
        "role": role.value,
        "type": token_type,
        "iat": int(now.timestamp()),
        "exp": int((now + expires).timestamp()),
    }
    return jwt.encode(payload, settings.jwt_secret, algorithm=settings.jwt_algorithm)


def mint_access_token(subject: uuid.UUID, role: Role) -> str:
    return _encode(
        subject, role, timedelta(minutes=settings.access_token_expire_minutes), "access"
    )


def mint_refresh_token(subject: uuid.UUID, role: Role) -> str:
    return _encode(
        subject, role, timedelta(days=settings.refresh_token_expire_days), "refresh"
    )
