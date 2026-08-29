"""Shared request dependencies: the current principal and the role guard.

Owner: Shreekumar. Spec: docs/API_CONTRACT.md §0 (Bearer JWT, role claim).

Phase 0 provides the plumbing — decode, reject, guard by role. Issuing tokens is
Phase 1 (`/auth/otp/*`, `/auth/login`).
"""

from __future__ import annotations

import uuid
from dataclasses import dataclass

import jwt
from fastapi import Depends
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer

from app.config import settings
from app.contracts.enums import Role
from app.errors import Forbidden, Unauthenticated

bearer_scheme = HTTPBearer(auto_error=False)


@dataclass(frozen=True, slots=True)
class Principal:
    """The authenticated caller. `subject` is the user id from the `sub` claim."""

    subject: uuid.UUID
    role: Role


async def current_principal(
    credentials: HTTPAuthorizationCredentials | None = Depends(bearer_scheme),
) -> Principal:
    """Decode and validate the bearer token, or raise UNAUTHENTICATED.

    Errors are deliberately uniform: an expired token, a forged signature and a
    malformed subject all read the same to the caller.
    """
    if credentials is None or not credentials.credentials:
        raise Unauthenticated("Sign in to continue.")

    try:
        claims = jwt.decode(
            credentials.credentials,
            settings.jwt_secret,
            algorithms=[settings.jwt_algorithm],
        )
        return Principal(subject=uuid.UUID(claims["sub"]), role=Role(claims["role"]))
    except (jwt.PyJWTError, KeyError, ValueError) as exc:
        raise Unauthenticated("Session is not valid. Sign in again.") from exc


def require_role(*allowed: Role):
    """Dependency factory guarding an endpoint by role.

        @router.get("/hotspots", dependencies=[Depends(require_role(Role.OFFICIAL))])
    """

    async def _guard(principal: Principal = Depends(current_principal)) -> Principal:
        if principal.role not in allowed:
            raise Forbidden(
                "Your role cannot do this.",
                details={"required": [str(r) for r in allowed], "actual": str(principal.role)},
            )
        return principal

    return _guard
