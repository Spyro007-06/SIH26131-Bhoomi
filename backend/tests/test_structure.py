"""Structure-only modules stay structure-only.

Router, service and schema modules start as headers: a docstring naming the
owner, the feature and the specifying docs section, and nothing else. This file
is the mechanical check that the ones still unbuilt remain that way.

It exists because the failure mode is quiet. A placeholder class or a stub route
added "just to get something working" looks like progress and has to be deleted
by the module's real owner before they can start.

IMPLEMENTED is a ledger of built surface. It should grow as phases land, and the
structure-only list shrinks to match — when you implement a module you own, move
it here in the same commit rather than deleting the check.
"""

from __future__ import annotations

import ast
import importlib
import pathlib

import pytest

CORE = pathlib.Path(__file__).resolve().parents[1] / "app" / "core"

STRUCTURE_ONLY_DIRS = [CORE / "routers", CORE / "services", CORE / "schemas"]

# Built and no longer structure-only. Phase 1 (F1 spine): the three endpoint
# groups Shreekumar owns, and their request/response models.
IMPLEMENTED = {
    "routers/auth.py",
    "routers/assets.py",
    "routers/farms.py",
    "schemas/auth.py",
    "schemas/assets.py",
    "schemas/farms.py",
    # Phase 2 (F8 lookup half + case-file reads).
    "services/registered_use.py",
    "routers/problems.py",
    "schemas/problems.py",
    # Phase 3 (F5 risk + alerts, F10 follow-up).
    "routers/alerts.py",
    "routers/followups.py",
    "schemas/alerts.py",
    "schemas/followups.py",
    "services/risk.py",
    "services/followup.py",
    "services/escalation.py",
    # Phase 4 (F6 spread, F14 confirmation + prior, F15 data half).
    #
    # routers/cases.py is PARTLY implemented: POST /cases/{id}/confirm and
    # GET /agronomist/case-queue are Shreekumar's and are built. GET /cases/{id}
    # — the bundle — and POST /cases/{id}/request-info remain Thaariha's F12 and
    # are NOT implemented; they are absent from the router rather than stubbed,
    # so they 404 rather than returning a plausible empty bundle.
    "routers/cases.py",
    "routers/officials.py",
    "schemas/cases.py",
    "schemas/officials.py",
    "services/spread.py",
    "services/confirmation.py",
    "services/prior.py",
    "services/aggregates.py",
    # Phase 1 exception (2026-08-31): POST /vision/classify, the fixture /
    # test-mode endpoint for the vision stub.
    #
    # POST /farms/{id}/diagnose itself landed later, in the same file --
    # escalate and clarify-with-no-cue-found are fully built; advise and
    # clarify-with-a-cue-found return 501 (F7's composer and F4's question
    # flow are Thaariha's). See routers/diagnose.py's module docstring.
    "routers/diagnose.py",
    # schemas/diagnose.py: the response shapes for the above. Same reasoning
    # as routers/diagnose.py -- built alongside it, not a phase-scaffolded
    # placeholder.
    "schemas/diagnose.py",
    # Corpus ingestion loader. "services/corpus.py" is the retrieval-side
    # authoritative filter -- NOT a router, schema or service that a phase
    # brief scaffolded as a placeholder; it is a new module written to answer
    # Part 2's "make the retrieval path exclude non-authoritative chunks"
    # requirement.
    "services/corpus.py",
    # V3 phase 3, Part 5: the inspection-tier alert-response fix. Not a phase
    # brief's scaffolded placeholder either -- a new module, same reasoning as
    # services/corpus.py above.
    "services/alerts.py",
}


def _rel(path: pathlib.Path) -> str:
    return f"{path.parent.name}/{path.name}"


def _structure_only_files() -> list[pathlib.Path]:
    found: list[pathlib.Path] = []
    for directory in STRUCTURE_ONLY_DIRS:
        found.extend(p for p in sorted(directory.glob("*.py")) if _rel(p) not in IMPLEMENTED)
    return found


def _module_name(path: pathlib.Path) -> str:
    rel = path.relative_to(CORE.parents[1]).with_suffix("")
    parts = list(rel.parts)
    if parts[-1] == "__init__":
        parts.pop()
    return ".".join(parts)


ALL_FILES = _structure_only_files()
IMPLEMENTED_FILES = [
    CORE / rel for rel in sorted(IMPLEMENTED) if (CORE / rel).exists()
]


def test_the_expected_modules_exist() -> None:
    """Guards against a rename quietly emptying the parametrised tests below."""
    routers = {p.name for p in (CORE / "routers").glob("*.py")}
    services = {p.name for p in (CORE / "services").glob("*.py")}

    assert routers == {
        "__init__.py",
        "auth.py",
        "assets.py",
        "farms.py",
        "alerts.py",
        "followups.py",
        "problems.py",
        "diagnose.py",
        "clarify.py",
        "advisory.py",
        "labelcheck.py",
        "cases.py",
        "referrals.py",
        "officials.py",
    }
    assert services == {
        "__init__.py",
        "risk.py",
        "spread.py",
        "followup.py",
        "confirmation.py",
        "prior.py",
        "registered_use.py",
        "aggregates.py",
        "escalation.py",
        "corpus.py",
        "alerts.py",
    }


def test_every_implemented_module_is_actually_present() -> None:
    """The ledger must not drift from the tree. A name listed as implemented
    that no longer exists means the exclusion below is silently covering
    nothing."""
    missing = sorted(rel for rel in IMPLEMENTED if not (CORE / rel).exists())
    assert not missing, f"IMPLEMENTED lists modules that do not exist: {missing}"


@pytest.mark.parametrize("path", ALL_FILES, ids=_module_name)
def test_module_is_importable(path: pathlib.Path) -> None:
    assert importlib.import_module(_module_name(path)) is not None


@pytest.mark.parametrize("path", ALL_FILES, ids=_module_name)
def test_module_contains_nothing_but_its_docstring(path: pathlib.Path) -> None:
    """The module body must be exactly one node: the docstring expression.

    An import, an assignment, a class or a def all fail here — including
    `from __future__ import annotations`, which is why these files do not carry
    one.
    """
    tree = ast.parse(path.read_text(encoding="utf-8"))

    assert len(tree.body) == 1, (
        f"{path.name} has {len(tree.body)} top-level statements; structure-only "
        "modules contain their docstring and nothing else. If you are ready to "
        f"implement this module, add {_rel(path)!r} to IMPLEMENTED in this file "
        "in the same commit."
    )
    node = tree.body[0]
    assert isinstance(node, ast.Expr) and isinstance(node.value, ast.Constant), (
        f"{path.name}'s only statement is not a docstring"
    )
    assert isinstance(node.value.value, str)


@pytest.mark.parametrize("path", ALL_FILES + IMPLEMENTED_FILES, ids=_module_name)
def test_module_names_an_owner_and_a_docs_section(path: pathlib.Path) -> None:
    """Every module carries who owns it and what specifies it — implemented ones
    too. A module with neither is a file nobody can safely change."""
    doc = ast.get_docstring(ast.parse(path.read_text(encoding="utf-8"))) or ""

    assert "OWNER:" in doc, f"{path.name} does not name an owner"
    assert "docs/" in doc, f"{path.name} does not cite a docs section"
