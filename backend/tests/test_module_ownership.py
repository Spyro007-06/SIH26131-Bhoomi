"""Definition of done step 5: every module exists with its owner named.

Also asserts the other owners' entry points are importable and refuse to run, so
nobody discovers at hour 20 that a signature was never created.
"""

from __future__ import annotations

import importlib

import pytest

from app.contracts.vision import Prediction, TopK

OWNED_MODULES = {
    "app.config": "Shreekumar",
    "app.db": "Shreekumar",
    "app.deps": "Shreekumar",
    "app.errors": "Shreekumar",
    "app.main": "Shreekumar",
    "app.core": "Shreekumar",
    "app.core.models": "Shreekumar",
    "app.core.schemas": "Shreekumar",
    "app.core.routers": "Shreekumar",
    "app.core.services": "Shreekumar",
    "app.vision": "Suchit",
    "app.vision.classifier": "Suchit",
    "app.vision.ocr": "Suchit",
    "app.intelligence": "Thaariha",
    "app.intelligence.gate": "Thaariha",
    "app.intelligence.rag": "Thaariha",
    "app.intelligence.verdict": "Thaariha",
    "app.intelligence.bundle": "Thaariha",
    "app.voice": "Shruthi",
    "app.voice.asr": "Shruthi",
    "app.voice.tts": "Shruthi",
    "app.voice.embedding_text": "Shruthi",
}


@pytest.mark.parametrize(("name", "owner"), sorted(OWNED_MODULES.items()))
def test_module_exists_and_names_its_owner(name: str, owner: str) -> None:
    module = importlib.import_module(name)
    doc = module.__doc__ or ""
    assert owner in doc, f"{name} does not name its owner ({owner}) in its docstring"


def _sample_topk() -> TopK:
    return TopK(
        predictions=[
            Prediction(label="paddy_blast", confidence=0.9),
            Prediction(label="paddy_brown_spot", confidence=0.06),
            Prediction(label="paddy_bacterial_leaf_blight", confidence=0.04),
        ],
        out_of_scope=False,
        model_version="test-1",
        is_stub=False,
    )


NOT_YET_IMPLEMENTED = [
    ("app.intelligence.rag", "compose", ("q", "paddy", "paddy_blast", [])),
    ("app.intelligence.verdict", "verdict", (None, "paddy", "paddy_blast", None, None)),
    ("app.intelligence.bundle", "compile_bundle", (None, None, None, [], [], [], [])),
    ("app.vision.ocr", "extract_label", (b"x",)),
]


@pytest.mark.parametrize(("module_name", "func_name", "args"), NOT_YET_IMPLEMENTED)
def test_unimplemented_entry_points_raise_loudly(
    module_name: str, func_name: str, args: tuple
) -> None:
    """Signatures exist; bodies refuse. A silent no-op would be worse than an
    import error, because it would look like a working feature."""
    func = getattr(importlib.import_module(module_name), func_name)
    with pytest.raises(NotImplementedError):
        func(*args)


def test_gate_signature_exists_and_returns_a_decision() -> None:
    """Phase 2 implements decide(); it no longer refuses. See test_gate.py for
    the four-band coverage against Phase 1's fixtures."""
    from app.intelligence import decide

    decision = decide(_sample_topk(), 0.8)
    assert decision.outcome == "advise"
