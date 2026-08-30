"""F14 - the capped confirmation prior.

OWNER: Shreekumar

prior[region][crop][stage][label] as a count-based nudge, applied as a small
additive bias to the vision output before the gate.

Specified by: docs/DESIGN.md §11.

-----------------------------------------------------------------------------
This is "learns from field confirmations". It is NOT training.

The arithmetic is deliberately something you can read off a screen:

    net   = max(confirmed_count - corrected_count, 0)
    bias  = min(net, PRIOR_FULL_CONFIDENCE_COUNT) / PRIOR_FULL_CONFIDENCE_COUNT
            * PRIOR_MAX_BIAS

Ten net confirmations for a (region, crop, stage, label) earns the full nudge;
five earns half; a label corrected as often as it is confirmed earns nothing.
No smoothing scheme, no decay curve — docs/DESIGN.md §11 warns that calling this
learning invites a question with no good answer on stage, and the defence is
that the whole rule fits on one line.

-----------------------------------------------------------------------------
THE CAP IS NOT SUFFICIENT ON ITS OWN. This surprised me; here is the detail.

app/config.py asserts PRIOR_MAX_BIAS < MARGIN and PRIOR_MAX_BIAS < (GATE-FLOOR).
Those two facts are necessary but they do NOT guarantee the outcome is
unchanged, because the gate checks the floor BEFORE it checks ambiguity
(docs/DESIGN.md §6):

    top1 = 0.42, top2 = 0.40      ->  top1 < FLOOR       -> escalate
    apply the maximum bias 0.05   ->  top1 = 0.47
    0.47 >= FLOOR, gap 0.07 < MARGIN                     -> clarify

A band was crossed, escalate -> clarify, using a bias inside its cap. The
prediction became engageable because of history rather than evidence, which is
exactly what §11 forbids.

So `apply()` clamps the bias to preserve every outcome-relevant predicate:
which side of FLOOR top-1 sits on, which side of GATE it sits on, and which side
of MARGIN the gap sits on. The result is that the invariant holds by
construction rather than by an arithmetic coincidence between three constants
that someone might later tune independently.
-----------------------------------------------------------------------------
"""

from __future__ import annotations

from datetime import UTC, datetime

from sqlalchemy import select
from sqlalchemy.dialects.postgresql import insert
from sqlalchemy.ext.asyncio import AsyncSession

from app.config import FLOOR, GATE, MARGIN, PRIOR_FULL_CONFIDENCE_COUNT, PRIOR_MAX_BIAS
from app.contracts.vision import Prediction, TopK
from app.core.models import LabelPrior

# A hair under a threshold, used when clamping so a value that was strictly
# below stays strictly below. Smaller than any confidence the models emit.
EPSILON = 1e-9


# ===========================================================================
# Write side
# ===========================================================================


async def _increment(
    session: AsyncSession,
    region: str,
    crop: str,
    growth_stage: str,
    label: str,
    *,
    confirmed: int = 0,
    corrected: int = 0,
) -> None:
    """Upsert one counter pair. The composite PK is the four dimensions."""
    statement = insert(LabelPrior.__table__).values(
        region=region,
        crop=crop,
        growth_stage=growth_stage,
        label=label,
        confirmed_count=confirmed,
        corrected_count=corrected,
        updated_at=datetime.now(UTC),
    )
    await session.execute(
        statement.on_conflict_do_update(
            index_elements=["region", "crop", "growth_stage", "label"],
            set_={
                "confirmed_count": LabelPrior.__table__.c.confirmed_count + confirmed,
                "corrected_count": LabelPrior.__table__.c.corrected_count + corrected,
                "updated_at": datetime.now(UTC),
            },
        )
    )


async def record_confirmation(
    session: AsyncSession,
    region: str,
    crop: str,
    growth_stage: str,
    model_label: str | None,
    corrected_label: str | None = None,
) -> None:
    """Move the counters for one agronomist verdict.

    On a correction BOTH counters move, on different rows: the model's label was
    wrong (corrected_count) and the corrected label was right (confirmed_count).
    Recording only one of those would make the F15 accuracy view wrong in a way
    that flatters the model — a corrected prediction would simply vanish rather
    than counting against it.
    """
    if corrected_label is None:
        if model_label is not None:
            await _increment(
                session, region, crop, growth_stage, model_label, confirmed=1
            )
        return

    if model_label is not None:
        await _increment(session, region, crop, growth_stage, model_label, corrected=1)
    await _increment(session, region, crop, growth_stage, corrected_label, confirmed=1)


# ===========================================================================
# Read side
# ===========================================================================


def bias_from_counts(confirmed: int, corrected: int) -> float:
    """The count-based nudge, before any gate-preserving clamp."""
    net = max(confirmed - corrected, 0)
    if net <= 0:
        return 0.0
    fraction = min(net, PRIOR_FULL_CONFIDENCE_COUNT) / PRIOR_FULL_CONFIDENCE_COUNT
    return round(fraction * PRIOR_MAX_BIAS, 6)


async def bias_for(
    session: AsyncSession, region: str, crop: str, growth_stage: str, label: str
) -> float:
    """Bias for one label in one place at one stage. Zero when unknown."""
    row = (
        await session.execute(
            select(LabelPrior).where(
                LabelPrior.region == region,
                LabelPrior.crop == crop,
                LabelPrior.growth_stage == growth_stage,
                LabelPrior.label == label,
            )
        )
    ).scalar_one_or_none()
    if row is None:
        return 0.0
    return bias_from_counts(row.confirmed_count, row.corrected_count)


def _clamped(top1: float, top2: float, raw_bias: float) -> float:
    """Largest bias <= raw_bias that leaves every gate predicate unchanged.

    The three predicates the gate reads, in its order (docs/DESIGN.md §6):
        top1 < FLOOR
        top1 - top2 < MARGIN
        top1 < GATE
    """
    if raw_bias <= 0:
        return 0.0

    ceilings: list[float] = []

    # Stay on the same side of FLOOR.
    if top1 < FLOOR:
        ceilings.append(FLOOR - EPSILON - top1)
    # Stay on the same side of GATE.
    if top1 < GATE:
        ceilings.append(GATE - EPSILON - top1)
    # Stay on the same side of MARGIN. Raising top-1 only widens the gap, so
    # only a gap that starts below MARGIN can cross.
    if (top1 - top2) < MARGIN:
        ceilings.append(MARGIN - EPSILON - (top1 - top2))

    allowed = min([raw_bias, *ceilings]) if ceilings else raw_bias
    return max(0.0, allowed)


def apply(
    topk: TopK, biases: dict[str, float], *, clamp: bool = True
) -> TopK:
    """Return a TopK with the prior applied to top-1.

    NO CALLER YET. The diagnose orchestration that would sit between the
    classifier and the gate is F2/F3 and belongs to Thaariha
    (`app/intelligence/`). This is built and tested so that when that lands it
    is a call, not a design problem.

    Args:
        topk: contract C1, exactly 3 predictions descending.
        biases: label -> bias, from `bias_for`. Missing labels mean zero.
        clamp: keep the gate-preserving clamp. Only a test that is deliberately
            demonstrating the unclamped hazard should pass False.

    Only top-1 is adjusted. Nudging every candidate by its own prior would let
    the prior reorder the list, which is a larger claim than "history slightly
    favours this label" and is not what docs/DESIGN.md §11 describes.
    """
    predictions = list(topk.predictions)
    top1, top2 = predictions[0], predictions[1]

    raw = biases.get(top1.label, 0.0)
    bias = _clamped(top1.confidence, top2.confidence, raw) if clamp else raw
    if bias <= 0:
        return topk

    adjusted = min(1.0, top1.confidence + bias)
    return TopK(
        predictions=[
            Prediction(label=top1.label, confidence=adjusted),
            *predictions[1:],
        ],
        out_of_scope=topk.out_of_scope,
        model_version=topk.model_version,
        is_stub=topk.is_stub,
    )
