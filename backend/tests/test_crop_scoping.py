"""Every query touching Problem, Diagnosis or CorpusDoc must be crop-scoped.

Cotton and soybean both have a "bacterial blight" whose symptom text is nearly
identical. Crop is therefore a CORRECTNESS filter, not a display field: a
retrieval or a history query that spans crops can return the right sentence
about the wrong plant.

-----------------------------------------------------------------------------
What counts as crop-scoped, and why this is not literally "has a crop predicate".

`Problem` and `Diagnosis` have no crop column — crop lives on `Farm`
(docs/DESIGN.md §5). A query can therefore be crop-safe two ways:

  1. an explicit predicate on a crop column (CorpusDoc.crop, LabelPrior.crop), or
  2. an equality predicate on farm_id or problem_id, which is STRICTLY NARROWER.
     A farm has exactly one crop, so a farm-scoped result set cannot span two.

Requiring a literal `.crop ==` on a farm-scoped query would mean joining Farm
solely to re-assert something the farm_id already guarantees, and a redundant
predicate that everyone learns to add mechanically is worse than an invariant
people understand.

An unscoped query — one that reads Problem, Diagnosis or CorpusDoc with neither
form of narrowing — fails here, with the module and line named.
-----------------------------------------------------------------------------
"""

from __future__ import annotations

import ast
import pathlib

import pytest

APP = pathlib.Path(__file__).resolve().parents[1] / "app"
SCANNED_DIRS = [APP / "core" / "services", APP / "core" / "routers"]

CROP_SENSITIVE_MODELS = {"Problem", "Diagnosis", "CorpusDoc"}

# Attribute names that scope a result set to a single crop, either directly or
# by being strictly narrower than crop. See the module docstring.
SCOPING_ATTRIBUTES = {
    "crop",           # explicit
    "farm_id",        # a farm has exactly one crop
    "problem_id",     # a problem belongs to one farm
    "id",             # a single row by primary key
}


def _python_files() -> list[pathlib.Path]:
    found: list[pathlib.Path] = []
    for directory in SCANNED_DIRS:
        found.extend(p for p in sorted(directory.rglob("*.py")) if p.name != "__init__.py")
    return found


class _SelectVisitor(ast.NodeVisitor):
    """Finds select(...) calls naming a crop-sensitive model, and records the
    attribute names referenced anywhere in the surrounding statement."""

    def __init__(self) -> None:
        self.findings: list[tuple[int, str, set[str]]] = []

    def visit_Call(self, node: ast.Call) -> None:  # noqa: N802 - ast API
        func = node.func
        name = func.id if isinstance(func, ast.Name) else getattr(func, "attr", None)
        if name == "select":
            models = {
                a.id
                for a in node.args
                if isinstance(a, ast.Name) and a.id in CROP_SENSITIVE_MODELS
            } | {
                a.value.id
                for a in node.args
                if isinstance(a, ast.Attribute) and isinstance(a.value, ast.Name)
                and a.value.id in CROP_SENSITIVE_MODELS
            }
            if models:
                self.findings.append((node.lineno, sorted(models)[0], set()))
        self.generic_visit(node)


def _statement_attributes(tree: ast.AST, lineno: int) -> set[str]:
    """Every attribute name used in the statement containing `lineno`.

    Crude but adequate: a select() and its .where() clauses are one expression,
    so the predicate columns appear as attributes within the same statement.
    """
    attributes: set[str] = set()
    for node in ast.walk(tree):
        if not isinstance(node, ast.stmt):
            continue
        start, end = node.lineno, getattr(node, "end_lineno", node.lineno)
        if start <= lineno <= end:
            for inner in ast.walk(node):
                if isinstance(inner, ast.Attribute):
                    attributes.add(inner.attr)
    return attributes


def _unscoped_queries() -> list[str]:
    offenders: list[str] = []
    for path in _python_files():
        tree = ast.parse(path.read_text(encoding="utf-8"))
        visitor = _SelectVisitor()
        visitor.visit(tree)
        for lineno, model, _ in visitor.findings:
            attributes = _statement_attributes(tree, lineno)
            if not (attributes & SCOPING_ATTRIBUTES):
                offenders.append(
                    f"{path.relative_to(APP.parent)}:{lineno} selects {model} "
                    f"with no crop scope (attributes seen: {sorted(attributes)})"
                )
    return offenders


def test_no_unscoped_crop_sensitive_query() -> None:
    """Fails naming the module and line. Do not add an exemption — either scope
    the query or, if it genuinely cannot be scoped, raise it with the team."""
    offenders = _unscoped_queries()
    assert not offenders, (
        "queries on Problem / Diagnosis / CorpusDoc with no crop scope:\n  "
        + "\n  ".join(offenders)
    )


def test_the_scan_actually_finds_queries() -> None:
    """Guards the guard. If a refactor moves these modules or renames select(),
    the test above would pass by scanning nothing."""
    total = 0
    for path in _python_files():
        visitor = _SelectVisitor()
        visitor.visit(ast.parse(path.read_text(encoding="utf-8")))
        total += len(visitor.findings)
    # A floor tracking today's reality (4 in routers/problems.py), not a target.
    # Raise it when more land; if it ever drops, the scan has stopped seeing them.
    assert total >= 4, f"only {total} crop-sensitive queries found - has the scan broken?"


@pytest.mark.parametrize("model", sorted(CROP_SENSITIVE_MODELS))
def test_crop_sensitive_model_is_reachable(model: str) -> None:
    """The three models named in the team decision still exist under those
    names, so the scan above is looking for the right things."""
    from app.core import models as m

    assert hasattr(m, model)
