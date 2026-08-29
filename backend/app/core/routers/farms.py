"""F1 — farm persistent memory.

OWNER: Shreekumar

Serves:
    POST /farms
    GET /farms/{id}
    PATCH /farms/{id}
    GET /farms/{id}/summary

Specified by: docs/API_CONTRACT.md §5. Farm shape is contract C2, docs/DESIGN.md §4.

Structure only. No routes are defined yet and nothing is mounted in
app/main.py — an empty router module has nothing to mount.
"""
