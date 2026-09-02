"""The error envelope and the stable code enum. docs/API_CONTRACT.md §0."""

from __future__ import annotations

import pytest
from fastapi import FastAPI
from fastapi.testclient import TestClient
from starlette.exceptions import HTTPException as StarletteHTTPException

from app.errors import (
    DEFAULT_STATUS,
    BhoomiError,
    ErrorCode,
    envelope,
    envelope_response,
    register_exception_handlers,
)

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
    "NOT_IMPLEMENTED",
    "METHOD_NOT_ALLOWED",
    "INTERNAL_ERROR",
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
    the status, which is most of what a stable envelope buys.

    This no longer relies on ValidationFailed discarding a status_code someone
    passed it -- BhoomiError has no status_code parameter at all, so passing one
    is a TypeError, not a silently-ignored override. See
    test_bhoomi_error_status_code_cannot_be_overridden below for the general
    form of that guarantee, and test_every_error_code_status_is_derived_by_construction
    for the property this docstring actually claims: one code, one status, for
    every code the app can emit, not just this one.
    """
    assert DEFAULT_STATUS[ErrorCode.VALIDATION_FAILED] == 422
    from app.errors import ValidationFailed

    assert ValidationFailed("x").status_code == 422


def test_bhoomi_error_status_code_cannot_be_overridden() -> None:
    """The bug this whole task fixed was two handlers picking their own status
    instead of trusting the code. The prior fix for VALIDATION_FAILED alone was
    ValidationFailed discarding a status_code kwarg -- a convention one
    subclass remembered. This asserts the stronger claim: the parameter does
    not exist on the base class, so no subclass, present or future, can accept
    one by forgetting to pop it.
    """
    with pytest.raises(TypeError):
        BhoomiError(ErrorCode.NOT_FOUND, "x", status_code=400)  # type: ignore[call-arg]


def test_every_error_code_status_is_derived_by_construction() -> None:
    """Structural, over the whole enum: BhoomiError.status_code and
    envelope_response()'s status are DEFAULT_STATUS[code], always, for every
    code -- not asserted case by case per handler. Every one of the four
    handlers in register_exception_handlers is required to build its response
    through envelope_response(); this is what makes that requirement pay off:
    no handler can construct a JSONResponse whose status disagrees with its
    code, because there is only one function that builds one, and this is its
    whole contract.
    """
    for code in ErrorCode:
        assert BhoomiError(code, "message").status_code == DEFAULT_STATUS[code]
        assert envelope_response(code, "message").status_code == DEFAULT_STATUS[code]


# ---------------------------------------------------------------------------
# Live coverage for the two handlers the class-level tests above cannot reach:
# _unhandled (a bare Exception) and _http's fallback (a StarletteHTTPException
# whose status isn't 401/403/404/405). Both used to answer with
# VALIDATION_FAILED/422 or the *original* mismatched status -- a real 500
# would come back labelled as if the caller's request was invalid, and a real
# 405 the same way. This drives both through the real ASGI stack, with the
# real exception handlers, rather than asserting anything about the handler
# functions' source.
#
# An isolated app, not the `client` fixture's real one: TestClient's default
# raise_server_exceptions=True re-raises an exception caught by the
# `Exception` handler back into the test process even though a response was
# already sent, so proving _unhandled's *response* requires
# raise_server_exceptions=False. Same pattern as test_voice_router.py's
# voice_client fixture -- a bare FastAPI() with only
# register_exception_handlers() wired in.
# ---------------------------------------------------------------------------


@pytest.fixture(scope="module")
def crash_client() -> TestClient:
    app = FastAPI()
    register_exception_handlers(app)

    @app.get("/crash")
    async def crash() -> None:
        raise RuntimeError("deliberate, for the test")

    @app.get("/only-get")
    async def only_get() -> dict[str, bool]:
        return {"ok": True}

    @app.get("/teapot")
    async def teapot() -> None:
        raise StarletteHTTPException(status_code=418, detail="short and stout")

    return TestClient(app, raise_server_exceptions=False)


def test_unhandled_exception_is_internal_error_not_validation_failed(
    crash_client: TestClient,
) -> None:
    """The bug, part one: a bare crash used to come back 500/VALIDATION_FAILED
    -- a farmer's client reading that as "fix your input," on a failure that
    was not the farmer's input."""
    res = crash_client.get("/crash")
    body = res.json()

    assert res.status_code == 500
    assert body["error"]["code"] == "INTERNAL_ERROR"
    assert DEFAULT_STATUS[ErrorCode(body["error"]["code"])] == res.status_code


def test_wrong_verb_on_a_real_route_is_method_not_allowed_not_validation_failed(
    crash_client: TestClient,
) -> None:
    """The bug, part two: calling a GET-only route with POST used to come back
    405/VALIDATION_FAILED -- telling the integrating developer their request
    body was invalid when the actual mistake was the HTTP verb."""
    res = crash_client.post("/only-get")
    body = res.json()

    assert res.status_code == 405
    assert body["error"]["code"] == "METHOD_NOT_ALLOWED"
    assert DEFAULT_STATUS[ErrorCode(body["error"]["code"])] == res.status_code


def test_unanticipated_http_status_falls_to_internal_error(crash_client: TestClient) -> None:
    """_http's map only names 401/403/404/405. Anything else reaching it is a
    status this app never designed for -- proven here with 418, chosen only
    because it is certainly not one of the four -- and must come back
    INTERNAL_ERROR/500, loudly logged, not silently relabelled as whichever
    status the exception happened to carry."""
    res = crash_client.get("/teapot")
    body = res.json()

    assert res.status_code == 500
    assert body["error"]["code"] == "INTERNAL_ERROR"


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
