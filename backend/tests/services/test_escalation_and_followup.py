"""F10 follow-up and F12 escalation, at the database.

The bundle-is-NULL test is the one that matters. docs/API_CONTRACT.md §12 says a
case bundle carries no placeholder data, and "not compiled yet" has to be
distinguishable from "compiled and empty". SQLAlchemy's JSON default silently
broke that once already — see migration 0005.
"""

from __future__ import annotations

import uuid

import pytest
from sqlalchemy import text

from app.contracts.enums import (
    Crop,
    FollowupResponse,
    ProblemSeverity,
    ProblemType,
    Role,
    TargetLabel,
)
from app.core.models import Farm, FollowUp, Problem, User
from app.core.services.escalation import escalate
from app.core.services.followup import promote, record_response, schedule_for


async def _problem(session, severity=ProblemSeverity.EARLY) -> Problem:
    farmer = User(role=Role.FARMER, phone=f"+9198{uuid.uuid4().int % 10**9:09d}", name="probe")
    session.add(farmer)
    await session.flush()
    farm = Farm(
        farmer_id=farmer.id, crop=Crop.PADDY, growth_stage="tillering",
        region="Nashik", location="SRID=4326;POINT(73.7898 19.9975)",
    )
    session.add(farm)
    await session.flush()
    problem = Problem(
        farm_id=farm.id, problem_type=ProblemType.DISEASE,
        label=TargetLabel.PADDY_BLAST, severity=severity,
    )
    session.add(problem)
    await session.flush()
    return problem


# --- the one that regressed -------------------------------------------------


async def test_escalation_leaves_bundle_as_sql_null_not_json_null(db_session) -> None:
    """Not `bundle == None` in Python — that is true for JSONB 'null' too.

    Asserted in SQL, because the bug was that Python None round-tripped as the
    JSON value `null`, leaving the column NOT NULL and making `bundle IS NULL`
    false for every uncompiled case.
    """
    problem = await _problem(db_session)
    case = await escalate(db_session, problem.id)
    await db_session.flush()

    row = (
        await db_session.execute(
            text(
                "select bundle is null as sql_null, "
                "coalesce(bundle = 'null'::jsonb, false) as json_null "
                'from "case" where id = :id'
            ).bindparams(id=case.id)
        )
    ).one()
    assert row.sql_null is True, "bundle must be SQL NULL until F12 compiles it"
    assert row.json_null is False, "bundle must not be the JSON value null"


async def test_escalation_populates_queue_position_and_eta(db_session) -> None:
    problem = await _problem(db_session)
    case = await escalate(db_session, problem.id)
    assert case.queue_position >= 1
    assert case.eta_minutes == case.queue_position * 15


async def test_escalating_twice_returns_the_same_case(db_session) -> None:
    """A farmer answering got_worse twice must not put two cases for one field
    into an agronomist's queue."""
    problem = await _problem(db_session)
    first = await escalate(db_session, problem.id)
    second = await escalate(db_session, problem.id)
    assert first.id == second.id


# --- severity promotion -----------------------------------------------------


@pytest.mark.parametrize(
    ("start", "expected"),
    [
        (ProblemSeverity.EARLY, ProblemSeverity.MODERATE),
        (ProblemSeverity.MODERATE, ProblemSeverity.SEVERE),
        (ProblemSeverity.SEVERE, ProblemSeverity.SEVERE),
        (None, ProblemSeverity.MODERATE),
    ],
)
def test_promote_steps_once_and_saturates(start, expected) -> None:
    assert promote(start) == expected


async def test_got_worse_promotes_and_escalates(db_session) -> None:
    problem = await _problem(db_session)
    follow_up = await schedule_for(db_session, problem.id)

    _, was, now, case_id = await record_response(
        db_session, follow_up, FollowupResponse.GOT_WORSE
    )
    assert (was, now) == (ProblemSeverity.EARLY, ProblemSeverity.MODERATE)
    assert case_id is not None


@pytest.mark.parametrize("answer", [FollowupResponse.IMPROVED, FollowupResponse.NO_CHANGE])
async def test_other_answers_do_not_escalate_or_resolve(db_session, answer) -> None:
    """An `improved` answer is the farmer's word, not a diagnosis. Closing the
    problem here would remove it from the case file an agronomist reads."""
    problem = await _problem(db_session)
    follow_up = await schedule_for(db_session, problem.id)

    updated, was, now, case_id = await record_response(db_session, follow_up, answer)
    assert case_id is None
    assert was == now == ProblemSeverity.EARLY
    assert updated.status.value == "open"


# --- scheduling -------------------------------------------------------------


async def test_schedule_for_does_not_double_book(db_session) -> None:
    """Two pending check-ins for one problem would ask the farmer the same
    question twice and count twice in the home screen total."""
    problem = await _problem(db_session)
    first = await schedule_for(db_session, problem.id)
    second = await schedule_for(db_session, problem.id)
    assert first is not None
    assert second is None


async def test_schedule_for_uses_the_configured_interval(db_session) -> None:
    from app.config import FOLLOWUP_DUE_DAYS

    problem = await _problem(db_session)
    follow_up = await schedule_for(db_session, problem.id)
    assert isinstance(follow_up, FollowUp)
    assert (follow_up.due_at - problem.opened_at).days in (
        FOLLOWUP_DUE_DAYS - 1,
        FOLLOWUP_DUE_DAYS,
    )
