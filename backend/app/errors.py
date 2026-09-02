"""The one error envelope and the stable error codes. docs/API_CONTRACT.md §0.

Owner: Shreekumar.

RULE: no endpoint hand-rolls an error body. Raise `BhoomiError` (or a subclass)
and the handler registered in app/main.py renders the envelope. Adding a code to
`ErrorCode` is a deliberate act — the list is stable and clients switch on it.

    {
      "error": {
        "code": "NO_RELEVANT_SOURCE",
        "message": "No trusted source covers this. Sending to an expert.",
        "details": { "best_relevance": 0.31, "threshold": 0.60 }
      }
    }
"""

from __future__ import annotations

import logging
from typing import Any

from fastapi import FastAPI, Request, status
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse
from pydantic import BaseModel
from starlette.exceptions import HTTPException as StarletteHTTPException

from app.contracts.enums import StrEnum


class ErrorCode(StrEnum):
    """The stable codes from docs/API_CONTRACT.md §0. Do not add casually."""

    UNAUTHENTICATED = "UNAUTHENTICATED"
    FORBIDDEN = "FORBIDDEN"
    NOT_FOUND = "NOT_FOUND"
    VALIDATION_FAILED = "VALIDATION_FAILED"
    BELOW_CONFIDENCE_GATE = "BELOW_CONFIDENCE_GATE"
    AMBIGUOUS_REQUIRES_CLARIFICATION = "AMBIGUOUS_REQUIRES_CLARIFICATION"
    OUT_OF_SCOPE_TARGET = "OUT_OF_SCOPE_TARGET"
    NO_RELEVANT_SOURCE = "NO_RELEVANT_SOURCE"
    OCR_UNREADABLE = "OCR_UNREADABLE"
    PRODUCT_NOT_IN_RECORDS = "PRODUCT_NOT_IN_RECORDS"
    AGRONOMIST_UNAVAILABLE = "AGRONOMIST_UNAVAILABLE"
    VOICE_PROVIDER_UNAVAILABLE = "VOICE_PROVIDER_UNAVAILABLE"
    """Added S3 (voice/providers.py): a Sarvam HTTP call failed (non-200 or a
    transport error). Distinct from AGRONOMIST_UNAVAILABLE, which carries a
    specific escalation meaning clients may branch on — this is an unrelated
    upstream-provider failure. docs/API_CONTRACT.md §0's stable-codes list
    needs the same addition; flagged for whoever owns that doc edit."""
    FIXTURES_DISABLED = "FIXTURES_DISABLED"
    """The server is configured so that test fixtures are not served.

    Added in v3. The vision fixture endpoint was raising FORBIDDEN for this,
    which says "your credentials do not permit this" — but the caller's identity
    is irrelevant: with VISION_MODEL=real nobody may pull a fixture, and with
    VISION_MODEL=stub everybody may. It is a server configuration state, so it
    gets a code that says so and a 409 rather than a 403."""
    NOT_IMPLEMENTED = "NOT_IMPLEMENTED"
    """Added wiring POST /farms/{id}/diagnose: the gate genuinely reached a
    branch (advise; or clarify with a matching DistinguishingCue found) whose
    response this build does not compose. Both are real, reachable states, not
    bugs — the composer (F7) and the Doubt Doctor question flow (F4) are
    Thaariha's and are not built here. Distinct from FIXTURES_DISABLED (a
    server configuration state) and from every gate reason code: those are
    conditions the GATE decided, delivered as a normal 200 docs/API_CONTRACT.md
    §6 response; this is the API declining to build a response it cannot yet
    compose honestly. 501, not 200 — this is not a designed outcome to render,
    it is missing software."""
    METHOD_NOT_ALLOWED = "METHOD_NOT_ALLOWED"
    """A route exists but was called with the wrong HTTP verb. Only ever seen
    during integration — a client calling GET on a POST-only route, say — so it
    is a developer-facing "you called this wrong" signal, not a farmer-facing
    one. Distinct from NOT_FOUND: the path is real."""
    INTERNAL_ERROR = "INTERNAL_ERROR"
    """The server failed in a way the caller did not cause and the API did not
    anticipate: an unhandled exception, or an HTTP status this app has no
    mapping for. Added because both of the handlers below used to answer these
    with VALIDATION_FAILED, which tells a client "fix your request" for a
    failure that has nothing to do with the request — a farmer's client reads
    that as an instruction to correct input that was never wrong, and does not
    retry. See the commit that added this code for the incident."""


# Every code's HTTP status is exactly DEFAULT_STATUS[code]. There is no
# per-raise override — BhoomiError does not accept a status_code argument, so a
# mismatch between what a handler believes it is sending and what DEFAULT_STATUS
# says the code means is unrepresentable, not just untested. See
# envelope_response() below, the only function allowed to build the JSONResponse
# a handler returns.
DEFAULT_STATUS: dict[ErrorCode, int] = {
    ErrorCode.UNAUTHENTICATED: status.HTTP_401_UNAUTHORIZED,
    ErrorCode.FORBIDDEN: status.HTTP_403_FORBIDDEN,
    ErrorCode.NOT_FOUND: status.HTTP_404_NOT_FOUND,
    ErrorCode.VALIDATION_FAILED: status.HTTP_422_UNPROCESSABLE_ENTITY,
    ErrorCode.BELOW_CONFIDENCE_GATE: status.HTTP_200_OK,
    ErrorCode.AMBIGUOUS_REQUIRES_CLARIFICATION: status.HTTP_200_OK,
    ErrorCode.OUT_OF_SCOPE_TARGET: status.HTTP_200_OK,
    ErrorCode.NO_RELEVANT_SOURCE: status.HTTP_200_OK,
    ErrorCode.OCR_UNREADABLE: status.HTTP_200_OK,
    ErrorCode.PRODUCT_NOT_IN_RECORDS: status.HTTP_200_OK,
    ErrorCode.AGRONOMIST_UNAVAILABLE: status.HTTP_503_SERVICE_UNAVAILABLE,
    ErrorCode.VOICE_PROVIDER_UNAVAILABLE: status.HTTP_503_SERVICE_UNAVAILABLE,
    # 409: the request conflicts with the server's current configuration, and
    # will keep conflicting until that configuration changes. Not 403 (identity
    # is irrelevant) and not 400 (the request is well formed).
    ErrorCode.FIXTURES_DISABLED: status.HTTP_409_CONFLICT,
    ErrorCode.NOT_IMPLEMENTED: status.HTTP_501_NOT_IMPLEMENTED,
    ErrorCode.METHOD_NOT_ALLOWED: status.HTTP_405_METHOD_NOT_ALLOWED,
    ErrorCode.INTERNAL_ERROR: status.HTTP_500_INTERNAL_SERVER_ERROR,
}
# The gate outcomes default to 200 deliberately. "I am not confident, here is an
# expert" is a successful, designed response — not an HTTP failure. They appear
# in this enum because clients switch on the code, not because they are faults.


class BhoomiError(Exception):
    """Every error the API returns deliberately. Rendered by the handler below.

    No status_code parameter: self.status_code is always DEFAULT_STATUS[code].
    A prior version accepted an override, but nothing in the codebase ever
    passed one (grepped every raise site before removing it), and the one
    subclass that thought about the question, ValidationFailed, already
    discarded it. The capability was dead; removing it makes "one code, one
    status" true by construction instead of by nobody happening to break it.
    """

    def __init__(
        self,
        code: ErrorCode,
        message: str,
        details: dict[str, Any] | None = None,
    ) -> None:
        self.code = code
        self.message = message
        self.details = details
        self.status_code = DEFAULT_STATUS[code]
        super().__init__(f"{code}: {message}")


def envelope(
    code: ErrorCode, message: str, details: dict[str, Any] | None = None
) -> dict[str, Any]:
    """Build the §0 envelope body. The single place this shape is constructed."""
    body: dict[str, Any] = {"code": str(code), "message": message}
    if details is not None:
        body["details"] = details
    return {"error": body}


def envelope_response(
    code: ErrorCode, message: str, details: dict[str, Any] | None = None
) -> JSONResponse:
    """The only way any handler below builds an error JSONResponse.

    Status is always DEFAULT_STATUS[code] — there is no parameter to pass a
    different one. Two handlers used to hand-build a JSONResponse with a status
    they picked themselves, and both picked wrong (a 500 and a 405 both landed
    as VALIDATION_FAILED/422). Routing every handler through this one function
    makes that class of mistake unrepresentable rather than a thing each
    handler has to remember not to do.
    """
    return JSONResponse(status_code=DEFAULT_STATUS[code], content=envelope(code, message, details))


# ---------------------------------------------------------------------------
# The envelope as an OpenAPI schema component.
#
# envelope()/register_exception_handlers() below build and render this shape
# by hand, from an exception handler — a real, live wire shape (verified
# against a running server, not assumed from reading the handler: see the
# task's pasted 404/422/501 responses) that FastAPI's automatic schema
# generation has no way to see, because no route declares it. A client
# generated from docs/openapi.json before this model existed believed every
# route returned either its 2xx model or FastAPI's default 422 — every other
# error this API actually sends was invisible to it.
#
# ErrorDetail.code is typed ErrorCode, not str, specifically so the OpenAPI
# schema carries the full enum: a generated client can switch on `code`
# rather than string-match it.
# ---------------------------------------------------------------------------


class ErrorDetail(BaseModel):
    code: ErrorCode
    message: str
    details: dict[str, Any] | None = None


class ErrorEnvelope(BaseModel):
    """docs/API_CONTRACT.md §0. The body of every error response, no
    exceptions — including FastAPI's own framework-generated ones (404 on an
    unrouted path, 422 on a request body pydantic cannot parse), which the
    handlers below also render into this same shape rather than letting
    Starlette's default plain-text/JSON-detail bodies escape."""

    error: ErrorDetail


def error_response(status_code: int, description: str) -> dict[int, dict[str, Any]]:
    """One `responses=` entry for a route: ErrorEnvelope at `status_code`,
    with a description of the specific, route-true reason that route can
    return it — not a generic restatement of what the status code means.

    Usage: `responses={**error_response(401, "..."), **error_response(404, "...")}`.
    """
    return {status_code: {"model": ErrorEnvelope, "description": description}}


class Unauthenticated(BhoomiError):
    def __init__(self, message: str = "Sign in to continue.", **kw: Any) -> None:
        super().__init__(ErrorCode.UNAUTHENTICATED, message, **kw)


class Forbidden(BhoomiError):
    def __init__(self, message: str = "Your role cannot do this.", **kw: Any) -> None:
        super().__init__(ErrorCode.FORBIDDEN, message, **kw)


class NotFound(BhoomiError):
    def __init__(self, message: str = "Not found.", **kw: Any) -> None:
        super().__init__(ErrorCode.NOT_FOUND, message, **kw)


class ValidationFailed(BhoomiError):
    """One code, one status.

    This used to be raised with an explicit status_code=400 at one call site and
    at its 422 default everywhere else. A client switching on `code` could not
    then predict the status, which is most of what a stable envelope is for.
    422 is the default and no caller can override it — BhoomiError itself has
    no status_code parameter to pass. See
    tests/test_errors.py::test_validation_failed_is_always_422.
    """

    def __init__(self, message: str = "Request could not be validated.", **kw: Any) -> None:
        super().__init__(ErrorCode.VALIDATION_FAILED, message, **kw)


class FixturesDisabled(BhoomiError):
    def __init__(
        self, message: str = "Test fixtures are not served in this configuration.", **kw: Any
    ) -> None:
        super().__init__(ErrorCode.FIXTURES_DISABLED, message, **kw)


def register_exception_handlers(app: FastAPI) -> None:
    """Wire the envelope in once, so no endpoint has to know its shape."""

    @app.exception_handler(BhoomiError)
    async def _bhoomi(_: Request, exc: BhoomiError) -> JSONResponse:
        return envelope_response(exc.code, exc.message, exc.details)

    @app.exception_handler(RequestValidationError)
    async def _validation(_: Request, exc: RequestValidationError) -> JSONResponse:
        return envelope_response(
            ErrorCode.VALIDATION_FAILED,
            "Request could not be validated.",
            {"errors": exc.errors()},
        )

    @app.exception_handler(Exception)
    async def _unhandled(_: Request, exc: Exception) -> JSONResponse:
        """Last resort, so an unexpected failure still speaks the envelope.

        Without this, Starlette answers with plain-text "Internal Server Error"
        and a client that parses every response as the §0 shape gets a decode
        error instead of a code it can branch on. The traceback is logged in
        full; the body deliberately carries no detail, since an exception
        message can contain a connection string or a row.

        INTERNAL_ERROR, not VALIDATION_FAILED: a client switching on `code`
        reads VALIDATION_FAILED as "fix your request." A server crash is not
        the caller's fault and retrying may well succeed — telling a farmer's
        client to stop and correct input that was never wrong is the bug this
        code exists to close.
        """
        logging.getLogger("bhoomi.errors").exception("unhandled error: %s", exc)
        return envelope_response(ErrorCode.INTERNAL_ERROR, "Something went wrong on our side.")

    @app.exception_handler(StarletteHTTPException)
    async def _http(_: Request, exc: StarletteHTTPException) -> JSONResponse:
        """Catches 404s from unrouted paths and anything raising HTTPException,
        so even framework-generated errors carry the envelope.

        405 gets its own code rather than folding into the residual bucket:
        it is Starlette's own automatic answer when a real route is called
        with the wrong verb, seen only during integration, by a developer who
        needs to know the verb was wrong — not that their request body failed
        validation, which is a different bug pointed at the wrong person.

        Anything else landing here is a status this app never anticipated —
        a genuine gap, not a request problem — so it is INTERNAL_ERROR at 500,
        logged loudly rather than silently relabelled as something ordinary.
        """
        code = {
            status.HTTP_401_UNAUTHORIZED: ErrorCode.UNAUTHENTICATED,
            status.HTTP_403_FORBIDDEN: ErrorCode.FORBIDDEN,
            status.HTTP_404_NOT_FOUND: ErrorCode.NOT_FOUND,
            status.HTTP_405_METHOD_NOT_ALLOWED: ErrorCode.METHOD_NOT_ALLOWED,
        }.get(exc.status_code)
        if code is None:
            logging.getLogger("bhoomi.errors").error(
                "StarletteHTTPException with an unanticipated status %s: %s",
                exc.status_code,
                exc.detail,
            )
            code = ErrorCode.INTERNAL_ERROR
        return envelope_response(code, str(exc.detail))
