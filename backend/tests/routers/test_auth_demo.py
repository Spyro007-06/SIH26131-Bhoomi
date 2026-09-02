"""POST /auth/demo -- fail-closed by default. docs/API_CONTRACT.md §2.

This route used to default open: demo_mode defaulted True, and app_env did
no gating work because the check was an AND inside a negation (`if not
demo_mode and app_env != "local"` blocks only when BOTH are true). A request
with no body minted tokens for a fixed farmer identity in any deployment
where nobody had explicitly set DEMO_MODE=false. See the commit that added
this file for the incident.

Mounting is decided once, at create_app() time, from settings.demo_mode --
so the "not mounted" and "refused" cases build their own app per test rather
than using the shared session-scoped `client` fixture (which is built once,
lazily, on first use across the whole suite; mutating the shared settings
singleton around it would leak into whichever test happens to trigger that
first build). Neither of those two cases queries the database (the FORBIDDEN
raise in demo_login happens before the session is touched), so no db_session
is needed for them.

The "found" and "not found" cases call demo_login() directly with db_session
rather than going over HTTP through a fresh TestClient -- same reason
test_farms_diagnose.py calls diagnose_farm() directly: a TestClient's app
runs on app.db's own engine, a separate connection from db_session's
rolled-back-on-teardown transaction, so a row inserted through db_session
would not be visible to it.
"""

from __future__ import annotations

import uuid

import pytest
from fastapi.testclient import TestClient

from app import config
from app.config import settings
from app.contracts.enums import Role
from app.core.models import User
from app.core.routers import auth as auth_router
from app.errors import NotFound

DEMO_PATH = f"{settings.api_prefix}/auth/demo"


def _unique_phone() -> str:
    return f"+9199{uuid.uuid4().int % 10**8:08d}"


def test_route_is_not_mounted_when_demo_mode_is_off(monkeypatch: pytest.MonkeyPatch) -> None:
    """DEMO_MODE unset (default False): the route does not exist on the app
    at all -- a normal framework 404, not a 403 from a reachable handler."""
    monkeypatch.setattr(config.settings, "demo_mode", False)

    from app.main import create_app

    client = TestClient(create_app())
    res = client.post(DEMO_PATH)

    assert res.status_code == 404
    assert res.json()["error"]["code"] == "NOT_FOUND"


def test_route_refuses_a_production_app_env_even_with_demo_mode_on(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    """Mounted (demo_mode=True), but app_env=production still refuses. Proves
    app_env is doing real gating work now, not sitting dead inside a negation
    demo_mode alone already satisfies."""
    monkeypatch.setattr(config.settings, "demo_mode", True)
    monkeypatch.setattr(config.settings, "app_env", "production")

    from app.main import create_app

    client = TestClient(create_app())
    res = client.post(DEMO_PATH)

    assert res.status_code == 403
    assert res.json()["error"]["code"] == "FORBIDDEN"


async def test_mints_tokens_for_the_seeded_demo_farmer(
    db_session, monkeypatch: pytest.MonkeyPatch
) -> None:
    """demo_mode on, app_env non-production, farmer present: real tokens for
    that farmer, nothing created."""
    phone = _unique_phone()
    monkeypatch.setattr(auth_router, "DEMO_FARMER_PHONE", phone)
    monkeypatch.setattr(config.settings, "demo_mode", True)
    monkeypatch.setattr(config.settings, "app_env", "local")

    user = User(role=Role.FARMER, phone=phone, name="probe demo farmer")
    db_session.add(user)
    await db_session.flush()

    result = await auth_router.demo_login(session=db_session)

    assert result.user.phone == phone
    assert result.user.role == Role.FARMER
    assert result.access_token and result.refresh_token


async def test_clear_error_when_the_seed_row_is_absent(
    db_session, monkeypatch: pytest.MonkeyPatch
) -> None:
    """demo_mode on, app_env non-production, farmer absent: a clear NOT_FOUND
    telling the caller to run the seed -- not a row created on the fly. That
    unauthenticated write path was the other half of the original bug."""
    monkeypatch.setattr(auth_router, "DEMO_FARMER_PHONE", _unique_phone())
    monkeypatch.setattr(config.settings, "demo_mode", True)
    monkeypatch.setattr(config.settings, "app_env", "local")

    with pytest.raises(NotFound) as exc_info:
        await auth_router.demo_login(session=db_session)

    assert "seed" in str(exc_info.value.message).lower()
