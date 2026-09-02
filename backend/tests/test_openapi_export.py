"""docs/openapi.json must match what the live app actually generates.

`docs/openapi.json` is a committed file generated from live code
(scripts/export_openapi.py). Nothing enforced that someone who adds or
changes a route also re-exports it, so the contract Tharun and Santheesh
generate clients from could silently drift from the real API. This test is
that enforcement.

Compares parsed JSON, not raw bytes: key ordering and trailing whitespace
are not contract changes, and a test that fails on them is the kind that
gets `# noqa`'d or disabled within a week rather than fixed.
"""

from __future__ import annotations

import json
import sys

sys.path.insert(0, "scripts")

from export_openapi import OUTPUT_PATH  # noqa: E402

from app.main import create_app  # noqa: E402


def test_committed_openapi_json_matches_the_live_schema() -> None:
    live_schema = create_app().openapi()

    assert OUTPUT_PATH.exists(), (
        f"{OUTPUT_PATH} does not exist. Generate it: "
        "python -m scripts.export_openapi"
    )
    committed_schema = json.loads(OUTPUT_PATH.read_text(encoding="utf-8"))

    assert committed_schema == live_schema, (
        "docs/openapi.json is stale -- it does not match what the app "
        "actually generates. A route was added, changed, or had its "
        "responses=/response_model touched without re-exporting. Fix: "
        "python -m scripts.export_openapi, then commit the result."
    )
