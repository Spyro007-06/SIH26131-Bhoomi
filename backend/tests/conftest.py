"""Shared fixtures.

Phase 0 tests are deliberately DB-free: they exercise contracts, config
invariants, the error envelope and the vision stub. Database-backed fixtures
arrive in Phase 1 with the ORM.
"""

from __future__ import annotations

import asyncio

import pytest
from fastapi.testclient import TestClient

from app.main import create_app


@pytest.fixture(scope="session")
def client() -> TestClient:
    return TestClient(create_app())


# Stopgap for docs/POOLER_LATENCY.md: the Supabase project is in ap-northeast-1
# (Tokyo), ~130ms RTT from where this team develops, and every DB-touching
# test opens a fresh physical connection (NullPool, by design -- see below).
# At that churn rate and that latency, connection acquisition occasionally
# gets dropped mid-handshake by the network path or the pooler. NOT a pooling
# bug: reproduced twice with fresh, never-reused connections. Remove these
# constants and the retry loop they drive once the project moves to ap-south-1.
_ACQUISITION_RETRY_ATTEMPTS = 3
_ACQUISITION_RETRY_BACKOFF_SECONDS = 0.5
# A dropped connection raises promptly. A connection that goes half-open
# (accepted at the TCP level, never answers) does not raise at all -- it
# hangs. asyncpg/SQLAlchemy have no default query timeout, so without this
# bound a single half-open connection stalls the whole suite indefinitely
# rather than retrying. 15s is generous against a ~130ms-RTT handshake.
_ACQUISITION_TIMEOUT_SECONDS = 15


@pytest.fixture
async def db_session():
    """A session whose writes are always rolled back.

    Runs against TEST_DATABASE_URL -- a database separate from DATABASE_URL,
    so a live-verification curl and the pytest suite cannot collide on the
    same seed rows (LabelPrior, the demo Problem/Diagnosis case,
    registered_use). Falls back to DATABASE_URL when TEST_DATABASE_URL is
    unset, so nobody's local setup breaks silently -- see README's "Test
    database" section. Logged at "bhoomi.tests" level INFO on first use per
    test (host + database name only, never credentials) so a run's actual
    target is provable rather than assumed.

    Every test body runs inside an outer transaction rolled back on
    teardown, and the session joins it as a savepoint, so a test may commit
    without leaking rows into shared data.

    A fresh engine per test, with NullPool. pytest-asyncio gives each test its
    own event loop, and asyncpg connections are bound to the loop that opened
    them — a module-level pooled engine hands the second test a connection from
    a dead loop, which surfaces as a connection error and (because of the skip
    below) silently skips half the suite rather than failing it.

    Skips rather than fails when no database is reachable: a teammate running
    pytest with no .env should see the DB-free suite pass, not a wall of
    connection errors hiding a real failure.

    Acquisition (connect + open the outer transaction) retries up to
    _ACQUISITION_RETRY_ATTEMPTS times on a dropped connection -- see
    docs/POOLER_LATENCY.md. Deliberately scoped to that narrow window, not to
    the session's first query: an earlier version of this stopgap also forced
    the session's lazy SAVEPOINT to exist before yielding (an extra
    round-trip on every single test, to close the exact failure this fixture
    once hit on a SAVEPOINT statement) and cost real time across the whole
    suite to guard a failure that hits a small fraction of tests -- reverted
    in favour of the cheaper, narrower scope actually asked for. A SAVEPOINT
    failure on a test's first query is not retried here; it fails as it did
    before this stopgap existed. This fixture is the only thing the retry
    touches -- app/db.py and production request handling are untouched,
    since retrying there would mask a real outage behind added latency
    instead of surfacing the 503 it should.
    """
    import logging

    from asyncpg.exceptions import ConnectionDoesNotExistError
    from sqlalchemy import NullPool, make_url
    from sqlalchemy.exc import DBAPIError
    from sqlalchemy.ext.asyncio import AsyncSession, create_async_engine

    from app.config import settings

    target_url = settings.test_database_url or settings.database_url
    _parsed = make_url(target_url)
    logging.getLogger("bhoomi.tests").info(
        "db_session -> %s%s/%s (TEST_DATABASE_URL %s)",
        _parsed.host or "",
        f":{_parsed.port}" if _parsed.port else "",
        _parsed.database or "",
        "set" if settings.test_database_url else "unset, falling back to DATABASE_URL",
    )

    def _is_dropped_connection(exc: BaseException) -> bool:
        if isinstance(exc, TimeoutError):
            return True
        return isinstance(exc, DBAPIError) and isinstance(
            exc.orig, ConnectionResetError | ConnectionDoesNotExistError
        )

    # Appended to as each step of _acquire() completes, so the except block
    # below can still find (and close) whatever got created even when
    # asyncio.wait_for cancels _acquire() mid-step on a timeout -- a plain
    # local return value would be lost with the cancelled frame.
    _progress: list[object] = []

    async def _acquire() -> AsyncSession:
        connection = await engine.connect()
        _progress.append(connection)
        transaction = await connection.begin()
        _progress.append(transaction)
        session = AsyncSession(
            bind=connection, expire_on_commit=False, join_transaction_mode="create_savepoint"
        )
        _progress.append(session)
        return session

    engine = create_async_engine(target_url, poolclass=NullPool)

    connection = transaction = session = None
    for attempt in range(1, _ACQUISITION_RETRY_ATTEMPTS + 1):
        _progress.clear()
        try:
            await asyncio.wait_for(_acquire(), timeout=_ACQUISITION_TIMEOUT_SECONDS)
            connection, transaction, session = _progress
            break
        except Exception as exc:  # noqa: BLE001 - inspected immediately below
            connection = _progress[0] if len(_progress) > 0 else None
            transaction = _progress[1] if len(_progress) > 1 else None
            session = _progress[2] if len(_progress) > 2 else None
            if session is not None:
                await session.close()
            if transaction is not None:
                await transaction.rollback()
            if connection is not None:
                await connection.close()
            connection = transaction = session = None

            if _is_dropped_connection(exc) and attempt < _ACQUISITION_RETRY_ATTEMPTS:
                await asyncio.sleep(_ACQUISITION_RETRY_BACKOFF_SECONDS * attempt)
                continue

            await engine.dispose()
            if _is_dropped_connection(exc):
                # Retries exhausted on a connection that WAS reachable (or
                # hung past the timeout) -- a real, worth-seeing failure, not
                # "no database configured." Fails loud rather than skipping.
                raise
            pytest.skip(f"no database reachable: {type(exc).__name__}: {exc}")

    try:
        yield session
    finally:
        await session.close()
        await transaction.rollback()
        await connection.close()
        await engine.dispose()
