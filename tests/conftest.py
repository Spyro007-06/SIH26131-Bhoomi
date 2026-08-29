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
