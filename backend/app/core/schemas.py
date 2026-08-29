"""Request and response models for core/'s endpoints.

OWNER: Shreekumar. Spec: docs/API_CONTRACT.md §2, §3, §5, §10, §11.

PHASE 1, not Phase 0. Shapes that cross a module boundary belong in
app/contracts/ and are frozen; shapes that are only ever core/'s wire format
live here.
"""

from __future__ import annotations
