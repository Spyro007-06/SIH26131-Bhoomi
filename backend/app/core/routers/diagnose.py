"""F2 the confidence gate, F3 image-based identification.

OWNER: Thaariha + Suchit; orchestration by Shreekumar

Serves:
    POST /farms/{id}/diagnose -- the orchestration (this file): load farm
        context, classify, apply the prior, call app.intelligence.gate.decide()
        (owner Thaariha, unmodified here), and branch. Two of the gate's three
        branches produce a real, complete response (escalate; clarify with no
        matching cue, which is the only clarify path reachable while
        DistinguishingCue is empty). advise, and clarify with a cue actually
        found, are real reachable states this build does not compose a
        response for -- 501 NOT_IMPLEMENTED, not a bug: F7's advisory
        composer and F4's Doubt Doctor question flow are Thaariha's and are
        not built here. See _resolve_topk() and diagnose_farm() below.

    POST /vision/classify -- Phase 1 exception, vision fixture / test mode
        (owner Suchit). Returns contract C1 (TopK) unmodified and untouched
        by any gate logic, so any caller can drive all three gate bands by
        header. diagnose_farm() below reads the SAME header through the same
        _resolve_topk() this endpoint uses -- one fixture resolution, not two
        copies of the dict that could drift apart.

Specified by: docs/API_CONTRACT.md §6, docs/DESIGN.md §6, §7.
"""

from __future__ import annotations

import uuid

from fastapi import APIRouter, Depends, Header
from sqlalchemy import ARRAY, Text, cast, select
from sqlalchemy.dialects.postgresql import array as pg_array
from sqlalchemy.ext.asyncio import AsyncSession

from app.config import settings
from app.contracts.enums import GateOutcome, GateReasonCode, ProblemStatus, TargetLabel
from app.contracts.vision import Prediction, TopK
from app.core.models import Case, Diagnosis, DistinguishingCue, Farm, Problem, User
from app.core.schemas.diagnose import DiagnoseIn, DiagnoseOut, EscalationOut, GateOut
from app.core.services import prior as prior_service
from app.core.services.alerts import TARGET_PROBLEM_TYPES
from app.core.services.escalation import escalate
from app.db import get_session
from app.deps import Principal, current_principal
from app.errors import (
    BhoomiError,
    ErrorCode,
    FixturesDisabled,
    Forbidden,
    NotFound,
    ValidationFailed,
    error_response,
)
from app.intelligence.gate import decide

# _stub_topk, not classify(): the no-header path must return the stub without
# handing invented bytes to a classifier. Reaching into Suchit's module for the
# private builder keeps one definition of the stub distribution; assembling a
# second copy of it here is the thing that drifts.
from app.vision.classifier import STUB_MODEL_VERSION, _stub_topk

router = APIRouter(tags=["diagnose"])

# Fixture presets, Phase 1 vision test mode. Fixed values only -- never derived
# from the uploaded image (docs/DESIGN.md §12: a stub must not produce
# input-dependent output that looks like a real prediction).
#
# Two properties hold for every entry, and both are asserted in
# tests/routers/test_diagnose.py rather than trusted here:
#
#   Every label is in TargetLabel, the bounded five-class set. These predictions
#   reach the client as gate.alternatives, where Tharun renders each label
#   against reference data -- a label from outside the set has none.
#
#   Every distribution sums to 1.0, because that is what a softmax over the
#   bounded set returns. Out-of-scope is the `out_of_scope` flag plus a flat,
#   low distribution; it is never a label borrowed from another crop.
#
# Band comments below name the config constant and not its value: a number
# written into a comment cannot be checked by anything and is believed anyway.
_FIXTURES: dict[str, TopK] = {
    "confident": TopK(  # advise band: top-1 at or above GATE, clear by MARGIN
        predictions=[
            Prediction(label="paddy_blast", confidence=0.85),
            Prediction(label="paddy_brown_spot", confidence=0.10),
            Prediction(label="paddy_bacterial_leaf_blight", confidence=0.05),
        ],
        out_of_scope=False,
        model_version=STUB_MODEL_VERSION,
        is_stub=True,
    ),
    "torn": TopK(  # Doubt Doctor band: blast vs brown_spot, both above FLOOR,
        # gap under MARGIN
        predictions=[
            Prediction(label="paddy_blast", confidence=0.50),
            Prediction(label="paddy_brown_spot", confidence=0.46),
            Prediction(label="paddy_bacterial_leaf_blight", confidence=0.04),
        ],
        out_of_scope=False,
        model_version=STUB_MODEL_VERSION,
        is_stub=True,
    ),
    "low_confidence": TopK(  # escalate band: top-1 below FLOOR
        predictions=[
            Prediction(label="paddy_blast", confidence=0.38),
            Prediction(label="paddy_brown_spot", confidence=0.33),
            Prediction(label="paddy_bacterial_leaf_blight", confidence=0.29),
        ],
        out_of_scope=False,
        model_version=STUB_MODEL_VERSION,
        is_stub=True,
    ),
    "out_of_scope": TopK(  # nothing in the bounded set fits: flat, low, flag set
        predictions=[
            Prediction(label="paddy_blast", confidence=0.36),
            Prediction(label="paddy_brown_spot", confidence=0.33),
            Prediction(label="paddy_bacterial_leaf_blight", confidence=0.31),
        ],
        out_of_scope=True,
        model_version=STUB_MODEL_VERSION,
        is_stub=True,
    ),
}


def _resolve_topk(x_vision_fixture: str | None) -> TopK:
    """Return a fixture TopK selected by the X-Vision-Fixture header.

    No header returns the inert stub distribution, unchanged, in every mode.
    That is the one path here that does not name a fixture.

    A fixture name is refused with FIXTURES_DISABLED when VISION_MODEL=real.
    Not FORBIDDEN: the caller's identity is irrelevant to it. On a machine with
    the model loaded, a stray header left in a client must not quietly stand in
    for inference -- that is a silent stub by another route (docs/DESIGN.md §12).

    An unrecognised name is a 422 rather than a fall-through. Falling through
    handed back the stub's near-uniform distribution, which reads as a broken
    gate rather than as a typo in the header.

    Shared by classify_vision_fixture() and diagnose_farm() -- one fixture
    resolution for both, so they cannot drift apart.
    """
    if x_vision_fixture is None:
        return _stub_topk()

    if settings.vision_model == "real":
        raise FixturesDisabled(
            "Vision fixtures are not served when VISION_MODEL=real. Drop the "
            "X-Vision-Fixture header, or run with VISION_MODEL=stub.",
            details={"vision_model": settings.vision_model},
        )

    if x_vision_fixture not in _FIXTURES:
        raise ValidationFailed(
            f"Unknown X-Vision-Fixture value {x_vision_fixture!r}.",
            details={"known_fixtures": sorted(_FIXTURES)},
        )

    return _FIXTURES[x_vision_fixture]


@router.post(
    "/vision/classify",
    response_model=TopK,
    responses={
        **error_response(
            409,
            "An X-Vision-Fixture header was sent while VISION_MODEL=real -- "
            "fixtures are not served against the real classifier.",
        ),
        **error_response(422, "X-Vision-Fixture named an unrecognised fixture."),
    },
)
async def classify_vision_fixture(
    x_vision_fixture: str | None = Header(default=None),
) -> TopK:
    """Phase 1 vision fixture / test mode. See _resolve_topk()."""
    return _resolve_topk(x_vision_fixture)


# ===========================================================================
# POST /farms/{id}/diagnose -- the orchestration
# ===========================================================================


async def _load_owned_farm(farm_id: uuid.UUID, principal: Principal, session: AsyncSession) -> Farm:
    """Same ownership rule as farms.py and alerts.py's local copies: a farmer
    sees only their own farm, agronomists and officials see any farm."""
    farm = await session.get(Farm, farm_id)
    if farm is None:
        raise NotFound("That farm does not exist.")
    if principal.role == "farmer" and farm.farmer_id != principal.subject:
        raise Forbidden("That farm belongs to a different account.")
    return farm


async def _upsert_open_problem(
    session: AsyncSession, farm_id: uuid.UUID, label: TargetLabel
) -> Problem:
    """Reuse the open Problem for this farm+label if one exists, rather than
    creating a duplicate on every diagnose call against the same suspected
    issue. A different label (a genuinely different problem on the same
    farm) still gets its own row -- scoped per label, not per farm."""
    existing = (
        await session.execute(
            select(Problem).where(
                Problem.farm_id == farm_id,
                Problem.label == label,
                Problem.status == ProblemStatus.OPEN,
            )
        )
    ).scalar_one_or_none()
    if existing is not None:
        return existing

    problem = Problem(
        farm_id=farm_id, problem_type=TARGET_PROBLEM_TYPES[label], label=label
    )
    session.add(problem)
    await session.flush()
    return problem


async def _find_discriminating_cue(
    session: AsyncSession, label_a: str, label_b: str
) -> DistinguishingCue | None:
    """docs/DESIGN.md §7: a cue whose `discriminates` pair is exactly
    {label_a, label_b}, order-independent. `@>` (Postgres array-contains):
    the left array contains every element of the right one; combined with
    the DB CHECK that `discriminates` is always exactly 2 elements, containing
    both labels is sufficient to guarantee an exact-set match -- no third
    label can be present. Built with `.op("@>")` against a real Postgres
    ARRAY literal rather than the ORM's `.contains()`: `discriminates` is
    typed as the dialect-generic `ARRAY(Text)` (docs/DESIGN.md §5's model),
    and the generic type's `.contains()` raises NotImplementedError -- it
    only supports the dialect-specific `postgresql.ARRAY` type, which the
    frozen model does not use. The literal is explicitly cast to `text[]`:
    left uninferred, asyncpg binds Python strings as `varchar[]`, and
    Postgres has no `text[] @> varchar[]` operator -- "operator does not
    exist," not a permission or logic error."""
    needle = cast(pg_array([label_a, label_b]), ARRAY(Text))
    stmt = select(DistinguishingCue).where(DistinguishingCue.discriminates.op("@>")(needle))
    return (await session.execute(stmt)).scalars().first()


def _agronomist_slug(user: User) -> str:
    """"agronomist:kvk_nashik"-style display string for Case.assigned_to --
    docs/API_CONTRACT.md §12/§13's rendered form of a real FK row (see
    Case.assigned_to's docstring). No dedicated organisation/KVK column
    exists on User, so this derives from the email domain -- the only
    crafted example available is seed/farms.py's
    agronomist@kvk-nashik.example -> "agronomist:kvk_nashik". Revisit if a
    real KVK/organisation field is ever added to User."""
    if not user.email:
        return f"agronomist:{user.id}"
    domain = user.email.split("@", 1)[-1]
    slug = domain.split(".", 1)[0].replace("-", "_")
    return f"agronomist:{slug}"


async def _escalation_out(session: AsyncSession, case: Case) -> EscalationOut:
    assigned_to = None
    if case.assigned_to is not None:
        agronomist = await session.get(User, case.assigned_to)
        if agronomist is not None:
            assigned_to = _agronomist_slug(agronomist)
    return EscalationOut(
        case_id=case.id,
        assigned_to=assigned_to,
        queue_position=case.queue_position,
        eta_minutes=case.eta_minutes,
    )


@router.post(
    "/farms/{farm_id}/diagnose",
    response_model=DiagnoseOut,
    response_model_exclude_none=True,
    responses={
        **error_response(401, "No, or an invalid, bearer token."),
        **error_response(404, "That farm does not exist."),
        **error_response(
            403, "The caller is a farmer and that farm belongs to a different account."
        ),
        **error_response(
            409,
            "An X-Vision-Fixture header was sent while VISION_MODEL=real -- "
            "fixtures are not served against the real classifier.",
        ),
        **error_response(
            422,
            "The request body did not parse, or X-Vision-Fixture named an "
            "unrecognised fixture.",
        ),
        # THE important one. Both are real, reachable gate outcomes today,
        # not hypothetical future states: `advise` is reached by every
        # confident, in-scope, unambiguous prediction (gate.decide() is
        # still the Phase 2 implementation and does not consult
        # retrieval_score, so a corpus existing would not currently change
        # this); `clarify` reaches it the moment DistinguishingCue holds a
        # cue for the predicted pair. Composing the advisory (F7) and
        # rendering the Doubt Doctor question (F4) are Thaariha's and are
        # not built in this orchestration.
        **error_response(
            501,
            "The gate reached an outcome this orchestration does not compose "
            "a response for: 'advise' (F7's advisory composer is not built -- "
            "details.reason_code names the gate reason, e.g. ABOVE_GATE), or "
            "'clarify' with a matching DistinguishingCue found (F4's Doubt "
            "Doctor question rendering is not built -- details.cue_id names "
            "the matched cue). The two are distinguishable by which details "
            "key is present.",
        ),
    },
)
async def diagnose_farm(
    farm_id: uuid.UUID,
    payload: DiagnoseIn,
    x_vision_fixture: str | None = Header(default=None),
    principal: Principal = Depends(current_principal),
    session: AsyncSession = Depends(get_session),
) -> DiagnoseOut:
    """The gated diagnose path. docs/API_CONTRACT.md §6, docs/DESIGN.md §6, §7.

    escalate and clarify-with-no-cue-found are the only branches this build
    produces a full response for. advise, and clarify-with-a-cue-found, are
    real reachable gate outcomes this build refuses rather than fabricates a
    response for -- 501 NOT_IMPLEMENTED. See the module docstring.

    The Problem and Diagnosis rows are written regardless of which branch is
    reached, including the two 501 branches: a real classification event
    happened and is recorded before the response is decided, not only when
    this build knows how to finish answering it.
    """
    farm = await _load_owned_farm(farm_id, principal, session)

    topk = _resolve_topk(x_vision_fixture)

    biases = {
        prediction.label: await prior_service.bias_for(
            session, farm.region, farm.crop.value, farm.growth_stage, prediction.label
        )
        for prediction in topk.predictions
    }
    topk = prior_service.apply(topk, biases)

    # The corpus has zero loaded rows -- every delivered row was refused on
    # source_dated (seed/corpus/SOURCES_NEEDED.md). retrieval_score is
    # honestly None, not a value invented to make the advise branch reachable.
    retrieval_score: float | None = None

    decision = decide(topk, retrieval_score)

    top1 = topk.predictions[0]
    target_label = TargetLabel(top1.label)
    problem = await _upsert_open_problem(session, farm.id, target_label)

    session.add(
        Diagnosis(
            problem_id=problem.id,
            image_asset_id=payload.image_asset_id,
            topk=topk.model_dump(),
            gate_outcome=GateOutcome(decision.outcome),
            gate_confidence=decision.confidence,
            reason_code=GateReasonCode(decision.reason_code),
            model_version=topk.model_version,
            is_stub=topk.is_stub,
        )
    )
    await session.flush()

    if decision.outcome == "escalate":
        case = await escalate(session, problem.id, reason=f"gate: {decision.reason_code}")
        await session.commit()
        return DiagnoseOut(
            gate=GateOut(
                outcome=decision.outcome,
                confidence=decision.confidence,
                threshold_applied=decision.threshold_applied,
                reason_code=decision.reason_code,
                alternatives=decision.alternatives,
                is_stub=topk.is_stub,
            ),
            problem_id=problem.id,
            problem_type=problem.problem_type,
            escalation=await _escalation_out(session, case),
        )

    if decision.outcome == "clarify":
        top2 = topk.predictions[1]
        cue = await _find_discriminating_cue(session, top1.label, top2.label)
        if cue is None:
            # docs/DESIGN.md §7: "not found -> escalate". reason_code stays
            # AMBIGUOUS -- honest about why this escalated -- while outcome
            # reports what actually happened, so the response still satisfies
            # "outcome determines which field is present" (escalation, not a
            # half-built clarification with no question to ask).
            case = await escalate(
                session, problem.id, reason="clarify: no discriminating cue found"
            )
            await session.commit()
            return DiagnoseOut(
                gate=GateOut(
                    outcome="escalate",
                    confidence=decision.confidence,
                    threshold_applied=decision.threshold_applied,
                    reason_code=decision.reason_code,
                    alternatives=decision.alternatives,
                    is_stub=topk.is_stub,
                ),
                problem_id=problem.id,
                problem_type=problem.problem_type,
                escalation=await _escalation_out(session, case),
            )

        await session.commit()
        raise BhoomiError(
            ErrorCode.NOT_IMPLEMENTED,
            "A discriminating cue exists for this pair, but rendering the "
            "Doubt Doctor question is not built in this orchestration.",
            details={"cue_id": str(cue.id)},
        )

    # advise: unreachable while the corpus is empty under the intended
    # design (decide() should refuse for NO_RELEVANT_SOURCE first) -- reached
    # here only because the deployed gate.decide() is still the Phase 2
    # implementation and does not consult retrieval_score at all. Refused
    # regardless of why it was reached: composing an advisory is F7's, not
    # built here.
    await session.commit()
    raise BhoomiError(
        ErrorCode.NOT_IMPLEMENTED,
        "The gate reached 'advise', but composing an advisory is not built "
        "in this orchestration.",
        details={"reason_code": decision.reason_code},
    )
