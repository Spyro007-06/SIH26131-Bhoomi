"""confirmation model_label

Adds Confirmation.model_label — what the model actually predicted, frozen at
confirm time — and backfills it where the answer is unambiguous.

WHY THE COLUMN EXISTS

/officials/accuracy grouped on Problem.label, and on a correction that column
has already been overwritten with the corrected label. So a case where the model
said blast and the agronomist corrected it to brown_spot was reported as a
correction against BROWN_SPOT — the label the model never predicted. F15's
headline metric read the inverse of the truth: the label the model got wrong
looked clean, and the label it was corrected to carried the penalty.

The model's guess is not recoverable after the fact, so it is recorded at the
moment it is still known. Same reasoning as Alert.reason: freeze what was true
when the event happened rather than reconstructing it later.

THE BACKFILL REFUSES TO GUESS

A problem with exactly one Diagnosis has one unambiguous model label, taken from
topk.predictions[0].label. A problem with several has no single answer — the
confirmation may relate to any of them — and one with none never had a model
prediction at all. Both are left NULL and counted, because a guessed value in an
accuracy metric is worse than a gap: a gap is visible, a guess is not.

Revision ID: 0006_confirmation_model_label
Revises: 0005_case_bundle_sql_null
Create Date: 2026-08-30
"""

from __future__ import annotations

from collections.abc import Sequence

import sqlalchemy as sa

from alembic import op

revision: str = "0006_confirmation_model_label"
down_revision: str | None = "0005_case_bundle_sql_null"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


# Only problems with exactly one diagnosis, and only where that diagnosis's
# top-1 label is a real member of the target_label enum. A topk written by an
# older or stubbed producer could hold anything; casting it blindly would abort
# the migration.
BACKFILL = """
UPDATE confirmation AS c
SET model_label = sub.label::target_label
FROM (
    SELECT d.problem_id,
           d.topk -> 'predictions' -> 0 ->> 'label' AS label
    FROM diagnosis d
    WHERE d.problem_id IN (
        SELECT problem_id FROM diagnosis GROUP BY problem_id HAVING count(*) = 1
    )
) AS sub
WHERE c.problem_id = sub.problem_id
  AND sub.label IS NOT NULL
  AND sub.label IN (SELECT unnest(enum_range(NULL::target_label))::text)
"""

REPORT = """
SELECT
    count(*) FILTER (WHERE c.model_label IS NOT NULL)                      AS backfilled,
    count(*) FILTER (WHERE c.model_label IS NULL AND d.n IS NULL)          AS no_diagnosis,
    count(*) FILTER (WHERE c.model_label IS NULL AND d.n > 1)              AS many_diagnoses,
    count(*) FILTER (WHERE c.model_label IS NULL AND d.n = 1)              AS one_but_unusable,
    count(*)                                                               AS total
FROM confirmation c
LEFT JOIN (
    SELECT problem_id, count(*) AS n FROM diagnosis GROUP BY problem_id
) d ON d.problem_id = c.problem_id
"""


def upgrade() -> None:
    op.add_column(
        "confirmation",
        sa.Column(
            "model_label",
            sa.Enum(
                "blast",
                "brown_spot",
                "bacterial_leaf_blight",
                "yellow_stem_borer",
                "brown_planthopper",
                name="target_label",
                create_type=False,
            ),
            nullable=True,
        ),
    )

    connection = op.get_bind()
    connection.execute(sa.text(BACKFILL))
    row = connection.execute(sa.text(REPORT)).one()

    print("\n  Confirmation.model_label backfill")
    print(f"    rows total                 {row.total}")
    print(f"    backfilled                 {row.backfilled}")
    print(f"    left NULL, no diagnosis    {row.no_diagnosis}")
    print(f"    left NULL, >1 diagnosis    {row.many_diagnoses}")
    print(f"    left NULL, label not in enum {row.one_but_unusable}")
    if row.total and row.backfilled < row.total:
        print(
            "    NULLs are deliberate. /officials/accuracy excludes them rather\n"
            "    than attributing them to a guessed label."
        )
    print()


def downgrade() -> None:
    op.drop_column("confirmation", "model_label")
