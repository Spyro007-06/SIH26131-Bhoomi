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

from fastapi import APIRouter, Header

from app.contracts.vision import Prediction, TopK
from app.vision import classify
from app.vision.classifier import STUB_MODEL_VERSION

router = APIRouter(tags=["diagnose"])

# Fixture presets, Phase 1 vision test mode. Fixed values only -- never derived
# from the uploaded image (docs/DESIGN.md §12: a stub must not produce
# input-dependent output that looks like a real prediction).
_FIXTURES: dict[str, TopK] = {
    "confident": TopK(  # advise band: top-1 >= GATE (0.70)
        predictions=[
            Prediction(label="blast", confidence=0.85),
            Prediction(label="brown_spot", confidence=0.10),
            Prediction(label="bacterial_leaf_blight", confidence=0.05),
        ],
        out_of_scope=False,
        model_version=STUB_MODEL_VERSION,
        is_stub=True,
    ),
    "torn": TopK(  # Doubt Doctor band: blast vs brown_spot, both 0.40-0.69
        predictions=[
            Prediction(label="blast", confidence=0.58),
            Prediction(label="brown_spot", confidence=0.49),
            Prediction(label="bacterial_leaf_blight", confidence=0.11),
        ],
        out_of_scope=False,
        model_version=STUB_MODEL_VERSION,
        is_stub=True,
    ),
    "low_confidence": TopK(  # escalate band: top-1 < 0.40
        predictions=[
            Prediction(label="blast", confidence=0.31),
            Prediction(label="brown_spot", confidence=0.08),
            Prediction(label="bacterial_leaf_blight", confidence=0.04),
        ],
        out_of_scope=False,
        model_version=STUB_MODEL_VERSION,
        is_stub=True,
    ),
    "out_of_scope": TopK(  # a target outside the bounded label set
        predictions=[
            Prediction(label="wheat_rust", confidence=0.91),
            Prediction(label="blast", confidence=0.05),
            Prediction(label="brown_spot", confidence=0.04),
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

    No header, or a value not in _FIXTURES, falls back to the unmodified
    classify() stub -- current behavior, unchanged.
    """
    if x_vision_fixture in _FIXTURES:
        return _FIXTURES[x_vision_fixture]
    return classify(b"")
