"""Measure the F5 fire rate on seed data without writing anything.

OWNER: Shreekumar. Run from backend/:  python scripts/measure_fire_rate.py

Scores every farm against every registry entry for its crop and reports the
fraction that would issue an alert. Writes nothing — this is a measurement, so
it must not change what it measures.
"""

from __future__ import annotations

import asyncio
import pathlib
import sys

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parents[1]))

from geoalchemy2.shape import to_shape  # noqa: E402
from sqlalchemy import select  # noqa: E402

from app.config import RISK_ALERT_MIN_LEVEL, RISK_LEVELS  # noqa: E402
from app.core.models import Farm, Problem  # noqa: E402
from app.core.services.risk import load_registry, score_farm_target  # noqa: E402
from app.core.weather import WeatherCache  # noqa: E402
from app.db import SessionLocal, dispose_engine  # noqa: E402


def meets(level: str) -> bool:
    return RISK_LEVELS.index(level) >= RISK_LEVELS.index(RISK_ALERT_MIN_LEVEL)


async def main() -> None:
    registry = load_registry()
    try:
        async with SessionLocal() as session, WeatherCache() as weather:
            farms = list((await session.execute(select(Farm))).scalars().all())
            pairs = fired = 0
            by_level: dict[str, int] = {}
            rows: list[tuple[str, str, str, bool, str]] = []

            for farm in farms:
                crop = farm.crop.value if hasattr(farm.crop, "value") else str(farm.crop)
                entries = [e for e in registry if e.crop == crop]
                point = to_shape(farm.location)
                window = await weather.window(point.y, point.x, farm.region)

                history = {
                    (h.value if hasattr(h, "value") else str(h))
                    for h in (
                        await session.execute(
                            select(Problem.label).where(Problem.farm_id == farm.id)
                        )
                    ).scalars().all()
                    if h is not None
                }

                for entry in entries:
                    pairs += 1
                    score = score_farm_target(
                        farm, entry, window, entry.target in history
                    )
                    issues = score.fired and meets(score.level)
                    if issues:
                        fired += 1
                        by_level[score.level] = by_level.get(score.level, 0) + 1
                    rows.append(
                        (
                            f"{farm.region}/{str(farm.id)[:8]}",
                            entry.target,
                            score.level,
                            issues,
                            score.reason if issues else score.reason,
                        )
                    )

            print(f"\n  {'farm':20s} {'target':24s} {'level':9s} issues?")
            print("  " + "-" * 70)
            for farm_label, target, level, issues, _ in rows:
                print(f"  {farm_label:20s} {target:24s} {level:9s} {'YES' if issues else '.'}")

            print(f"\n  FIRE RATE  {fired}/{pairs}  = {fired / pairs:.0%}")
            print(f"  by level   {by_level or '{}'}")
            print(f"  threshold  RISK_ALERT_MIN_LEVEL = {RISK_ALERT_MIN_LEVEL}\n")
    finally:
        await dispose_engine()


if __name__ == "__main__":
    asyncio.run(main())
