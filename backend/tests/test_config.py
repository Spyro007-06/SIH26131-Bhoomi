"""Config invariants. docs/DESIGN.md §6, §11.

The PRIOR_MAX_BIAS assertion is enforced at import time in app/config.py; these
tests state the property explicitly so a future edit that weakens it fails here
with an explanation rather than only as an AssertionError at startup.
"""

from __future__ import annotations

import ast
import pathlib

from app import config


def test_prior_cannot_resolve_an_ambiguous_pair() -> None:
    """docs/DESIGN.md §11: the prior must not move a prediction across a band.

    A bias at or above MARGIN could turn an ambiguous pair (clarify) into a clear
    one (advise) on history alone.
    """
    assert config.PRIOR_MAX_BIAS < config.MARGIN


def test_prior_cannot_carry_a_prediction_from_floor_to_gate() -> None:
    """A bias at or above (GATE - FLOOR) could carry a below-floor prediction
    over the gate — confidence from history rather than evidence."""
    assert config.PRIOR_MAX_BIAS < (config.GATE - config.FLOOR)


def test_threshold_ordering_holds() -> None:
    assert 0.0 < config.FLOOR < config.GATE <= 1.0
    assert 0.0 < config.MARGIN < 1.0
    assert 0.0 < config.RAG_THRESHOLD <= 1.0


def test_perception_floors_are_probabilities() -> None:
    assert 0.0 < config.OCR_FLOOR <= 1.0
    assert 0.0 < config.ASR_FLOOR <= 1.0


def test_thresholds_are_declared_only_in_config() -> None:
    """docs/DESIGN.md §6: "Constants live here and nowhere else. A threshold
    literal appearing in a second file is a bug."

    Scans every module under app/ for an assignment to one of the constant names
    and fails if one is bound outside app/config.py. This catches the specific
    failure mode of someone re-declaring GATE = 0.70 locally rather than
    importing it.
    """
    guarded = {
        "GATE",
        "FLOOR",
        "MARGIN",
        "RAG_THRESHOLD",
        "OCR_FLOOR",
        "ASR_FLOOR",
        "SPREAD_RADIUS_M",
        "FOLLOWUP_DUE_DAYS",
        "PRIOR_MAX_BIAS",
    }
    app_dir = pathlib.Path(__file__).resolve().parents[1] / "app"
    offenders: list[str] = []

    for path in app_dir.rglob("*.py"):
        if path.name == "config.py":
            continue
        tree = ast.parse(path.read_text(encoding="utf-8"))
        for node in ast.walk(tree):
            if isinstance(node, ast.Assign):
                targets = [t.id for t in node.targets if isinstance(t, ast.Name)]
            elif isinstance(node, ast.AnnAssign) and isinstance(node.target, ast.Name):
                targets = [node.target.id]
            else:
                continue
            for name in targets:
                if name in guarded:
                    offenders.append(f"{path.relative_to(app_dir.parent)}:{node.lineno} {name}")

    assert not offenders, (
        "threshold constants redeclared outside app/config.py "
        f"(docs/DESIGN.md §6): {offenders}"
    )
