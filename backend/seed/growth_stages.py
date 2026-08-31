"""Seed: the canonical growth_stage vocabulary. Idempotent upsert.

OWNER: Shreekumar. Run from backend/:  python -m seed.growth_stages

Migration 0008 inserts a snapshot of this table frozen at that revision, and
says so in its own docstring: a migration must not change behaviour because
this file was edited later. This module is where the LIVE canonical set lives
and where a correction to an UNSOURCED row is made.

=============================================================================
Paddy's six stages carry v2 provenance and the Phase 1 seed's DAS arithmetic.

Cotton, soybean and jowar are UNSOURCED-PENDING-REVIEW. The ICAR reference
named in the V1 brief (cotton_soybean_jowar_pest_disease_symptoms.pdf) is not
in this repository, so these eighteen rows are standard phenological
vocabularies proposed without a source, not transcribed from one.

tests/test_growth_stages.py fails the suite if any UNSOURCED row survives past
V2 — replace the `source` field with a real citation when the reference lands,
run this script again, and the CHECK constraint and the upsert do the rest.
=============================================================================
"""

from __future__ import annotations

import asyncio

from sqlalchemy.dialects.postgresql import insert

from app.contracts.enums import Crop
from app.core.models import GrowthStage
from app.db import SessionLocal, dispose_engine

SOURCED = "v2 enum + Phase 1 seed DAS arithmetic"
UNSOURCED = "UNSOURCED-PENDING-REVIEW"

# (crop, stage_key, display_name, order, das_min, das_max, source)
# Identical to migration 0008's frozen snapshot at the moment this file was
# written. Edit HERE for a live correction; the migration stays historical.
STAGES: list[tuple[str, str, str, int, int, int, str]] = [
    ("paddy", "nursery", "Nursery", 1, 0, 25, SOURCED),
    ("paddy", "vegetative", "Vegetative", 2, 25, 40, SOURCED),
    ("paddy", "tillering", "Tillering", 3, 40, 65, SOURCED),
    ("paddy", "booting", "Booting", 4, 65, 85, SOURCED),
    ("paddy", "flowering", "Flowering", 5, 85, 105, SOURCED),
    ("paddy", "maturity", "Maturity", 6, 105, 130, SOURCED),
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


async def seed() -> None:
    async with SessionLocal() as session:
        for crop, key, name, order, lo, hi, source in STAGES:
            statement = insert(GrowthStage.__table__).values(
                crop=Crop(crop), stage_key=key, display_name=name,
                display_order=order, typical_das_min=lo, typical_das_max=hi,
                source=source,
            )
            await session.execute(
                statement.on_conflict_do_update(
                    index_elements=["crop", "stage_key"],
                    set_={
                        "display_name": statement.excluded.display_name,
                        "display_order": statement.excluded.display_order,
                        "typical_das_min": statement.excluded.typical_das_min,
                        "typical_das_max": statement.excluded.typical_das_max,
                        "source": statement.excluded.source,
                    },
                )
            )
        await session.commit()

        by_crop: dict[str, int] = {}
        unsourced = 0
        for crop, *_rest, source in STAGES:
            by_crop[crop] = by_crop.get(crop, 0) + 1
            if source == UNSOURCED:
                unsourced += 1

        print(f"\n  growth_stage upserted: {len(STAGES)} rows")
        for crop, count in by_crop.items():
            print(f"    {crop:10s} {count} stages")
        if unsourced:
            print(f"\n  {unsourced} row(s) still UNSOURCED-PENDING-REVIEW.")
        print()


async def main() -> None:
    try:
        await seed()
    finally:
        await dispose_engine()


if __name__ == "__main__":
    asyncio.run(main())
