"""HTTP surface for /voice/transcribe and /voice/synthesize. docs/API_CONTRACT.md §4.

No network, no DB — the router calls straight through to the S0 stub-backed
transcribe()/synthesize().

This router is not yet mounted on the shared app in app/main.py (that one-line
mount is Shreekumar's to add — see the PR notes). These tests build a small,
isolated app that mounts only app.voice.router under the real settings.api_prefix,
with the same exception handlers main.py registers, so the tests exercise real
HTTP behaviour without depending on, or making, that mount edit.
"""

from __future__ import annotations

import uuid

import jwt
import pytest
from fastapi import FastAPI
from fastapi.testclient import TestClient

from app.config import settings
from app.contracts.enums import Role
from app.errors import register_exception_handlers
from app.voice.router import router as voice_router

TRANSCRIBE_BODY = {"asset_id": str(uuid.uuid4()), "lang": "mr-IN", "context": "query"}
SYNTHESIZE_BODY = {"text": "hello", "lang": "mr-IN"}


@pytest.fixture(scope="module")
def voice_client() -> TestClient:
    app = FastAPI()
    register_exception_handlers(app)
    app.include_router(voice_router, prefix=settings.api_prefix)
    return TestClient(app)


def _bearer_token(role: Role = Role.FARMER) -> str:
    claims = {"sub": str(uuid.uuid4()), "role": role.value}
    return jwt.encode(claims, settings.jwt_secret, algorithm=settings.jwt_algorithm)


def _auth_headers(role: Role = Role.FARMER) -> dict[str, str]:
    return {"Authorization": f"Bearer {_bearer_token(role)}"}


def test_transcribe_requires_auth(voice_client: TestClient) -> None:
    res = voice_client.post(f"{settings.api_prefix}/voice/transcribe", json=TRANSCRIBE_BODY)
    assert res.status_code == 401


def test_synthesize_requires_auth(voice_client: TestClient) -> None:
    res = voice_client.post(f"{settings.api_prefix}/voice/synthesize", json=SYNTHESIZE_BODY)
    assert res.status_code == 401


def test_transcribe_below_floor_omits_parsed_intent_key(voice_client: TestClient) -> None:
    res = voice_client.post(
        f"{settings.api_prefix}/voice/transcribe",
        json=TRANSCRIBE_BODY,
        headers=_auth_headers(),
    )
    assert res.status_code == 200

    body = res.json()
    assert "parsed_intent" not in body
    assert body["needs_confirmation"] is False
    assert body["lang"] == "mr-IN"
    assert body["is_stub"] is True
    assert isinstance(body["text"], str)
    assert isinstance(body["confidence"], float)


def test_synthesize_returns_audio_url_and_expiry(voice_client: TestClient) -> None:
    res = voice_client.post(
        f"{settings.api_prefix}/voice/synthesize",
        json=SYNTHESIZE_BODY,
        headers=_auth_headers(),
    )
    assert res.status_code == 200

    body = res.json()
    assert set(body) == {"audio_url", "expires_in", "is_stub"}
    assert body["expires_in"] == settings.presign_expiry_seconds
    assert body["is_stub"] is True


@pytest.mark.parametrize("bad_context", ["not_a_real_context", ""])
def test_transcribe_rejects_invalid_context(voice_client: TestClient, bad_context: str) -> None:
    body = {**TRANSCRIBE_BODY, "context": bad_context}
    res = voice_client.post(
        f"{settings.api_prefix}/voice/transcribe", json=body, headers=_auth_headers()
    )
    assert res.status_code == 422


def test_transcribe_rejects_null_context(voice_client: TestClient) -> None:
    body = {**TRANSCRIBE_BODY, "context": None}
    res = voice_client.post(
        f"{settings.api_prefix}/voice/transcribe", json=body, headers=_auth_headers()
    )
    assert res.status_code == 422


def test_transcribe_rejects_missing_context(voice_client: TestClient) -> None:
    body = {k: v for k, v in TRANSCRIBE_BODY.items() if k != "context"}
    res = voice_client.post(
        f"{settings.api_prefix}/voice/transcribe", json=body, headers=_auth_headers()
    )
    assert res.status_code == 422


def test_transcribe_rejects_invalid_lang(voice_client: TestClient) -> None:
    body = {**TRANSCRIBE_BODY, "lang": "xx-XX"}
    res = voice_client.post(
        f"{settings.api_prefix}/voice/transcribe", json=body, headers=_auth_headers()
    )
    assert res.status_code == 422
