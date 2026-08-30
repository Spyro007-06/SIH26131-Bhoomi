"""Run the F5 risk job once and print its report.

OWNER: Shreekumar. Run from backend/:  python scripts/run_risk_job.py

Standalone entry point so the job can be run by hand during a demo. The
scheduled version is registered in app/scheduler.py.
"""

from __future__ import annotations

import asyncio
import pathlib
import sys

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parents[1]))

from app.core.services.risk import issue_alerts  # noqa: E402
from app.db import SessionLocal, dispose_engine  # noqa: E402


async def main() -> None:
    try:
        async with SessionLocal() as session:
            report = await issue_alerts(session)
        print(report.render())
    finally:
        await dispose_engine()


if __name__ == "__main__":
    asyncio.run(main())
