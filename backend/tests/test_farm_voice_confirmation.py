"""The read-back guarantee, made structural. docs/API_CONTRACT.md §5, PRD F9.

A voice-derived crop or growth stage must be read back and confirmed before
it saves. FarmCreate/FarmUpdate refuse the whole write when input_source is
"voice" and confirmed is not exactly true -- tested directly against the
pydantic models, no DB or HTTP needed, since the refusal happens at request
parsing before either is touched.
"""

from __future__ import annotations

from datetime import date

import pytest
from pydantic import ValidationError

from app.contracts.farm import GeoPoint
from app.core.schemas.farms import FarmCreate, FarmUpdate

_LOCATION = GeoPoint(lat=19.9975, lng=73.7898)


def test_typed_input_needs_no_confirmation() -> None:
    """The default, unaffected by this change."""
    farm = FarmCreate(growth_stage="tillering", region="Nashik", location=_LOCATION)
    assert farm.input_source == "typed"
    assert farm.confirmed is False


def test_voice_input_without_confirmation_is_refused() -> None:
    with pytest.raises(ValidationError, match="confirmed"):
        FarmCreate(
            growth_stage="tillering",
            region="Nashik",
            location=_LOCATION,
            input_source="voice",
        )


def test_voice_input_with_confirmed_false_is_refused() -> None:
    with pytest.raises(ValidationError, match="confirmed"):
        FarmCreate(
            growth_stage="tillering",
            region="Nashik",
            location=_LOCATION,
            input_source="voice",
            confirmed=False,
        )


def test_voice_input_with_confirmed_true_is_accepted() -> None:
    farm = FarmCreate(
        growth_stage="tillering",
        region="Nashik",
        location=_LOCATION,
        input_source="voice",
        confirmed=True,
    )
    assert farm.input_source == "voice"
    assert farm.confirmed is True


def test_confirmed_true_with_typed_input_is_accepted_and_ignored() -> None:
    """confirmed only gates something when input_source is voice -- a typed
    request sending confirmed=true (a client being extra-careful) is not an
    error, since there is no voice-derived value it could apply to."""
    farm = FarmCreate(
        growth_stage="tillering", region="Nashik", location=_LOCATION, confirmed=True
    )
    assert farm.input_source == "typed"


def test_farm_update_enforces_the_same_rule() -> None:
    with pytest.raises(ValidationError, match="confirmed"):
        FarmUpdate(growth_stage="flowering", input_source="voice")

    update = FarmUpdate(growth_stage="flowering", input_source="voice", confirmed=True)
    assert update.growth_stage == "flowering"


def test_input_source_and_confirmed_are_not_farm_columns() -> None:
    """Neither field is a persisted attribute -- the guarantee lives at the
    write boundary, not as stored state. See VOICE_CONFIRMATION_FIELDS and
    the router's exclusion of it from the PATCH setattr loop."""
    from app.core.models import Farm

    assert not hasattr(Farm, "input_source")
    assert not hasattr(Farm, "confirmed")


def test_farm_update_excludes_voice_fields_from_setattr_dump() -> None:
    """The router dumps FarmUpdate with VOICE_CONFIRMATION_FIELDS excluded
    before iterating setattr -- confirm the dump this depends on actually
    drops both fields, even when the client explicitly sent them."""
    from app.core.schemas.farms import VOICE_CONFIRMATION_FIELDS

    update = FarmUpdate(
        growth_stage="flowering",
        sowing_date=date(2026, 6, 1),
        input_source="voice",
        confirmed=True,
    )
    dumped = update.model_dump(exclude_unset=True, exclude=VOICE_CONFIRMATION_FIELDS)
    assert "input_source" not in dumped
    assert "confirmed" not in dumped
    assert dumped == {"growth_stage": "flowering", "sowing_date": date(2026, 6, 1)}
