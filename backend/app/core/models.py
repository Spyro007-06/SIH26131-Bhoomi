"""ORM models — the twelve tables of docs/DESIGN.md §5.

OWNER: Shreekumar.

PHASE 1, not Phase 0. Deliberately empty: the contracts in app/contracts/ are
reviewed and frozen before the schema hardens around them.

When this is filled, two constraints go in the Alembic migration as Postgres
CHECKs rather than Python validators (docs/DESIGN.md §5):

  - Alert.inspection_tasks must be a non-empty JSON array. An alert without a
    task is noise, and enforcing it in Python means someone bypasses it at
    hour 25.
  - Advisory.ladder must have chemical last when a chemical rung is present. The
    PRD's structural claim about pesticide ordering is only true if the database
    refuses to store it otherwise.

Farm.location is geography(Point, 4326) NOT NULL — contract C2.
"""

from __future__ import annotations

from app.db import Base

__all__ = ["Base"]
