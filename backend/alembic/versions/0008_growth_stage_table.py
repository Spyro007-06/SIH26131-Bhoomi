"""growth stages become a per-crop table

The v2 enum held six paddy stages — nursery, tillering, vegetative, booting,
flowering, maturity. Cotton has squaring and boll formation; jowar and soybean
have their own. The F5 phenology branch could not express "pink bollworm at boll
formation" because that stage did not exist as a value.

ORDER MATTERS HERE. In Postgres a table and a type share one namespace, so the
enum `growth_stage` and the table `growth_stage` cannot coexist. The columns are
converted to text and the enum dropped BEFORE the table is created.

THE FK IS COMPOSITE, ON (crop, growth_stage). A farm cannot hold a stage
belonging to another crop: that is not filtered out at read time, it is not
storable. Same reasoning as the two CHECK constraints in docs/DESIGN.md §5 —
enforcing it in application code means someone bypasses it.

The rows below are a snapshot frozen at this revision. `seed/growth_stages.py`
holds the live canonical set and upserts it; a migration must not change
behaviour because a seed file was edited later.

Revision ID: 0008_growth_stage_table
Revises: 0007_v3_crops_and_targets
Create Date: 2026-08-31
"""

from __future__ import annotations

from collections.abc import Sequence

import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

from alembic import op

revision: str = "0008_growth_stage_table"
down_revision: str | None = "0007_v3_crops_and_targets"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None

SOURCED = "v2 enum + Phase 1 seed DAS arithmetic"
UNSOURCED = "UNSOURCED-PENDING-REVIEW"

# (crop, stage_key, display_name, order, das_min, das_max, source)
STAGES = [
    # Paddy keeps the v2 vocabulary and the DAS windows the Phase 1 seed already
    # used — farm A is tillering at 52 DAS, farm C vegetative at 33.
    ("paddy", "nursery", "Nursery", 1, 0, 25, SOURCED),
    ("paddy", "vegetative", "Vegetative", 2, 25, 40, SOURCED),
    ("paddy", "tillering", "Tillering", 3, 40, 65, SOURCED),
    ("paddy", "booting", "Booting", 4, 65, 85, SOURCED),
    ("paddy", "flowering", "Flowering", 5, 85, 105, SOURCED),
    ("paddy", "maturity", "Maturity", 6, 105, 130, SOURCED),
    # The three new crops are UNSOURCED. The ICAR reference named in the V1
    # brief (cotton_soybean_jowar_pest_disease_symptoms.pdf) is not in the
    # repository, so these are standard phenological vocabularies proposed by
    # Claude and explicitly NOT sourced. tests/test_growth_stages.py fails if
    # any survives past V2.
    ("cotton", "germination", "Germination", 1, 0, 15, UNSOURCED),
    ("cotton", "vegetative", "Vegetative", 2, 15, 35, UNSOURCED),
    ("cotton", "squaring", "Squaring", 3, 35, 60, UNSOURCED),
    ("cotton", "flowering", "Flowering", 4, 60, 90, UNSOURCED),
    ("cotton", "boll_formation", "Boll formation", 5, 90, 120, UNSOURCED),
    ("cotton", "boll_opening", "Boll opening", 6, 120, 160, UNSOURCED),
    ("soybean", "emergence", "Emergence", 1, 0, 10, UNSOURCED),
    ("soybean", "vegetative", "Vegetative", 2, 10, 35, UNSOURCED),
    ("soybean", "flowering", "Flowering", 3, 35, 55, UNSOURCED),
    ("soybean", "pod_formation", "Pod formation", 4, 55, 80, UNSOURCED),
    ("soybean", "seed_filling", "Seed filling", 5, 80, 100, UNSOURCED),
    ("soybean", "maturity", "Maturity", 6, 100, 120, UNSOURCED),
    ("jowar", "seedling", "Seedling", 1, 0, 20, UNSOURCED),
    ("jowar", "vegetative", "Vegetative", 2, 20, 40, UNSOURCED),
    ("jowar", "boot_leaf", "Boot leaf", 3, 40, 60, UNSOURCED),
    ("jowar", "flowering", "Flowering", 4, 60, 80, UNSOURCED),
    ("jowar", "grain_filling", "Grain filling", 5, 80, 100, UNSOURCED),
    ("jowar", "maturity", "Maturity", 6, 100, 125, UNSOURCED),
]


def upgrade() -> None:
    connection = op.get_bind()

    # 1. Columns off the enum, so the type can be dropped and the name reused.
    op.execute("ALTER TABLE farm ALTER COLUMN growth_stage TYPE text USING growth_stage::text")
    op.execute(
        "ALTER TABLE label_prior ALTER COLUMN growth_stage TYPE text "
        "USING growth_stage::text"
    )
    op.execute("DROP TYPE IF EXISTS growth_stage")

    # 2. The table.
    op.create_table(
        "growth_stage",
        # postgresql.ENUM, not sa.Enum: only the dialect type honours
        # create_type=False inside create_table. sa.Enum re-emits CREATE TYPE
        # and fails on the type that already exists.
        sa.Column(
            "crop",
            postgresql.ENUM(
                "paddy", "cotton", "soybean", "jowar", name="crop", create_type=False
            ),
            nullable=False,
        ),
        sa.Column("stage_key", sa.Text(), nullable=False),
        sa.Column("display_name", sa.Text(), nullable=False),
        sa.Column("display_order", sa.Integer(), nullable=False),
        sa.Column("typical_das_min", sa.Integer(), nullable=False),
        sa.Column("typical_das_max", sa.Integer(), nullable=False),
        sa.Column("source", sa.Text(), nullable=False),
        sa.PrimaryKeyConstraint("crop", "stage_key"),
        sa.UniqueConstraint("crop", "display_order", name="uq_growth_stage_crop_order"),
        sa.CheckConstraint(
            "typical_das_min >= 0 AND typical_das_max >= typical_das_min",
            name="ck_growth_stage_das_window",
        ),
        sa.CheckConstraint("display_order >= 0", name="ck_growth_stage_display_order"),
    )

    # 3. Seed, before the FKs — existing farm rows already point at paddy keys.
    connection.execute(
        sa.text(
            "INSERT INTO growth_stage (crop, stage_key, display_name, display_order,"
            " typical_das_min, typical_das_max, source)"
            " VALUES (cast(:crop AS crop), :stage_key, :display_name, :display_order,"
            " :das_min, :das_max, :source)"
        ),
        [
            {
                "crop": crop, "stage_key": key, "display_name": name,
                "display_order": order, "das_min": lo, "das_max": hi, "source": src,
            }
            for crop, key, name, order, lo, hi, src in STAGES
        ],
    )

    # 4. Composite FKs. These fail loudly if any existing farm holds a stage that
    #    is not valid for its crop, which is the point.
    op.create_foreign_key(
        "fk_farm_crop_growth_stage", "farm", "growth_stage",
        ["crop", "growth_stage"], ["crop", "stage_key"], onupdate="CASCADE",
    )
    op.create_foreign_key(
        "fk_label_prior_crop_growth_stage", "label_prior", "growth_stage",
        ["crop", "growth_stage"], ["crop", "stage_key"], onupdate="CASCADE",
    )

    counts = connection.execute(
        sa.text(
            "SELECT crop::text AS crop, count(*) AS n,"
            " count(*) FILTER (WHERE source = :unsourced) AS unsourced"
            " FROM growth_stage GROUP BY 1 ORDER BY 1"
        ),
        {"unsourced": UNSOURCED},
    ).all()
    print("\n  growth_stage seeded")
    for row in counts:
        flag = f"  ({row.unsourced} UNSOURCED)" if row.unsourced else "  (sourced)"
        print(f"    {row.crop:10s} {row.n} stages{flag}")
    print()


def downgrade() -> None:
    op.drop_constraint("fk_label_prior_crop_growth_stage", "label_prior", type_="foreignkey")
    op.drop_constraint("fk_farm_crop_growth_stage", "farm", type_="foreignkey")
    op.drop_table("growth_stage")

    op.execute(
        "CREATE TYPE growth_stage AS ENUM "
        "('nursery','tillering','vegetative','booting','flowering','maturity')"
    )
    # Rows holding a stage outside the v2 paddy set cannot be represented by the
    # enum. There are none on a database that only ever held paddy farms; if a
    # cotton farm exists this will fail, correctly, rather than discarding it.
    op.execute(
        "ALTER TABLE farm ALTER COLUMN growth_stage TYPE growth_stage "
        "USING growth_stage::growth_stage"
    )
    op.execute(
        "ALTER TABLE label_prior ALTER COLUMN growth_stage TYPE growth_stage "
        "USING growth_stage::growth_stage"
    )
