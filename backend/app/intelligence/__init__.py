"""intelligence/ — the gate, the Doubt Doctor, RAG, verdicts and case bundles.

OWNER: Thaariha. Spec: docs/DESIGN.md §3, §6, §7, §8, §9, §12.

Exposes `decide()`, `compose()`, `verdict()` and `compile_bundle()`.

Boundary rule, docs/DESIGN.md §3: this package never queries the database
directly. `core/` hands it what it needs and persists what it returns.
"""

from app.intelligence.bundle import compile_bundle
from app.intelligence.gate import decide
from app.intelligence.rag import compose
from app.intelligence.verdict import verdict

__all__ = ["compile_bundle", "compose", "decide", "verdict"]
