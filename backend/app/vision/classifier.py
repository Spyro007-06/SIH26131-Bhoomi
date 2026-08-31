"""Bounded paddy classifier. Returns contract C1.

OWNER: Suchit. Spec: docs/DESIGN.md §3 (module boundaries), §4 (C1), §12 (flags).

`classify()` is the only entry point. It dispatches on `settings.vision_model`:

  real  -> the PyTorch classifier, served in-process (Suchit, Phase 2+)
  stub  -> the deliberately-inert distribution below

The stub is the one function in another owner's module that Phase 0 implements,
because a missing stub blocks everyone and a *bad* stub loses the demo.
"""

from __future__ import annotations

import logging

from app.config import settings
from app.contracts.vision import Prediction, TopK

log = logging.getLogger("bhoomi.vision")

STUB_MODEL_VERSION = "stub-0"

# ---------------------------------------------------------------------------
# The stub distribution. docs/DESIGN.md §12 and the Phase 0 brief:
#
#   "It must NOT hash the image, compare it to anything, or produce
#    input-dependent output that looks like a real prediction."
#
# So this is a constant. It does not read a single byte of the image.
#
# The values are chosen so the stub cannot produce advice under any gate path:
# top-1 is 0.34, below FLOOR (0.45), so the gate returns escalate/BELOW_FLOOR.
# The top1-top2 gap is 0.01, far below MARGIN, so even if the floor check were
# reordered the stub would land in clarify, never in advise. A stub physically
# incapable of composing an advisory is the property worth having here.
# ---------------------------------------------------------------------------
STUB_DISTRIBUTION: tuple[tuple[str, float], ...] = (
    ("paddy_blast", 0.34),
    ("paddy_brown_spot", 0.33),
    ("paddy_bacterial_leaf_blight", 0.33),
)


def _stub_topk() -> TopK:
    return TopK(
        predictions=[Prediction(label=lbl, confidence=c) for lbl, c in STUB_DISTRIBUTION],
        out_of_scope=False,
        model_version=STUB_MODEL_VERSION,
        is_stub=True,
    )


def classify(image: bytes | str) -> TopK:
    """Classify a paddy leaf image into the bounded label set.

    Args:
        image: image bytes, or the asset id / object key to fetch them by.

    Returns:
        TopK — exactly 3 predictions, descending, with `is_stub` set truthfully.

    Raises:
        NotImplementedError: when VISION_MODEL=real. Suchit implements this.
    """
    if settings.vision_model == "stub":
        log.warning(
            "vision.classify() served by STUB — fixed distribution, image not read. "
            "is_stub=true; clients must show a stub banner. docs/DESIGN.md §12."
        )
        return _stub_topk()

    raise NotImplementedError(
        "Real classifier not implemented — owner: Suchit, docs/DESIGN.md §3. "
        "Set VISION_MODEL=stub to run against the stub."
    )
