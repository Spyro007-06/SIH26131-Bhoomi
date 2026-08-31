"""F2 the confidence gate, F3 image-based identification.

OWNER: Thaariha + Suchit; orchestration by Shreekumar

Serves:
    POST /farms/{id}/diagnose -- NOT implemented here. Its frozen response
        (docs/API_CONTRACT.md §6) requires a `gate` object composed by
        app.intelligence.gate.decide(), which raises NotImplementedError
        (owner Thaariha). Building it is out of scope for this file for now.

    POST /vision/classify -- Phase 1 exception, vision fixture / test mode
        (owner Suchit). This is a deliberately separate, interim path: it
        returns contract C1 (TopK) unmodified and untouched by any gate logic,
        so Thaariha (and anyone downstream) can drive all three gate bands by
        header before decide() exists. It is not the diagnose contract and
        must not be mistaken for it -- fold it into the real handler, or
        remove it, once F2 lands.

Specified by: docs/API_CONTRACT.md §6, docs/DESIGN.md §6.
"""

from __future__ import annotations

from fastapi import APIRouter, Header, status

from app.config import settings
from app.contracts.vision import Prediction, TopK
from app.errors import Forbidden, ValidationFailed

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
            Prediction(label="blast", confidence=0.85),
            Prediction(label="brown_spot", confidence=0.10),
            Prediction(label="bacterial_leaf_blight", confidence=0.05),
        ],
        out_of_scope=False,
        model_version=STUB_MODEL_VERSION,
        is_stub=True,
    ),
    "torn": TopK(  # Doubt Doctor band: blast vs brown_spot, both above FLOOR,
        # gap under MARGIN
        predictions=[
            Prediction(label="blast", confidence=0.50),
            Prediction(label="brown_spot", confidence=0.46),
            Prediction(label="bacterial_leaf_blight", confidence=0.04),
        ],
        out_of_scope=False,
        model_version=STUB_MODEL_VERSION,
        is_stub=True,
    ),
    "low_confidence": TopK(  # escalate band: top-1 below FLOOR
        predictions=[
            Prediction(label="blast", confidence=0.38),
            Prediction(label="brown_spot", confidence=0.33),
            Prediction(label="bacterial_leaf_blight", confidence=0.29),
        ],
        out_of_scope=False,
        model_version=STUB_MODEL_VERSION,
        is_stub=True,
    ),
    "out_of_scope": TopK(  # nothing in the bounded set fits: flat, low, flag set
        predictions=[
            Prediction(label="blast", confidence=0.36),
            Prediction(label="brown_spot", confidence=0.33),
            Prediction(label="bacterial_leaf_blight", confidence=0.31),
        ],
        out_of_scope=True,
        model_version=STUB_MODEL_VERSION,
        is_stub=True,
    ),
}


@router.post("/vision/classify", response_model=TopK)
async def classify_vision_fixture(
    x_vision_fixture: str | None = Header(default=None),
) -> TopK:
    """Return a fixture TopK selected by the X-Vision-Fixture header.

    No header returns the inert stub distribution, unchanged, in every mode.
    That is the one path here that does not name a fixture.

    A fixture name is refused outright when VISION_MODEL=real. On a machine with
    the model loaded, a stray header left in a client must not quietly stand in
    for inference -- that is a silent stub by another route (docs/DESIGN.md §12).

    An unrecognised name is a 400 rather than a fall-through. Falling through
    handed back the stub's near-uniform distribution, which reads as a broken
    gate rather than as a typo in the header.
    """
    if x_vision_fixture is None:
        return _stub_topk()

    if settings.vision_model == "real":
        raise Forbidden(
            "Vision fixtures are not served when VISION_MODEL=real. Drop the "
            "X-Vision-Fixture header, or run with VISION_MODEL=stub.",
            details={"vision_model": settings.vision_model},
        )

    if x_vision_fixture not in _FIXTURES:
        raise ValidationFailed(
            f"Unknown X-Vision-Fixture value {x_vision_fixture!r}.",
            details={"known_fixtures": sorted(_FIXTURES)},
            status_code=status.HTTP_400_BAD_REQUEST,
        )

    return _FIXTURES[x_vision_fixture]
