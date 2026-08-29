"""Enable postgis and pgvector.

The tables are empty on purpose — Phase 0. The extensions are not: contract C2
requires geography(Point, 4326) on farm, and the corpus requires vector(1024),
so both must be real before any Phase 1 migration can reference those types.

scripts/postgres-init/01-extensions.sql also creates them, but that script runs
only on a fresh data volume. This migration is what guarantees them on a database
that already existed.

Revision ID: 0001_extensions
Revises:
Create Date: 2026-08-29
"""

from __future__ import annotations

from collections.abc import Sequence

from alembic import op

revision: str = "0001_extensions"
down_revision: str | None = None
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.execute("CREATE EXTENSION IF NOT EXISTS postgis")
    op.execute("CREATE EXTENSION IF NOT EXISTS vector")


def downgrade() -> None:
    # Deliberately not dropped. Dropping postgis cascades away every geometry
    # column in the database, which is not something a downgrade should do by
    # surprise. Drop the volume instead if you want a clean slate.
    pass
