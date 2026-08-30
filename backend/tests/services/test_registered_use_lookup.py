"""F8 lookup service. docs/DESIGN.md §9.

The property under test is the one that keeps a wrong verdict off a farmer's
field: the lookup must MISS on anything it is not certain about. Every "does not
match" case here is a case where returning a row would produce a confident
pesticide verdict for a product the system never actually identified.
"""

from __future__ import annotations

from datetime import date

import pytest

from app.core.models import RegisteredUse
from app.core.services.registered_use import lookup, normalise_ingredient


async def _insert(session, **overrides) -> RegisteredUse:
    row = RegisteredUse(
        active_ingredient=overrides.pop("active_ingredient", "carbendazim"),
        crop=overrides.pop("crop", "paddy"),
        target=overrides.pop("target", "blast"),
        pesticide_class=overrides.pop("pesticide_class", "fungicide"),
        dosage_text=overrides.pop("dosage_text", "0.6 g per litre"),
        phi_days=overrides.pop("phi_days", 30),
        reentry_hours=overrides.pop("reentry_hours", 24),
        source=overrides.pop("source", "CIB&RC label"),
        last_verified=overrides.pop("last_verified", date(2026, 1, 15)),
        **overrides,
    )
    session.add(row)
    await session.flush()
    return row


# --- the empty table: the current live state --------------------------------


async def test_empty_table_returns_empty_list_not_an_error(db_session) -> None:
    """registered_use has no rows today. That is a valid state — every check
    returns NOT_IN_RECORDS, which docs/PRD.md §9 accepts as an honest verdict.
    It must not raise."""
    assert await lookup(db_session, "carbendazim", "paddy") == []


# --- matching ---------------------------------------------------------------


async def test_exact_hit(db_session) -> None:
    await _insert(db_session)
    rows = await lookup(db_session, "carbendazim", "paddy")
    assert len(rows) == 1
    assert rows[0].active_ingredient == "carbendazim"
    assert rows[0].pesticide_class == "fungicide"
    assert rows[0].phi_days == 30


async def test_case_difference_still_matches(db_session) -> None:
    await _insert(db_session)
    assert len(await lookup(db_session, "CARBENDAZIM", "paddy")) == 1
    assert len(await lookup(db_session, "Carbendazim", "paddy")) == 1


async def test_surrounding_whitespace_still_matches(db_session) -> None:
    """OCR routinely returns padded strings."""
    await _insert(db_session)
    assert len(await lookup(db_session, "  carbendazim \n", "paddy")) == 1


async def test_unknown_ingredient_misses(db_session) -> None:
    await _insert(db_session)
    assert await lookup(db_session, "glyphosate", "paddy") == []


async def test_known_ingredient_unknown_crop_misses(db_session) -> None:
    """`crop` is a native Postgres enum, so an out-of-set value would be a type
    error rather than a miss if it reached SQL. It is filtered in Python."""
    await _insert(db_session)
    assert await lookup(db_session, "carbendazim", "cotton") == []
    assert await lookup(db_session, "carbendazim", "not-a-crop") == []


async def test_blank_ingredient_misses(db_session) -> None:
    await _insert(db_session)
    assert await lookup(db_session, "   ", "paddy") == []
    assert await lookup(db_session, "", "paddy") == []


# --- the property that matters ----------------------------------------------


@pytest.mark.parametrize(
    "typo",
    [
        "carbendazirn",  # rn read as m — the classic OCR confusion
        "carbendazi",
        "carbendazims",
        "carben dazim",
        "karbendazim",
    ],
)
async def test_near_misses_do_not_resolve(db_session, typo: str) -> None:
    """No fuzzy matching, no stemming, no edit distance.

    Each of these must produce NOT_IN_RECORDS ("Ask an expert before using it")
    rather than a confident class and PHI verdict for a product that was never
    actually identified. docs/DESIGN.md §9.
    """
    await _insert(db_session)
    assert await lookup(db_session, typo, "paddy") == [], (
        f"{typo!r} resolved to a real row — a fuzzy match here ships a pesticide "
        "verdict for an unidentified product"
    )


async def test_returns_every_target_for_the_ingredient(db_session) -> None:
    """The verdict logic needs the full set to tell NOT_IN_RECORDS (no rows at
    all) from NOT_REGISTERED_FOR_TARGET (rows exist, none for this target).
    Filtering by target in SQL would collapse the two."""
    await _insert(db_session, target="blast")
    await _insert(db_session, target="brown_spot")

    rows = await lookup(db_session, "carbendazim", "paddy")
    assert {r.target for r in rows} == {"blast", "brown_spot"}


async def test_row_is_detached_from_the_orm(db_session) -> None:
    """intelligence/ never touches the database — docs/DESIGN.md §3. Handing it
    a live ORM instance would pass a lazy-loading session handle across exactly
    the boundary that rule closes."""
    await _insert(db_session)
    row = (await lookup(db_session, "carbendazim", "paddy"))[0]
    assert not isinstance(row, RegisteredUse)
    # Frozen slots dataclass: no __dict__, so no session handle and no extra
    # state can be attached to it downstream.
    assert not hasattr(row, "__dict__")
    with pytest.raises((AttributeError, TypeError)):
        row.smuggled_session = object()


# --- normalisation is the whole transformation ------------------------------


def test_normalise_only_trims_and_folds() -> None:
    assert normalise_ingredient("  Carbendazim ") == "carbendazim"
    assert normalise_ingredient("MANCOZEB") == "mancozeb"
    # Not collapsed, not de-spaced, not stripped of punctuation.
    assert normalise_ingredient("carben dazim") == "carben dazim"
    assert normalise_ingredient("2,4-D") == "2,4-d"
