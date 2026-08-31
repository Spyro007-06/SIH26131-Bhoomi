"""F5 alert response: the inspection-tier branch.

OWNER: Shreekumar

Specified by: docs/API_CONTRACT.md §10, docs/DESIGN.md §10.

-----------------------------------------------------------------------------
`found` on an inspection-tier target has no diagnose path to suggest. The
target's own definition (docs/contracts/enums.py's TargetTier) is that a
photograph cannot settle it -- the organism is inside the stem, or too small,
or the damage looks like several other things from a leaf-level photo. A
farmer's field observation ("I found the pest the alert told me to look
for") is the only evidence that will ever exist for it, so `found` opens a
Problem with that label directly and escalates, mirroring exactly what
followup_service.record_response does for a `got_worse` answer -- this is
the same event (a field observation just became something an agronomist
should see), reached from a different entry point.

For a diagnosable target, `found` keeps suggesting the gated diagnose path;
nothing here changes that branch.
-----------------------------------------------------------------------------
"""

from __future__ import annotations

import uuid

from sqlalchemy.ext.asyncio import AsyncSession

from app.contracts.enums import TARGET_TIERS, AlertOutcome, ProblemType, TargetLabel, TargetTier
from app.core.models import Alert, Problem
from app.core.services.escalation import escalate

# Disease vs pest, by target. Not in app/contracts/enums.py alongside
# TARGET_TIERS: that file is frozen and this classification currently has one
# consumer (this module). Promote it there if a second consumer needs it.
TARGET_PROBLEM_TYPES: dict[TargetLabel, ProblemType] = {
    # paddy
    TargetLabel.PADDY_BLAST: ProblemType.DISEASE,
    TargetLabel.PADDY_BROWN_SPOT: ProblemType.DISEASE,
    TargetLabel.PADDY_BACTERIAL_LEAF_BLIGHT: ProblemType.DISEASE,
    TargetLabel.PADDY_YELLOW_STEM_BORER: ProblemType.PEST,
    TargetLabel.PADDY_BROWN_PLANTHOPPER: ProblemType.PEST,
    # cotton
    TargetLabel.COTTON_AMERICAN_BOLLWORM: ProblemType.PEST,
    TargetLabel.COTTON_PINK_BOLLWORM: ProblemType.PEST,
    TargetLabel.COTTON_WHITEFLY: ProblemType.PEST,
    TargetLabel.COTTON_THRIPS: ProblemType.PEST,
    TargetLabel.COTTON_BACTERIAL_BLIGHT: ProblemType.DISEASE,
    TargetLabel.COTTON_LEAF_CURL_VIRUS: ProblemType.DISEASE,
    TargetLabel.COTTON_FUSARIUM_WILT: ProblemType.DISEASE,
    # soybean
    TargetLabel.SOYBEAN_STEM_FLY: ProblemType.PEST,
    TargetLabel.SOYBEAN_GIRDLE_BEETLE: ProblemType.PEST,
    TargetLabel.SOYBEAN_DEFOLIATING_CATERPILLARS: ProblemType.PEST,
    TargetLabel.SOYBEAN_YELLOW_MOSAIC_VIRUS: ProblemType.DISEASE,
    TargetLabel.SOYBEAN_ANTHRACNOSE: ProblemType.DISEASE,
    TargetLabel.SOYBEAN_ALTERNARIA_LEAF_SPOT: ProblemType.DISEASE,
    TargetLabel.SOYBEAN_BACTERIAL_BLIGHT: ProblemType.DISEASE,
    # jowar
    TargetLabel.JOWAR_SHOOT_FLY: ProblemType.PEST,
    TargetLabel.JOWAR_STEM_BORER: ProblemType.PEST,
    TargetLabel.JOWAR_SHOOT_BUG: ProblemType.PEST,
    TargetLabel.JOWAR_ANTHRACNOSE: ProblemType.DISEASE,
    TargetLabel.JOWAR_GRAIN_MOLD: ProblemType.DISEASE,
    TargetLabel.JOWAR_SMUT: ProblemType.DISEASE,
    TargetLabel.JOWAR_DOWNY_MILDEW: ProblemType.DISEASE,
}


async def record_response(
    session: AsyncSession, alert: Alert, outcome: AlertOutcome
) -> tuple[bool, uuid.UUID | None]:
    """Apply an alert response. Returns (diagnose_suggested, case_id).

    `found` on a diagnosable target: diagnose_suggested=True, case_id=None --
    unchanged from before this function existed.

    `found` on an inspection-tier target: diagnose_suggested=False. Opens a
    Problem with the alert's target as its label and escalates immediately,
    same as followup_service.record_response does for `got_worse` -- see
    that module for why bundle stays NULL rather than a placeholder.

    Any other outcome (`nothing_found`, `snoozed`): diagnose_suggested=False,
    case_id=None. Nothing opens.
    """
    alert.outcome = outcome

    if outcome != AlertOutcome.FOUND:
        return False, None

    if TARGET_TIERS[alert.target] != TargetTier.INSPECTION:
        return True, None

    problem = Problem(
        farm_id=alert.farm_id,
        problem_type=TARGET_PROBLEM_TYPES[alert.target],
        label=alert.target,
    )
    session.add(problem)
    await session.flush()

    case = await escalate(
        session, problem.id, reason=f"inspection-tier alert response: {alert.target.value}"
    )
    return False, case.id
