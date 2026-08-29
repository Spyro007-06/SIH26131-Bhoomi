"""Structure-only modules stay structure-only.

The interstitial task created router, service and schema modules as headers: a
docstring naming the owner, the feature and the specifying docs section, and
nothing else. This file is the mechanical check that they still are that.

It exists because the failure mode is quiet. A placeholder class or a stub route
added "just to get something working" looks like progress and has to be deleted
by the module's real owner before they can start.
"""

from __future__ import annotations

import ast
import importlib
import pathlib

import pytest

CORE = pathlib.Path(__file__).resolve().parents[1] / "app" / "core"

STRUCTURE_ONLY_DIRS = [CORE / "routers", CORE / "services", CORE / "schemas"]


def _structure_only_files() -> list[pathlib.Path]:
    found: list[pathlib.Path] = []
    for directory in STRUCTURE_ONLY_DIRS:
        found.extend(sorted(directory.glob("*.py")))
    return found


def _module_name(path: pathlib.Path) -> str:
    rel = path.relative_to(CORE.parents[1]).with_suffix("")
    parts = list(rel.parts)
    if parts[-1] == "__init__":
        parts.pop()
    return ".".join(parts)


ALL_FILES = _structure_only_files()


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
    }


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
        "implement this module, delete its entry from STRUCTURE_ONLY_DIRS "
        "coverage in this test in the same commit."
    )
    node = tree.body[0]
    assert isinstance(node, ast.Expr) and isinstance(node.value, ast.Constant), (
        f"{path.name}'s only statement is not a docstring"
    )
    assert isinstance(node.value.value, str)


@pytest.mark.parametrize("path", ALL_FILES, ids=_module_name)
def test_module_names_an_owner_and_a_docs_section(path: pathlib.Path) -> None:
    """Every header carries who owns it and what specifies it. A module with
    neither is a directory nobody can commit into with confidence."""
    doc = ast.get_docstring(ast.parse(path.read_text(encoding="utf-8"))) or ""

    assert "OWNER:" in doc, f"{path.name} does not name an owner"
    assert "docs/" in doc, f"{path.name} does not cite a docs section"
