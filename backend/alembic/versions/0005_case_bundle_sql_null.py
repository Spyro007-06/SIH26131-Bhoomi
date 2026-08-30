"""normalise case.bundle JSON-null to SQL NULL

Case.bundle is nullable JSONB and is left unset until F12 compiles it.
SQLAlchemy's JSON types default to none_as_null=False, so Python None was being
stored as JSONB `null` — the JSON value — rather than SQL NULL. The column then
reads as NOT NULL and `bundle IS NULL` is false for every uncompiled case.

The model now sets none_as_null=True. This migration fixes rows already written
the old way. No DDL: the column type and nullability are unchanged.

Revision ID: 0005_case_bundle_sql_null
Revises: 0004_alert_daily_unique
Create Date: 2026-08-30
"""

from __future__ import annotations

from collections.abc import Sequence

from alembic import op

revision: str = "0005_case_bundle_sql_null"
down_revision: str | None = "0004_alert_daily_unique"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.execute("UPDATE \"case\" SET bundle = NULL WHERE bundle = 'null'::jsonb")


def downgrade() -> None:
    # Deliberately not reversed. Turning SQL NULL back into JSON null would
    # re-introduce the bug this migration exists to fix, and nothing depends on
    # the old representation.
    pass
