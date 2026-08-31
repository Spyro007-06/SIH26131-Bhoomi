"""growth_stage table invariants.

OWNER: Shreekumar. docs/DESIGN.md §5 (v3).
"""

from __future__ import annotations

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


async def test_no_growth_stage_row_is_unsourced(db_session) -> None:
    """The V1 trip-wire, closed in V2.

    Every row now names a real source in seed/growth_stages.py — see that
    module's docstring for what "sourced" means here: the named ICAR PDF was
    not reachable from this environment on either phase, so these are drawn
    from reachable agronomic literature, cited per crop, not from that single
    document. If a stricter source supersedes these, correct the row and this
    test keeps passing on its own; it is not itself the citation.
    """
    rows = (
        await db_session.execute(
            select(GrowthStage).where(GrowthStage.source == UNSOURCED)
        )
    ).scalars().all()

    unsourced_crops = sorted({r.crop.value for r in rows})
    assert not unsourced_crops, (
        f"{len(rows)} growth_stage row(s) across {unsourced_crops} still read "
        f"UNSOURCED-PENDING-REVIEW — seed/growth_stages.py was not fully "
        f"applied, or a new unsourced row was added without updating its "
        f"source field."
    )
