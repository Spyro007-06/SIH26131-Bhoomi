"""Seed: one complete case file on farm A (Gangapur).

OWNER: Shreekumar. Run from backend/:  python -m seed.case_file
Requires seed.farms to have run first.

=============================================================================
EVERY ROW IN THIS MODULE IS A HAND-WRITTEN FIXTURE.

None of it is the output of a working pipeline. The gate (F2) and the advisory
composer (F7) are Thaariha's and do not exist yet; the classifier (F3) is
Suchit's and only has a stub. These rows were typed out to match the shapes in
docs/API_CONTRACT.md §6, §7 and §8 so that Tharun and Santheesh have real-shaped
data to build screens against today.

Do not read a green response from these rows as evidence that diagnosis,
clarification or advisory composition works. When those land, this fixture
should be replaced by their actual output — and if it ever disagrees with them,
they are right and this file is wrong.

The `is_stub: true` on the diagnosis is honest for the same reason: the numbers
did not come from a model.
=============================================================================

The scenario is docs/PRD.md §6 in miniature, stopped at step 6:

    2. photo -> top-3 blast 0.58 / brown_spot 0.49 / BLB 0.11
    3. gate  -> top1 under GATE, gap under MARGIN -> ambiguous -> clarify
    4. Doubt Doctor asks one question; farmer answers yes
    6. advisory: what-to-avoid first, ladder chemical-last with PHI and re-entry

It deliberately stops before confirmation, so Phase 4 has an unconfirmed case to
work with, and the follow-up is left unanswered so F10 has something due.
"""

from __future__ import annotations

import asyncio
from datetime import UTC, datetime, timedelta

from sqlalchemy import select

from app.contracts.enums import (
    AlertTrigger,
    AssetKind,
    CueAnswer,
    GateOutcome,
    GateReasonCode,
    ProblemSeverity,
    ProblemStatus,
    ProblemType,
    TargetLabel,
)
from app.core.models import (
    Advisory,
    Alert,
    Asset,
    Diagnosis,
    Farm,
    Observation,
    Problem,
    User,
)
from app.core.services.followup import schedule_for
from app.db import SessionLocal, dispose_engine

FARM_A_PHONE = "+919820000001"

# docs/PRD.md §6 step 2. top1 0.58 is under GATE (0.70) and the top1-top2 gap is
# 0.09, under MARGIN (0.15) — so the gate lands on clarify/AMBIGUOUS. These
# numbers are copied from the PRD, not produced by a classifier.
TOPK = {
    "predictions": [
        {"label": "paddy_blast", "confidence": 0.58},
        {"label": "paddy_brown_spot", "confidence": 0.49},
        {"label": "paddy_bacterial_leaf_blight", "confidence": 0.11},
    ],
    "out_of_scope": False,
    "model_version": "fixture-0",
    "is_stub": True,
    "threshold_applied": 0.15,
}

# docs/API_CONTRACT.md §8, verbatim in structure. Chemical is last and carries
# dosage, phi_days and reentry_hours — the CHECK constraint on advisory.ladder
# refuses to store it any other way.
LADDER = [
    {"tier": "cultural", "action": "Drain the field and let it dry for 48 hours."},
    {"tier": "biological", "action": "Apply Pseudomonas fluorescens as a foliar spray."},
    {
        "tier": "chemical",
        "action": "Tricyclazole 75 WP",
        "dosage": "0.6 g per litre",
        "phi_days": 30,
        "reentry_hours": 24,
    },
]

CITATIONS = [
    {
        "doc_id": "kb_211",
        "title": "ICAR Package of Practices: Rice - Blast",
        "reviewed_on": "2025-11-02",
    }
]


async def seed_case_file() -> None:
    async with SessionLocal() as session:
        farmer = (
            await session.execute(select(User).where(User.phone == FARM_A_PHONE))
        ).scalar_one_or_none()
        if farmer is None:
            raise SystemExit("Run `python -m seed.farms` first — farm A is missing.")

        farm = (
            await session.execute(select(Farm).where(Farm.farmer_id == farmer.id))
        ).scalars().first()
        if farm is None:
            raise SystemExit("Run `python -m seed.farms` first — farm A is missing.")

        existing = (
            await session.execute(select(Problem).where(Problem.farm_id == farm.id))
        ).scalars().first()
        if existing is not None:
            print(f"Case file already present on farm A (problem {existing.id}). Nothing to do.")
            return

        now = datetime.now(UTC)
        opened = now - timedelta(days=2)

        async def fixture_asset(slug: str, at, size: int) -> Asset:
            """Reuse the row if it is already there.

            object_key is UNIQUE, so re-running after a partial reset must match
            on it rather than insert. Idempotency has to survive the case where
            some tables were cleared and others were not.
            """
            key = f"image/fixture-{slug}-{farm.id}.jpg"
            found = (
                await session.execute(select(Asset).where(Asset.object_key == key))
            ).scalars().first()
            if found is not None:
                return found
            asset = Asset(
                kind=AssetKind.IMAGE, content_type="image/jpeg", object_key=key,
                farm_id=farm.id, uploaded_at=at, byte_size=size,
            )
            session.add(asset)
            await session.flush()
            return asset

        leaf_photo = await fixture_asset("leaf", opened, 248_311)
        await fixture_asset("underside", opened + timedelta(minutes=6), 201_774)

        problem = Problem(
            farm_id=farm.id,
            problem_type=ProblemType.DISEASE,
            label=TargetLabel.PADDY_BLAST,
            severity=ProblemSeverity.EARLY,
            status=ProblemStatus.OPEN,
            opened_at=opened,
        )
        session.add(problem)
        await session.flush()

        session.add(
            Diagnosis(
                problem_id=problem.id,
                image_asset_id=leaf_photo.id,
                topk=TOPK,
                gate_outcome=GateOutcome.CLARIFY,
                gate_confidence=0.58,
                reason_code=GateReasonCode.AMBIGUOUS,
                model_version="fixture-0",
                is_stub=True,
                created_at=opened + timedelta(minutes=2),
            )
        )

        session.add(
            Observation(
                problem_id=problem.id,
                kind="doubt_doctor",
                question="Flip the leaf over. Do you see fuzzy grey growth?",
                answer=CueAnswer.YES,
                created_at=opened + timedelta(minutes=7),
            )
        )

        session.add(
            Advisory(
                problem_id=problem.id,
                possible_issue="Early blast (confidence: high).",
                what_to_check="Diamond-shaped lesions with grey centres on upper leaves.",
                what_to_avoid="Do not top-dress nitrogen now. It accelerates spread.",
                ladder=LADDER,
                expert_trigger=(
                    "If lesions cover more than 25% of leaves within 3 days, escalate."
                ),
                citations=CITATIONS,
                created_at=opened + timedelta(minutes=8),
            )
        )

        # Unanswered on purpose, so F10 has something due to render.
        #
        # Created via services/followup.schedule_for() rather than by hand: that
        # is the function F7's advisory composition will call when it lands
        # (Thaariha, app/intelligence/rag.py), and routing the seed through it
        # means the seeded row and the real row are produced the same way.
        await schedule_for(session, problem.id, from_time=opened)

        # inspection_tasks is non-empty because the CHECK constraint refuses an
        # empty array — docs/DESIGN.md §5.
        session.add(
            Alert(
                farm_id=farm.id,
                trigger_type=AlertTrigger.WEATHER,
                target=TargetLabel.PADDY_BLAST,
                risk_level="high",
                reason=(
                    "Humidity above 90% for 4 consecutive nights at tillering stage."
                ),
                inspection_tasks=[
                    "Check the upper leaves on 10 plants across the field.",
                    "Photograph any spot with a grey centre.",
                ],
                issued_at=opened - timedelta(hours=6),
            )
        )

        await session.commit()

        print(f"\n  farm A     {farm.id}")
        print(f"  problem    {problem.id}  blast / early / open")
        print("  rows       1 diagnosis (clarify, AMBIGUOUS, is_stub=true)")
        print("             1 doubt_doctor observation, answer=yes")
        print("             1 advisory, 3 ladder rungs, chemical last, 1 citation")
        print("             1 follow-up, unanswered, via services/followup.schedule_for")
        print("             1 weather alert, 2 inspection tasks, outcome null")
        print("             2 image assets")
        print("\n  Farms B and C stay bare on purpose: F6's fan-out in Phase 4 needs a")
        print("  farm with no history to prove it alerts on proximity, not on prior")
        print("  problems.")
        print("\n  These rows are FIXTURES, not pipeline output. See the module docstring.")


async def main() -> None:
    try:
        await seed_case_file()
    finally:
        await dispose_engine()


if __name__ == "__main__":
    asyncio.run(main())
