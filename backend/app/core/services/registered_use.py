"""F8 — the lookup half.

OWNER: Shreekumar

Table lookup against registered_use. No model is consulted and the LLM is not
in this path. An ingredient with no row is NOT_IN_RECORDS, never an inferred
verdict.

Specified by: docs/DESIGN.md §9, docs/API_CONTRACT.md §9.

Structure only. No implementation yet.
"""
