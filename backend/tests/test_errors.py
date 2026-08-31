"""The error envelope and the stable code enum. docs/API_CONTRACT.md §0."""

from __future__ import annotations

import pytest

from app.errors import DEFAULT_STATUS, BhoomiError, ErrorCode, envelope

CONTRACT_CODES = {
    "UNAUTHENTICATED",
    "FORBIDDEN",
    "NOT_FOUND",
    "VALIDATION_FAILED",
    "BELOW_CONFIDENCE_GATE",
    "AMBIGUOUS_REQUIRES_CLARIFICATION",
    "OUT_OF_SCOPE_TARGET",
    "NO_RELEVANT_SOURCE",
    "OCR_UNREADABLE",
    "PRODUCT_NOT_IN_RECORDS",
    "AGRONOMIST_UNAVAILABLE",
    "VOICE_PROVIDER_UNAVAILABLE",
    "FIXTURES_DISABLED",
}


def test_enum_matches_the_contract_exactly() -> None:
    """Adding a code is a deliberate act. If this fails, either the contract
    moved or someone added a code without a team decision."""
    assert {c.value for c in ErrorCode} == CONTRACT_CODES


@pytest.mark.parametrize("code", list(ErrorCode))
def test_every_stable_code_is_reachable_and_renders(code: ErrorCode) -> None:
    """Every code can be raised and produces the section 0 envelope."""
    err = BhoomiError(code, "message text", {"k": "v"})
    body = envelope(err.code, err.message, err.details)

    assert set(body) == {"error"}
    assert body["error"]["code"] == code.value
    assert body["error"]["message"] == "message text"
    assert body["error"]["details"] == {"k": "v"}
    assert err.status_code == DEFAULT_STATUS[code]


def test_details_is_omitted_when_absent() -> None:
    body = envelope(ErrorCode.NOT_FOUND, "Not found.")
    assert "details" not in body["error"]


def test_validation_failed_is_always_422() -> None:
    """One code, one status.

    VALIDATION_FAILED used to come back 400 from the vision fixture endpoint and
    422 everywhere else. A client that switches on `code` then cannot predict
    the status, which is most of what a stable envelope buys. ValidationFailed
    now discards any status_code passed to it rather than trusting call sites to
    stop passing one.
    """
    assert DEFAULT_STATUS[ErrorCode.VALIDATION_FAILED] == 422
    from app.errors import ValidationFailed

    assert ValidationFailed("x").status_code == 422
    assert ValidationFailed("x", status_code=400).status_code == 422


def test_fixtures_disabled_is_a_configuration_state_not_an_authz_failure() -> None:
    """409, not 403. The caller's identity has no bearing on it."""
    from app.errors import FixturesDisabled

    error = FixturesDisabled()
    assert error.code is ErrorCode.FIXTURES_DISABLED
    assert error.status_code == 409
    assert error.status_code != DEFAULT_STATUS[ErrorCode.FORBIDDEN]


def test_every_code_has_a_default_status() -> None:
    assert set(DEFAULT_STATUS) == set(ErrorCode)


def test_unrouted_path_still_carries_the_envelope(client) -> None:
    """A framework-generated 404 must not escape with FastAPI's own detail
    shape. One envelope for every error response, section 0."""
    res = client.get("/api/v1/does-not-exist")
    assert res.status_code == 404
    assert res.json()["error"]["code"] == "NOT_FOUND"
