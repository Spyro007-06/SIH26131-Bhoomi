"""The confidence gate (F2) — the single most important function in the build.

OWNER: Thaariha. Spec: docs/DESIGN.md §6.

Everything consequential passes through `decide()`. It is deterministic code
comparing probabilities against constants, not a prompt — that is what makes the
"never fabricate" guarantee something you can point at.

Properties that must hold and must have tests (docs/DESIGN.md §6, §13):
  - Exactly one outcome. Never both advice and escalation; never neither.
  - `alternatives` populated on every branch, including `advise`.
  - No advisory composition happens before this returns `advise`.
  - Thresholds are imported from app.config. A threshold literal appearing here
    is a bug.

Ordering note from §6: the ambiguity check runs BEFORE the absolute-gate check.
0.68/0.12 is clear but under the gate -> escalate. 0.58/0.49 is ambiguous ->
Doubt Doctor, even though neither clears the gate. Ambiguity is the more
informative signal and is worth a question.

Phase 2 scope note: this implements the classifier-confidence half of §6's
pseudocode only — out-of-scope, floor, ambiguity, gate. It deliberately stops
before §6's final branch (`retrieval_score < RAG_THRESHOLD -> escalate`,
reason NO_RELEVANT_SOURCE): that branch is corpus-backed, and Phase 2 has zero
dependency on the corpus by its own brief. `retrieval_score` stays in the
signature for call-site stability but is not consulted yet. A confident,
in-scope, unambiguous prediction reaches `advise` on its own until Phase 3
wires RAG in and this stub grows that last check.

Crop-scope note: `topk.out_of_scope` is contract C1 — vision/ decides whether
the crop or target is in the bounded set (docs/DESIGN.md §4) and hands the
gate a plain bool. The gate does not keep its own crop list and never
inspects `topk.predictions` labels to make that call; it only reads the flag.
That is what makes the out-of-scope check crop-aware without this module
naming a single crop.
"""

from __future__ import annotations

from app.config import FLOOR, GATE, MARGIN
from app.contracts.enums import GateOutcome, GateReasonCode
from app.contracts.gate import GateDecision
from app.contracts.vision import TopK


def decide(topk: TopK, retrieval_score: float | None) -> GateDecision:
    """Map a classifier output to one gate outcome. See module docstring for
    what Phase 2 does and does not implement.

    Args:
        topk: contract C1 from vision/.
        retrieval_score: unused in Phase 2 (see module docstring); kept so the
            Phase 3 caller does not need a signature change.

    Returns:
        GateDecision with exactly one outcome and populated alternatives.
    """
    del retrieval_score  # Phase 2: not consulted yet, see module docstring.
    alternatives = list(topk.predictions)

    if topk.out_of_scope:
        return GateDecision(
            outcome=GateOutcome.ESCALATE,
            confidence=topk.predictions[0].confidence,
            threshold_applied=GATE,
            reason_code=GateReasonCode.OUT_OF_SCOPE,
            alternatives=alternatives,
        )

    top1, top2 = topk.predictions[0], topk.predictions[1]

    if top1.confidence < FLOOR:
        return GateDecision(
            outcome=GateOutcome.ESCALATE,
            confidence=top1.confidence,
            threshold_applied=FLOOR,
            reason_code=GateReasonCode.BELOW_FLOOR,
            alternatives=alternatives,
        )

    if top1.confidence - top2.confidence < MARGIN:
        return GateDecision(
            outcome=GateOutcome.CLARIFY,
            confidence=top1.confidence,
            threshold_applied=MARGIN,
            reason_code=GateReasonCode.AMBIGUOUS,
            alternatives=alternatives,
        )

    if top1.confidence < GATE:
        # No reason code of its own exists for "clear but under the gate"
        # (GateReasonCode has five members total) — docs/DESIGN.md §6's own
        # pseudocode reuses BELOW_FLOOR here, so this does too.
        return GateDecision(
            outcome=GateOutcome.ESCALATE,
            confidence=top1.confidence,
            threshold_applied=GATE,
            reason_code=GateReasonCode.BELOW_FLOOR,
            alternatives=alternatives,
        )

    return GateDecision(
        outcome=GateOutcome.ADVISE,
        confidence=top1.confidence,
        threshold_applied=GATE,
        reason_code=GateReasonCode.ABOVE_GATE,
        alternatives=alternatives,
    )
