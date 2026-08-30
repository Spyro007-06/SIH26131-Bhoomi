"""alert daily uniqueness

One alert per farm, per target, per UTC day.

HAND-WRITTEN. Autogenerate produced a unique index on (farm_id, target) alone —
it silently dropped the date expression, which would have blocked every repeat
alert for a farm and target for the rest of the season rather than just a
same-day duplicate. That is a much stronger constraint than intended and would
have looked correct in a migration review.

Two details that matter:

  * `date(issued_at)` cannot be indexed. `issued_at` is timestamptz and
    date(timestamptz) is STABLE, not IMMUTABLE — its result depends on the
    session TimeZone setting, so Postgres refuses it in an index. Fixing the
    zone explicitly with `AT TIME ZONE 'UTC'` makes the expression immutable.

  * This is what makes the risk job idempotent. A SELECT-then-INSERT guard in
    Python would still let two concurrent runs both see "no alert yet" and both
    insert. docs/DESIGN.md §5's reasoning about CHECK constraints applies here
    too: enforcing it in application code means someone bypasses it at hour 25.

Revision ID: 0004_alert_daily_unique
Revises: 0003_farm_sowing_date
Create Date: 2026-08-30
"""

from __future__ import annotations

from collections.abc import Sequence

from alembic import op

revision: str = "0004_alert_daily_unique"
down_revision: str | None = "0003_farm_sowing_date"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.execute(
        "CREATE UNIQUE INDEX uq_alert_farm_target_day "
        "ON alert (farm_id, target, ((issued_at AT TIME ZONE 'UTC')::date))"
    )


def downgrade() -> None:
    op.execute("DROP INDEX IF EXISTS uq_alert_farm_target_day")
