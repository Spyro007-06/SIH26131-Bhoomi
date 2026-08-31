"""v3 scope: four crops, twenty-six crop-namespaced targets

Scope moved from one crop and five targets to four crops and twenty-six.

WHY THE LABELS ARE RENAMED, NOT JUST ADDED TO

Bacterial blight exists in both cotton and soybean; anthracnose in both soybean
and jowar. An unprefixed set makes a wrong-crop match something the system has
to FILTER out, and a filter is something a future query can forget. Prefixed,
`cotton_bacterial_blight` and `soybean_bacterial_blight` are different values
and a cross-crop match is not expressible.

HOW THE RENAME IS DONE

`ALTER TYPE ... RENAME VALUE` is a catalog change: every row holding the old
label holds the new one immediately, with no row rewrite and no window in which
a column points at a value that no longer exists. Recreating the type and
casting each column would have moved the same data with more moving parts and a
worse failure mode halfway through.

The one place labels are NOT held as an enum is `diagnosis.topk`, which is JSONB
containing label strings. Those are rewritten explicitly below.

Revision ID: 0007_v3_crops_and_targets
Revises: 0006_confirmation_model_label
Create Date: 2026-08-31
"""

from __future__ import annotations

from collections.abc import Sequence

import sqlalchemy as sa

from alembic import op

revision: str = "0007_v3_crops_and_targets"
down_revision: str | None = "0006_confirmation_model_label"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


# v2 value -> v3 value. The five paddy targets keep their identity and gain the
# namespace; nothing is merged, split or dropped.
RENAMES: dict[str, str] = {
    "blast": "paddy_blast",
    "brown_spot": "paddy_brown_spot",
    "bacterial_leaf_blight": "paddy_bacterial_leaf_blight",
    "yellow_stem_borer": "paddy_yellow_stem_borer",
    "brown_planthopper": "paddy_brown_planthopper",
}

NEW_CROPS = ["cotton", "soybean", "jowar"]

NEW_TARGETS = [
    "cotton_american_bollworm", "cotton_pink_bollworm", "cotton_whitefly",
    "cotton_thrips", "cotton_bacterial_blight", "cotton_leaf_curl_virus",
    "cotton_fusarium_wilt",
    "soybean_stem_fly", "soybean_girdle_beetle", "soybean_defoliating_caterpillars",
    "soybean_yellow_mosaic_virus", "soybean_anthracnose",
    "soybean_alternaria_leaf_spot", "soybean_bacterial_blight",
    "jowar_shoot_fly", "jowar_stem_borer", "jowar_shoot_bug", "jowar_anthracnose",
    "jowar_grain_mold", "jowar_smut", "jowar_downy_mildew",
]

# Every column holding a target_label, for the report and the dead-value proof.
LABEL_COLUMNS = [
    ("problem", "label"),
    ("alert", "target"),
    ("confirmation", "model_label"),
    ("confirmation", "corrected_label"),
    ("label_prior", "label"),
    ("label_reference", "label"),
    ("registered_use", "target"),
    ("corpus_doc", "target"),
    ("distinguishing_cue", "answer_yes_implies"),
]


def _counts(connection) -> dict[tuple[str, str, str], int]:
    tally: dict[tuple[str, str, str], int] = {}
    for table, column in LABEL_COLUMNS:
        rows = connection.execute(
            sa.text(
                f'SELECT "{column}"::text AS v, count(*) AS n '  # noqa: S608 - fixed names
                f'FROM "{table}" WHERE "{column}" IS NOT NULL GROUP BY 1'
            )
        ).all()
        for row in rows:
            tally[(table, column, row.v)] = int(row.n)
    return tally


def upgrade() -> None:
    connection = op.get_bind()

    before = _counts(connection)

    # --- crop: three additions, paddy untouched ---------------------------
    for value in NEW_CROPS:
        op.execute(f"ALTER TYPE crop ADD VALUE IF NOT EXISTS '{value}'")

    # --- target_label: rename five, add twenty-one ------------------------
    for old, new in RENAMES.items():
        op.execute(f"ALTER TYPE target_label RENAME VALUE '{old}' TO '{new}'")
    for value in NEW_TARGETS:
        op.execute(f"ALTER TYPE target_label ADD VALUE IF NOT EXISTS '{value}'")

    # --- target_tier: new type -------------------------------------------
    op.execute(
        "DO $$ BEGIN "
        "IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'target_tier') THEN "
        "CREATE TYPE target_tier AS ENUM ('diagnosable','inspection'); "
        "END IF; END $$"
    )

    # --- diagnosis.topk: labels live inside JSONB, not as an enum ---------
    # Rewritten one label at a time so the report can show what moved. The
    # jsonb_set walks predictions[0..n] by index because jsonb has no map().
    topk_moved = 0
    for old, new in RENAMES.items():
        result = connection.execute(
            sa.text(
                """
                WITH rewritten AS (
                    SELECT d.id,
                           jsonb_set(
                               d.topk,
                               '{predictions}',
                               (
                                   SELECT coalesce(jsonb_agg(
                                       CASE WHEN p ->> 'label' = :old
                                            THEN jsonb_set(p, '{label}', to_jsonb(cast(:new AS text)))
                                            ELSE p END
                                       ORDER BY ord
                                   ), '[]'::jsonb)
                                   FROM jsonb_array_elements(d.topk -> 'predictions')
                                        WITH ORDINALITY AS t(p, ord)
                               )
                           ) AS topk
                    FROM diagnosis d
                    WHERE d.topk -> 'predictions' @> jsonb_build_array(
                              jsonb_build_object('label', :old)
                          )
                )
                UPDATE diagnosis d
                SET topk = r.topk
                FROM rewritten r
                WHERE d.id = r.id
                """
            ),
            {"old": old, "new": new},
        )
        topk_moved += result.rowcount or 0

    # --- distinguishing_cue.discriminates is text[], not enum -------------
    cues_moved = 0
    for old, new in RENAMES.items():
        result = connection.execute(
            sa.text(
                "UPDATE distinguishing_cue "
                "SET discriminates = array_replace(discriminates, :old, :new) "
                "WHERE :old = ANY(discriminates)"
            ),
            {"old": old, "new": new},
        )
        cues_moved += result.rowcount or 0

    after = _counts(connection)

    # --- the report -------------------------------------------------------
    print("\n  v3 label migration - rows moved per table")
    print(f"    {'table.column':34s} {'v2 label':26s} -> {'v3 label':30s} rows")
    print("    " + "-" * 96)
    total = 0
    for (table, column, value), _before_count in sorted(before.items()):
        new = RENAMES.get(value, value)
        moved = after.get((table, column, new), 0)
        print(f"    {table + '.' + column:34s} {value:26s} -> {new:30s} {moved}")
        total += moved
    if not before:
        print("    (no rows held a target_label)")
    print(f"\n    enum-column rows moved       {total}")
    print(f"    diagnosis.topk rows rewritten {topk_moved}")
    print(f"    distinguishing_cue rows       {cues_moved}")

    # --- prove no row is left on a dead value -----------------------------
    dead = connection.execute(
        sa.text(
            "SELECT count(*) FROM diagnosis d, "
            "jsonb_array_elements(d.topk -> 'predictions') p "
            "WHERE p ->> 'label' = ANY(:old)"
        ),
        {"old": list(RENAMES)},
    ).scalar_one()
    print(f"    topk entries still on a v2 label {dead}")
    if dead:
        raise RuntimeError(
            f"{dead} topk prediction(s) still hold a v2 label - migration aborted"
        )
    print()


def downgrade() -> None:
    connection = op.get_bind()

    for new, old in {v: k for k, v in RENAMES.items()}.items():
        op.execute(f"ALTER TYPE target_label RENAME VALUE '{new}' TO '{old}'")

    for new, old in {v: k for k, v in RENAMES.items()}.items():
        connection.execute(
            sa.text(
                """
                WITH rewritten AS (
                    SELECT d.id,
                           jsonb_set(d.topk, '{predictions}', (
                               SELECT coalesce(jsonb_agg(
                                   CASE WHEN p ->> 'label' = :new
                                        THEN jsonb_set(p, '{label}', to_jsonb(cast(:old AS text)))
                                        ELSE p END
                                   ORDER BY ord
                               ), '[]'::jsonb)
                               FROM jsonb_array_elements(d.topk -> 'predictions')
                                    WITH ORDINALITY AS t(p, ord)
                           )) AS topk
                    FROM diagnosis d
                    WHERE d.topk -> 'predictions' @> jsonb_build_array(
                              jsonb_build_object('label', :new)
                          )
                )
                UPDATE diagnosis d SET topk = r.topk FROM rewritten r WHERE d.id = r.id
                """
            ),
            {"new": new, "old": old},
        )
        connection.execute(
            sa.text(
                "UPDATE distinguishing_cue "
                "SET discriminates = array_replace(discriminates, :new, :old) "
                "WHERE :new = ANY(discriminates)"
            ),
            {"new": new, "old": old},
        )

    op.execute("DROP TYPE IF EXISTS target_tier")

    # The 21 added target_label values and 3 added crop values are NOT removed.
    # Postgres cannot drop an enum value, and recreating both types to shed them
    # would rewrite every dependent column to undo an addition that harms
    # nothing. A v2 database with unused v3 values in its enums is consistent.
