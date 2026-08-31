"""The two Alert constraints, tested at the database.

Both must fail in Postgres, not in Python. docs/DESIGN.md §5 is explicit that
enforcing them in application code means someone bypasses them at hour 25 — so
these tests insert directly through the ORM and assert the *database* rejects
the row. If a Python validator were added later and started catching these
first, the tests would still pass only because the DB check is still there.
"""

from __future__ import annotations

import uuid
from datetime import UTC, datetime, timedelta

import pytest
from sqlalchemy.exc import IntegrityError

from app.contracts.enums import AlertTrigger, Crop, Role, TargetLabel
from app.core.models import Alert, Farm, User

TASKS = [
    "Walk a diagonal line across the field and check the upper leaves of ten plants, today.",
    "Photograph any spot with a grey centre.",
]


async def _farm(session) -> Farm:
    farmer = User(role=Role.FARMER, phone=f"+9199{uuid.uuid4().int % 10**8:08d}", name="probe")
    session.add(farmer)
    await session.flush()
    farm = Farm(
        farmer_id=farmer.id,
        crop=Crop.PADDY,
        growth_stage="tillering",
        region="Nashik",
        location="SRID=4326;POINT(73.7898 19.9975)",
    )
    session.add(farm)
    await session.flush()
    return farm


def _alert(farm: Farm, **overrides) -> Alert:
    return Alert(
        farm_id=farm.id,
        trigger_type=overrides.pop("trigger_type", AlertTrigger.WEATHER),
        target=overrides.pop("target", TargetLabel.PADDY_BLAST),
        risk_level=overrides.pop("risk_level", "high"),
        reason=overrides.pop(
            "reason", "Humidity above 90% for 4 consecutive nights at tillering stage."
        ),
        inspection_tasks=overrides.pop("inspection_tasks", TASKS),
        **overrides,
    )


# --- carried forward from Phase 1: it rejected then, assert it still does ----


async def test_alert_with_empty_inspection_tasks_is_rejected(db_session) -> None:
    """docs/DESIGN.md §5: "An alert without a task is noise." """
    farm = await _farm(db_session)
    db_session.add(_alert(farm, inspection_tasks=[]))

    with pytest.raises(IntegrityError) as caught:
        await db_session.flush()
    assert "ck_alert_inspection_tasks_non_empty" in str(caught.value)


async def test_alert_with_one_inspection_task_is_accepted(db_session) -> None:
    """The control. A constraint that rejects everything is not a constraint."""
    farm = await _farm(db_session)
    db_session.add(_alert(farm, inspection_tasks=["Check ten plants along the bund today."]))
    await db_session.flush()


# --- new in Phase 3: daily uniqueness ---------------------------------------


async def test_second_same_day_alert_for_the_same_target_is_rejected(db_session) -> None:
    """Migration 0004. This is what makes the scheduled risk job idempotent.

    A Python "have I already issued this?" check would still let two concurrent
    runs both see no alert and both insert.
    """
    farm = await _farm(db_session)
    db_session.add(_alert(farm))
    await db_session.flush()

    db_session.add(_alert(farm))
    with pytest.raises(IntegrityError) as caught:
        await db_session.flush()
    assert "uq_alert_farm_target_day" in str(caught.value)


async def test_a_different_target_on_the_same_day_is_accepted(db_session) -> None:
    """The constraint is per target, not per farm. Blast and stem borer can both
    be live on one field on one day."""
    farm = await _farm(db_session)
    db_session.add(_alert(farm, target=TargetLabel.PADDY_BLAST))
    await db_session.flush()
    db_session.add(_alert(farm, target=TargetLabel.PADDY_BROWN_SPOT))
    await db_session.flush()


async def test_the_same_target_on_a_different_day_is_accepted(db_session) -> None:
    """The constraint is per day, not forever. If autogenerate's version had
    shipped — a plain unique index on (farm_id, target) — this would fail, and
    a farm would never be alerted about blast twice in a season."""
    farm = await _farm(db_session)
    db_session.add(_alert(farm, issued_at=datetime.now(UTC) - timedelta(days=1)))
    await db_session.flush()
    db_session.add(_alert(farm, issued_at=datetime.now(UTC)))
    await db_session.flush()
