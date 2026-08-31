"""corpus_doc.doc_id and corpus_doc.authoritative

Two columns for the corpus ingestion loader (scripts/load_corpus.py).

doc_id (TEXT NOT NULL) is the manifest's stable slug for a SOURCE DOCUMENT --
distinct from `id`, which is the surrogate key of one CHUNK. One document
produces several chunks, one per markdown section, and for the manifest's own
two-target files the same doc_id recurs under a second target. The loader's
idempotency is delete-then-reinsert per (doc_id, target), not a per-chunk
upsert: section headings can change between manifest revisions, so there is no
stable per-chunk key to upsert against, only a stable (doc_id, target) group.

authoritative (BOOLEAN NOT NULL DEFAULT true) is false on a chunk sourced from
a document's Chemical Management section. Every delivered document has one,
written from training knowledge and flagged by the manifest itself as
unverified against any registration table. docs/DESIGN.md §8 (v3) requires a
chemical rung to resolve against `registered_use` at composition time; this
flag is what lets the retrieval path exclude an unverified chunk from ever
reaching that composition, while keeping it available as background reading.
A citation attached to an unverified dosage is more dangerous than no
citation, because it looks checked.

Existing rows (the three paddy_blast chunks from Phase 4's corpus authoring)
get a synthetic doc_id derived from their title, since they predate the
manifest concept, and authoritative=true by the column default, since none of
them are Chemical Management content.

Revision ID: 0009_corpus_doc_id_authoritative
Revises: 0008_growth_stage_table
Create Date: 2026-08-31
"""

from __future__ import annotations

from collections.abc import Sequence

import sqlalchemy as sa

from alembic import op

revision: str = "0009_corpus_doc_id_authoritative"
down_revision: str | None = "0008_growth_stage_table"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.add_column(
        "corpus_doc",
        sa.Column("doc_id", sa.Text(), nullable=True),
    )
    op.add_column(
        "corpus_doc",
        sa.Column(
            "authoritative", sa.Boolean(), nullable=False, server_default=sa.text("true")
        ),
    )

    connection = op.get_bind()
    # Backfill pre-manifest rows with a slug derived from their title, so the
    # column can be made NOT NULL. lower/replace/regexp_replace rather than a
    # Python loop: three rows today, but the transformation has to be correct
    # for however many exist by the time this runs.
    result = connection.execute(
        sa.text(
            "UPDATE corpus_doc SET doc_id = "
            "regexp_replace(lower(trim(title)), '[^a-z0-9]+', '_', 'g') "
            "WHERE doc_id IS NULL"
        )
    )
    backfilled = result.rowcount or 0

    op.alter_column("corpus_doc", "doc_id", nullable=False)

    print(f"\n  corpus_doc.doc_id backfilled for {backfilled} pre-manifest row(s)")
    print("  corpus_doc.authoritative defaulted to true for all existing rows\n")


def downgrade() -> None:
    op.drop_column("corpus_doc", "authoritative")
    op.drop_column("corpus_doc", "doc_id")
