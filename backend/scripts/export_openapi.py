"""Export the live OpenAPI schema to docs/openapi.json.

OWNER: Shreekumar. Run from backend/:  python -m scripts.export_openapi

In-process only -- app.openapi() builds the schema from the routes and
response_models already registered on the app object; no server, no
database. Writes whatever FastAPI actually generates, unmodified: a route
missing a response_model or a summary is a gap in the app to fix there, not
something to hand-annotate prettier here. Re-runnable at any time; this is
meant to be regenerated after every route change, not committed once and
left stale.
"""

from __future__ import annotations

import json
import pathlib
import sys

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parents[1]))

from app.main import create_app  # noqa: E402

OUTPUT_PATH = pathlib.Path(__file__).resolve().parents[2] / "docs" / "openapi.json"


def main() -> int:
    schema = create_app().openapi()
    OUTPUT_PATH.write_text(json.dumps(schema, indent=2, sort_keys=True) + "\n", encoding="utf-8")

    paths = sorted(schema.get("paths", {}))
    print(f"\n  wrote {OUTPUT_PATH.relative_to(OUTPUT_PATH.parents[1])}")
    print(f"  {len(paths)} path(s):\n")
    for path in paths:
        methods = ", ".join(m.upper() for m in schema["paths"][path] if m != "parameters")
        print(f"    {methods:20s} {path}")
    print()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
