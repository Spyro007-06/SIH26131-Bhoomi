"""registered_use: source_dated, restriction_note, reentry_hours nullable

Three defects found ingesting the paddy CSV, all in the same table:

1. reentry_hours was NOT NULL and the loader required it, so any row whose
   source states a PHI but not a re-entry period was refused outright rather
   than loaded with reentry_hours = NULL. 8 of the CSV's 10 rows are exactly
   this case -- their source is silent on re-entry, not wrong about it. A row
   the source doesn't cover should say so; for_advisory() (Part 4 of this
   phase) is the thing that excludes an incomplete row from a chemical rung,
   and it needs the row to exist in order to exclude it.

2. last_verified conflated two different facts: the date the source document
   was itself dated, and the date someone last checked it. Every CIB&RC
   citation in the CSV reads "as on 30.09.2012," but last_verified reads
   today's date -- a reader takes that as "current in 2026." source_dated
   carries the source's own date; last_verified keeps its existing meaning.
   Both required by the loader.

3. restriction_note: nullable, for an ingredient that is still nationally
   registered but carries a live sub-national or non-CIB&RC restriction (a
   state agriculture department order, for instance) worth surfacing without
   removing the row -- it is not a ban.

Revision ID: 0011_registered_use_dates
Revises: 0010_corpus_document_cue_fk
Create Date: 2026-08-31
"""

from __future__ import annotations

from collections.abc import Sequence

import sqlalchemy as sa

from alembic import op

revision: str = "0011_registered_use_dates"
down_revision: str | None = "0010_corpus_document_cue_fk"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.add_column("registered_use", sa.Column("source_dated", sa.Date(), nullable=True))
    op.add_column("registered_use", sa.Column("restriction_note", sa.Text(), nullable=True))

    connection = op.get_bind()
    # Best-effort backfill for any pre-existing row: the closest fact on hand
    # to "when the source was dated" is "when it was last verified." New rows
    # loaded after this migration carry a real source_dated from the CSV.
    result = connection.execute(
        sa.text(
            "UPDATE registered_use SET source_dated = last_verified "
            "WHERE source_dated IS NULL AND last_verified IS NOT NULL"
        )
    )
    backfilled = result.rowcount or 0

    op.alter_column("registered_use", "source_dated", nullable=False)
    op.alter_column("registered_use", "reentry_hours", nullable=True)

    print(f"\n  registered_use.source_dated backfilled from last_verified for {backfilled} row(s)")
    print("  registered_use.reentry_hours is now nullable")
    print("  registered_use.restriction_note added, nullable\n")


def downgrade() -> None:
    connection = op.get_bind()
    null_reentry = connection.scalar(
        sa.text("SELECT COUNT(*) FROM registered_use WHERE reentry_hours IS NULL")
    )
    if null_reentry:
        print(
            f"\n  WARNING: {null_reentry} row(s) have reentry_hours = NULL and will be "
            "DELETED\n  (the column is going back to NOT NULL and there is no honest "
            "value to backfill with).\n"
        )
        connection.execute(sa.text("DELETE FROM registered_use WHERE reentry_hours IS NULL"))

    op.alter_column("registered_use", "reentry_hours", nullable=False)
    op.drop_column("registered_use", "restriction_note")
    op.drop_column("registered_use", "source_dated")
