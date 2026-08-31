"""growth_stage table invariants.

OWNER: Shreekumar. docs/DESIGN.md §5 (v3).
"""

from __future__ import annotations

import pytest
from sqlalchemy import select

from app.contracts.enums import Crop
from app.core.models import GrowthStage
from seed.growth_stages import STAGES, UNSOURCED


def test_seed_covers_every_crop_with_a_contiguous_display_order() -> None:
    """A gap in display_order means a stage was silently dropped."""
    by_crop: dict[str, list[int]] = {}
    for crop, _key, _name, order, *_rest in STAGES:
        by_crop.setdefault(crop, []).append(order)

    assert set(by_crop) == {c.value for c in Crop}
    for crop, orders in by_crop.items():
        assert sorted(orders) == list(range(1, len(orders) + 1)), (
            f"{crop} display_order is not contiguous: {sorted(orders)}"
        )


def test_das_windows_are_well_formed() -> None:
    for crop, key, _name, _order, lo, hi, _source in STAGES:
        assert lo >= 0, f"{crop}.{key} typical_das_min is negative"
        assert hi >= lo, f"{crop}.{key} typical_das_max < typical_das_min"


@pytest.mark.xfail(
    strict=True,
    reason=(
        "18 growth_stage rows (cotton, soybean, jowar) are "
        "UNSOURCED-PENDING-REVIEW pending the ICAR reference named in the V1 "
        "brief. strict=True: the day someone sources them and this test starts "
        "passing, the suite goes RED until this xfail marker is removed — that "
        "forced failure is the mechanical prompt to update seed/growth_stages.py "
        "and this docstring, not a bug in either."
    ),
)
async def test_unsourced_stages_are_visible_in_the_live_table(db_session) -> None:
    """Fails (xfail) while cotton/soybean/jowar stages remain unsourced;
    forces attention (XPASS -> suite failure) the moment they are not.

    Five people are building phenology rules against these stage keys, and
    nobody should discover the provenance gap by reading a comment.
    docs/PRD.md §10 and docs/DESIGN.md §14 flag unowned/unsourced inputs the
    same way — visible in the tree or the test suite, not only in prose.
    """
    rows = (
        await db_session.execute(
            select(GrowthStage).where(GrowthStage.source == UNSOURCED)
        )
    ).scalars().all()

    unsourced_crops = sorted({r.crop.value for r in rows})

    assert not unsourced_crops, (
        f"{len(rows)} growth_stage row(s) across {unsourced_crops} are still "
        f"UNSOURCED-PENDING-REVIEW. This is expected until the ICAR reference "
        f"(cotton_soybean_jowar_pest_disease_symptoms.pdf) is sourced and "
        f"seed/growth_stages.py is corrected. Not a bug to silence — fix the "
        f"data, then this test passes on its own."
    )
