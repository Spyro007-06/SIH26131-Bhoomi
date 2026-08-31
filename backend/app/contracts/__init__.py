"""The three frozen contracts. docs/DESIGN.md §4.

FROZEN AT HOUR 2. Four workstreams build against these. Reopening one costs more
than living with an imperfect shape — if something here is wrong, raise it with
the team rather than editing the file.

  C1  app/contracts/vision.py   Prediction, TopK           vision -> intelligence
  C2  app/contracts/farm.py     Farm, GeoPoint             core   -> everyone
  C3  app/contracts/gate.py     GateDecision, verdicts     intelligence -> clients

      app/contracts/enums.py    every wire enum, docs/API_CONTRACT.md §1
"""

from app.contracts.enums import (
    TARGET_TIERS,
    AlertOutcome,
    AlertTrigger,
    AssetKind,
    CaseStatus,
    ConfirmationVerdict,
    Crop,
    CueAnswer,
    FollowupResponse,
    GateOutcome,
    GateReasonCode,
    GrowthStageKey,
    LadderTier,
    Lang,
    ProblemSeverity,
    ProblemStatus,
    ProblemType,
    Role,
    TargetLabel,
    TargetTier,
    VerdictCode,
)
from app.contracts.farm import SRID, Farm, GeoPoint
from app.contracts.gate import (
    ENDORSEMENT_VOCABULARY,
    VERDICT_MESSAGES,
    GateDecision,
    phi_conflict_message,
)
from app.contracts.vision import TOPK_SIZE, Prediction, TopK

__all__ = [
    "ENDORSEMENT_VOCABULARY",
    "SRID",
    "TOPK_SIZE",
    "VERDICT_MESSAGES",
    "AlertOutcome",
    "AlertTrigger",
    "AssetKind",
    "CaseStatus",
    "ConfirmationVerdict",
    "Crop",
    "CueAnswer",
    "Farm",
    "FollowupResponse",
    "GateDecision",
    "GateOutcome",
    "GateReasonCode",
    "GeoPoint",
    "GrowthStageKey",
    "LadderTier",
    "Lang",
    "Prediction",
    "ProblemSeverity",
    "ProblemStatus",
    "ProblemType",
    "Role",
    "TARGET_TIERS",
    "TargetLabel",
    "TargetTier",
    "TopK",
    "VerdictCode",
    "phi_conflict_message",
]
