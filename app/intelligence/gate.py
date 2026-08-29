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
"""

from __future__ import annotations

from app.contracts.gate import GateDecision
from app.contracts.vision import TopK


def decide(topk: TopK, retrieval_score: float | None) -> GateDecision:
    """Map a classifier output and a retrieval relevance to one gate outcome.

    Args:
        topk: contract C1 from vision/.
        retrieval_score: best relevance from the corpus search, or None if no
            retrieval was attempted.

    Returns:
        GateDecision with exactly one outcome and populated alternatives.

    Raises:
        NotImplementedError: owner Thaariha, docs/DESIGN.md §6.
    """
    raise NotImplementedError(
        "Gate not implemented — owner: Thaariha, docs/DESIGN.md §6. "
        "Thresholds come from app.config (GATE, FLOOR, MARGIN, RAG_THRESHOLD); "
        "do not redeclare them here."
    )
