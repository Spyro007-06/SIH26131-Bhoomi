"""Case bundle compiler (F12) — what the agronomist opens.

OWNER: Thaariha. Spec: docs/API_CONTRACT.md §12.

Contract rule: every field is populated from live data. No placeholder strings —
no "Unregistered Farmer", no empty history array on a case that has history, no
null confidence where a diagnosis exists. A bundle failing this on a real case is
a failed feature, not a cosmetic issue.

docs/DESIGN.md §13 lists this among the two tests that exist because both have
failed before in this project's history.
"""

from __future__ import annotations

from typing import Any


def compile_bundle(
    farm: Any,
    problem: Any,
    diagnosis: Any,
    observations: list[Any],
    images: list[Any],
    label_checks: list[Any],
    followups: list[Any],
) -> Any:
    """Assemble the agronomist's case bundle from live records.

    core/ reads the rows and passes them in; this function shapes them. Return
    shape is docs/API_CONTRACT.md §12.

    Raises:
        NotImplementedError: owner Thaariha, docs/API_CONTRACT.md §12.
    """
    raise NotImplementedError(
        "Case bundle not implemented — owner: Thaariha, docs/API_CONTRACT.md §12."
    )
