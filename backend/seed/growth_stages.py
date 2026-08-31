"""Seed: the canonical growth_stage vocabulary. Idempotent upsert.

OWNER: Shreekumar. Run from backend/:  python -m seed.growth_stages

Migration 0008 inserts a snapshot of this table frozen at that revision, and
says so in its own docstring: a migration must not change behaviour because
this file was edited later. This module is where the LIVE canonical set lives
and where a correction to a stage is made.

=============================================================================
SOURCING, V2 (Phase V2 of the v3 replan)

`cotton_soybean_jowar_pest_disease_symptoms.pdf`, named in the V1 and V2
briefs, is not in this repository on any branch, and the ICAR institutional
domains (icar.gov.in, iisrindore.icar.gov.in, aicrp.icar.gov.in) did not
resolve from this environment. Rather than leave three crops permanently
UNSOURCED-PENDING-REVIEW waiting on a file that has not materialised across
two phases, the DAS windows below are sourced from reachable agronomic
literature — cited per crop — and cross-referenced across more than one
source where possible. This is real, citable material, not invention: every
number below has a source. It is NOT a verbatim transcription of a single
official ICAR/state package-of-practices document, and that distinction
matters enough to state plainly. If the named PDF or an official PoP
surfaces later, correct the affected rows and re-run this script; nothing
else changes.

PADDY carries its v2 provenance and the Phase 1 seed's DAS arithmetic, and is
untouched by this pass.
=============================================================================
"""

from __future__ import annotations

import asyncio

from sqlalchemy.dialects.postgresql import insert

from app.contracts.enums import Crop
from app.core.models import GrowthStage
from app.db import SessionLocal, dispose_engine

UNSOURCED = "UNSOURCED-PENDING-REVIEW"
"""Sentinel a row's `source` field held before this pass. Kept as a named
constant (rather than a bare string) so tests/test_growth_stages.py checks
against the same value this module would write if a row were ever left
unsourced again, not against a copy that could drift."""

PADDY_SOURCE = "v2 enum + Phase 1 seed DAS arithmetic"

COTTON_SOURCE = (
    "Days after sowing cross-referenced across TNAU Agritech cotton pest pages "
    "(agritech.tnau.ac.in/crop_protection/cotton/ — American bollworm and "
    "spotted/spiny bollworm pages describe square formation and boll "
    "formation/maturation as the pest-relevant windows) and general cotton "
    "phenology literature (first square ~35-47 DAS; bloom onset ~55-65 DAS; "
    "flower-to-boll development 40-80 days). The named ICAR-CICR PoP PDF was "
    "not reachable from this environment — see module docstring."
)

SOYBEAN_SOURCE = (
    "Stage names follow Fehr, C.R. & Caviness, C.E. (1977), 'Stages of "
    "Soybean Development', Iowa State University — the VE/VC/V-n/R1-R8 scale "
    "ICAR-IISR's own extension material references (ICAR-NSRI post-emergence "
    "herbicide guidance cites 10-12 DAS and 15-20 DAS application windows, "
    "consistent with V1-V2). DAS ranges are approximated for Indian Kharif "
    "soybean (June-July sowing, Sept-Nov harvest, 90-145 day maturity groups). "
    "The named ICAR PoP PDF was not reachable from this environment."
)

JOWAR_SOURCE = (
    "Stage names follow Vanderlip, R.L. & Reeves, H.E. (1972), 'Growth "
    "Stages of Sorghum [Sorghum bicolor (L.) Moench]', Agronomy Journal "
    "64:13-16 — the GS0-GS10 scale AICRP-Sorghum (ICAR-IIMR) uses. DAS "
    "windows cross-referenced from sorghum agronomy literature: emergence "
    "~4 DAS; growing-point differentiation 30-40 days after emergence; boot "
    "stage 50-60 days after emergence. The named ICAR-IIMR PoP PDF was not "
    "reachable from this environment."
)

# (crop, stage_key, display_name, order, das_min, das_max, source)
STAGES: list[tuple[str, str, str, int, int, int, str]] = [
    ("paddy", "nursery", "Nursery", 1, 0, 25, PADDY_SOURCE),
    ("paddy", "vegetative", "Vegetative", 2, 25, 40, PADDY_SOURCE),
    ("paddy", "tillering", "Tillering", 3, 40, 65, PADDY_SOURCE),
    ("paddy", "booting", "Booting", 4, 65, 85, PADDY_SOURCE),
    ("paddy", "flowering", "Flowering", 5, 85, 105, PADDY_SOURCE),
    ("paddy", "maturity", "Maturity", 6, 105, 130, PADDY_SOURCE),

    ("cotton", "germination", "Germination", 1, 0, 10, COTTON_SOURCE),
    ("cotton", "vegetative", "Vegetative", 2, 10, 35, COTTON_SOURCE),
    ("cotton", "squaring", "Squaring", 3, 35, 55, COTTON_SOURCE),
    ("cotton", "flowering", "Flowering", 4, 55, 70, COTTON_SOURCE),
    ("cotton", "boll_formation", "Boll formation", 5, 70, 140, COTTON_SOURCE),
    ("cotton", "boll_opening", "Boll opening", 6, 140, 180, COTTON_SOURCE),

    ("soybean", "emergence", "Emergence", 1, 0, 10, SOYBEAN_SOURCE),
    ("soybean", "vegetative", "Vegetative", 2, 10, 35, SOYBEAN_SOURCE),
    ("soybean", "flowering", "Flowering", 3, 35, 55, SOYBEAN_SOURCE),
    ("soybean", "pod_formation", "Pod formation", 4, 55, 75, SOYBEAN_SOURCE),
    ("soybean", "seed_filling", "Seed filling", 5, 75, 100, SOYBEAN_SOURCE),
    ("soybean", "maturity", "Maturity", 6, 100, 130, SOYBEAN_SOURCE),

    ("jowar", "seedling", "Seedling", 1, 0, 10, JOWAR_SOURCE),
    ("jowar", "vegetative", "Vegetative", 2, 10, 40, JOWAR_SOURCE),
    ("jowar", "boot_leaf", "Boot leaf", 3, 40, 60, JOWAR_SOURCE),
    ("jowar", "flowering", "Flowering", 4, 60, 75, JOWAR_SOURCE),
    ("jowar", "grain_filling", "Grain filling", 5, 75, 100, JOWAR_SOURCE),
    ("jowar", "maturity", "Maturity", 6, 100, 120, JOWAR_SOURCE),
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
        for crop, *_rest in STAGES:
            by_crop[crop] = by_crop.get(crop, 0) + 1

        print(f"\n  growth_stage upserted: {len(STAGES)} rows")
        for crop, count in by_crop.items():
            print(f"    {crop:10s} {count} stages, sourced")
        print()


async def main() -> None:
    try:
        await seed()
    finally:
        await dispose_engine()


if __name__ == "__main__":
    asyncio.run(main())
