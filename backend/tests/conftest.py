"""Shared fixtures.

Phase 0 tests are deliberately DB-free: they exercise contracts, config
invariants, the error envelope and the vision stub. Database-backed fixtures
arrive in Phase 1 with the ORM.
"""

from __future__ import annotations

import pytest
from fastapi.testclient import TestClient

from app.main import create_app


@pytest.fixture(scope="session")
def client() -> TestClient:
    return TestClient(create_app())


@pytest.fixture
async def db_session():
    """A session whose writes are always rolled back.

    Runs against whatever DATABASE_URL points at — on techpark-9 that is the
    Supabase instance, per CLAUDE.md. Every test body runs inside an outer
    transaction rolled back on teardown, and the session joins it as a
    savepoint, so a test may commit without leaking rows into shared data.

    A fresh engine per test, with NullPool. pytest-asyncio gives each test its
    own event loop, and asyncpg connections are bound to the loop that opened
    them — a module-level pooled engine hands the second test a connection from
    a dead loop, which surfaces as a connection error and (because of the skip
    below) silently skips half the suite rather than failing it.

    Skips rather than fails when no database is reachable: a teammate running
    pytest with no .env should see the DB-free suite pass, not a wall of
    connection errors hiding a real failure.
    """
    from sqlalchemy import NullPool
    from sqlalchemy.ext.asyncio import AsyncSession, create_async_engine

    from app.config import settings

    engine = create_async_engine(settings.database_url, poolclass=NullPool)
    try:
        connection = await engine.connect()
    except Exception as exc:  # noqa: BLE001 - any driver/network failure means skip
        await engine.dispose()
        pytest.skip(f"no database reachable: {type(exc).__name__}: {exc}")

    transaction = await connection.begin()
    session = AsyncSession(
        bind=connection, expire_on_commit=False, join_transaction_mode="create_savepoint"
    )
    try:
        yield session
    finally:
        await session.close()
        await transaction.rollback()
        await connection.close()
        await engine.dispose()
