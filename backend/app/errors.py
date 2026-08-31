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
    FIXTURES_DISABLED = "FIXTURES_DISABLED"
    """The server is configured so that test fixtures are not served.

    Added in v3. The vision fixture endpoint was raising FORBIDDEN for this,
    which says "your credentials do not permit this" — but the caller's identity
    is irrelevant: with VISION_MODEL=real nobody may pull a fixture, and with
    VISION_MODEL=stub everybody may. It is a server configuration state, so it
    gets a code that says so and a 409 rather than a 403."""


# Default HTTP status per code. A code may override per-raise, but the default
# keeps status selection out of endpoint bodies.
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
    # 409: the request conflicts with the server's current configuration, and
    # will keep conflicting until that configuration changes. Not 403 (identity
    # is irrelevant) and not 400 (the request is well formed).
    ErrorCode.FIXTURES_DISABLED: status.HTTP_409_CONFLICT,
}
# The gate outcomes default to 200 deliberately. "I am not confident, here is an
# expert" is a successful, designed response — not an HTTP failure. They appear
# in this enum because clients switch on the code, not because they are faults.


class BhoomiError(Exception):
    """Every error the API returns deliberately. Rendered by the handler below."""

    def __init__(
        self,
        code: ErrorCode,
        message: str,
        details: dict[str, Any] | None = None,
        status_code: int | None = None,
    ) -> None:
        self.code = code
        self.message = message
        self.details = details
        self.status_code = status_code or DEFAULT_STATUS[code]
        super().__init__(f"{code}: {message}")


def envelope(
    code: ErrorCode, message: str, details: dict[str, Any] | None = None
) -> dict[str, Any]:
    """Build the §0 envelope. The single place this shape is constructed."""
    body: dict[str, Any] = {"code": str(code), "message": message}
    if details is not None:
        body["details"] = details
    return {"error": body}


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
    422 is the default and callers do not override it — see
    tests/test_errors.py::test_validation_failed_is_always_422.
    """

    def __init__(self, message: str = "Request could not be validated.", **kw: Any) -> None:
        kw.pop("status_code", None)
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
        return JSONResponse(
            status_code=exc.status_code,
            content=envelope(exc.code, exc.message, exc.details),
        )

    @app.exception_handler(RequestValidationError)
    async def _validation(_: Request, exc: RequestValidationError) -> JSONResponse:
        return JSONResponse(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            content=envelope(
                ErrorCode.VALIDATION_FAILED,
                "Request could not be validated.",
                {"errors": exc.errors()},
            ),
        )

    @app.exception_handler(Exception)
    async def _unhandled(_: Request, exc: Exception) -> JSONResponse:
        """Last resort, so an unexpected failure still speaks the envelope.

        Without this, Starlette answers with plain-text "Internal Server Error"
        and a client that parses every response as the §0 shape gets a decode
        error instead of a code it can branch on. The traceback is logged in
        full; the body deliberately carries no detail, since an exception
        message can contain a connection string or a row.
        """
        logging.getLogger("bhoomi.errors").exception("unhandled error: %s", exc)
        return JSONResponse(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            content=envelope(
                ErrorCode.VALIDATION_FAILED,
                "Something went wrong on our side.",
            ),
        )

    @app.exception_handler(StarletteHTTPException)
    async def _http(_: Request, exc: StarletteHTTPException) -> JSONResponse:
        """Catches 404s from unrouted paths and anything raising HTTPException,
        so even framework-generated errors carry the envelope."""
        code = {
            status.HTTP_401_UNAUTHORIZED: ErrorCode.UNAUTHENTICATED,
            status.HTTP_403_FORBIDDEN: ErrorCode.FORBIDDEN,
            status.HTTP_404_NOT_FOUND: ErrorCode.NOT_FOUND,
        }.get(exc.status_code, ErrorCode.VALIDATION_FAILED)
        return JSONResponse(
            status_code=exc.status_code,
            content=envelope(code, str(exc.detail)),
        )
