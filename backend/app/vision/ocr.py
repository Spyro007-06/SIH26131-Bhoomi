"""Pesticide label OCR extraction. Feeds F8.

OWNER: Suchit. Spec: docs/DESIGN.md §9, docs/API_CONTRACT.md §9.

Label text only; no layout understanding needed. The verdict that follows is a
table lookup in core/ — no model is consulted for it, and the LLM is not in this
path at all.
"""

from __future__ import annotations

from typing import Any


def extract_label(image: bytes | str) -> Any:
    """Extract {active_ingredient, concentration, formulation, ocr_confidence}.

    Below `config.OCR_FLOOR` the caller returns OCR_UNREADABLE and offers the
    voice/text fallback rather than guessing an ingredient. docs/DESIGN.md §9.

    Return shape is specified on the wire in docs/API_CONTRACT.md §9
    (`extracted`); Suchit defines the Python type when implementing.

    Raises:
        NotImplementedError: owner Suchit, docs/DESIGN.md §3.
    """
    raise NotImplementedError(
        "OCR extraction not implemented — owner: Suchit, docs/DESIGN.md §9."
    )
