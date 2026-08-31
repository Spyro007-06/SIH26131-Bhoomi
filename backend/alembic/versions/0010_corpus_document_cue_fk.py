"""corpus_document table, distinguishing_cue.doc_id repointed to it

Fixes a dangling-pointer bug found while ingesting the real corpus delivery.

distinguishing_cue.doc_id FK'd to corpus_doc.id -- the per-chunk surrogate
key that migration 0009's delete-then-reinsert idempotency regenerates on
EVERY corpus reload, not just the first. Since cues are F4's entire input and
F4 escalates silently (rather than erroring) on a missing cue, an orphaned
cue does not fail loudly -- it silently disables the Doubt Doctor.

corpus_doc.doc_id (the manifest slug the brief actually wants cues to
reference) is not itself a valid FK target: it repeats across every
section-chunk of one document, and again across a two-target file's second
target. A real FK constraint needs something unique to land on, so this
migration introduces corpus_document -- one stable row per manifest doc_id,
upserted once by the loader and never deleted on reload -- and repoints both
corpus_doc.doc_id and distinguishing_cue.doc_id at it.

distinguishing_cue.doc_id changes type from UUID to TEXT (it now stores the
slug itself, not a chunk id). Existing cues are carried forward by joining
through the OLD corpus_doc.id -> corpus_doc.doc_id relationship before the
old column is dropped; a cue whose corpus_doc.id no longer resolves to any
row (already orphaned before this migration) ends up NULL, same as it would
if F4 could not find it today -- no new degradation, just an honest one.

Revision ID: 0010_corpus_document_cue_fk
Revises: 0009_corpus_doc_id_authoritative
Create Date: 2026-08-31
"""

from __future__ import annotations

from collections.abc import Sequence

import sqlalchemy as sa

from alembic import op

revision: str = "0010_corpus_document_cue_fk"
down_revision: str | None = "0009_corpus_doc_id_authoritative"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.create_table(
        "corpus_document",
        sa.Column("doc_id", sa.Text(), primary_key=True, nullable=False),
    )

    connection = op.get_bind()

    # One corpus_document row per distinct doc_id already in corpus_doc, so
    # the FK added below has something to reference.
    connection.execute(
        sa.text(
            "INSERT INTO corpus_document (doc_id) "
            "SELECT DISTINCT doc_id FROM corpus_doc "
            "ON CONFLICT (doc_id) DO NOTHING"
        )
    )

    op.create_foreign_key(
        "fk_corpus_doc_doc_id_corpus_document",
        "corpus_doc", "corpus_document", ["doc_id"], ["doc_id"],
    )

    # distinguishing_cue.doc_id: UUID (chunk id) -> TEXT (stable slug).
    op.add_column("distinguishing_cue", sa.Column("doc_id_new", sa.Text(), nullable=True))
    connection.execute(
        sa.text(
            "UPDATE distinguishing_cue dc SET doc_id_new = cd.doc_id "
            "FROM corpus_doc cd WHERE dc.doc_id = cd.id"
        )
    )
    op.drop_constraint("distinguishing_cue_doc_id_fkey", "distinguishing_cue", type_="foreignkey")
    op.drop_column("distinguishing_cue", "doc_id")
    op.alter_column("distinguishing_cue", "doc_id_new", new_column_name="doc_id")
    op.create_foreign_key(
        "fk_distinguishing_cue_doc_id_corpus_document",
        "distinguishing_cue", "corpus_document", ["doc_id"], ["doc_id"],
        ondelete="SET NULL",
    )

    print(
        "\n  corpus_document seeded from corpus_doc's existing distinct doc_id values"
        "\n  distinguishing_cue.doc_id repointed from corpus_doc.id (chunk) to "
        "corpus_document.doc_id (stable slug)\n"
    )


def downgrade() -> None:
    op.drop_constraint(
        "fk_distinguishing_cue_doc_id_corpus_document", "distinguishing_cue", type_="foreignkey"
    )
    op.add_column("distinguishing_cue", sa.Column("doc_id_old", sa.UUID(), nullable=True))
    # No general way back from a stable slug to a specific chunk id -- the
    # relationship this migration removes was the bug. Reverted rows carry
    # doc_id = NULL, same as an orphaned cue looked before this migration.
    op.drop_column("distinguishing_cue", "doc_id")
    op.alter_column("distinguishing_cue", "doc_id_old", new_column_name="doc_id")
    op.create_foreign_key(
        "distinguishing_cue_doc_id_fkey", "distinguishing_cue", "corpus_doc",
        ["doc_id"], ["id"], ondelete="SET NULL",
    )

    op.drop_constraint("fk_corpus_doc_doc_id_corpus_document", "corpus_doc", type_="foreignkey")
    op.drop_table("corpus_document")
