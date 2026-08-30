"""Open-Meteo client. Feeds F5's weather-driven favourability rules.

OWNER: Shreekumar. Spec: docs/DESIGN.md §1 and §10.

-----------------------------------------------------------------------------
There is deliberately no weather-observation table.

The rules need a multi-day window ("humidity above 90% for 4 consecutive
nights"), which looks like it needs stored history. It does not: Open-Meteo
takes `past_days`, so a single call returns the trailing week alongside the
forecast.

Storing observations would mean a table that has to be kept fresh by a job, and
a gap in that table does not announce itself — it just quietly makes every rule
that reads it weaker, because a missing day breaks a consecutive-day run. Asking
the upstream API for the window each time cannot silently degrade that way: if
the call fails, it fails loudly and no alert is issued.
-----------------------------------------------------------------------------

Caching is per job run, not global with a TTL. `WeatherCache` lives for the
duration of one `issue_alerts()` call, so twenty farms in Nashik make one HTTP
request. A process-lifetime cache would serve yesterday's window to tomorrow's
job, which is the same staleness problem as the table.
"""

from __future__ import annotations

from dataclasses import dataclass, field
from datetime import date

import httpx

from app.config import WEATHER_PAST_DAYS, WEATHER_TIMEOUT_SECONDS, settings


class WeatherUnavailable(RuntimeError):
    """Upstream weather could not be fetched.

    Raised rather than returning empty data. An empty window scores as "not
    favourable" everywhere, which would silently convert an outage into a day
    with no alerts — indistinguishable from a genuinely calm day.
    """


@dataclass(frozen=True, slots=True)
class DayWeather:
    """One day of the window. Nightly humidity is what the rules read."""

    on: date
    humidity_max: float | None
    temp_min: float | None
    temp_max: float | None

    @property
    def temp_mean(self) -> float | None:
        """Midpoint of the daily range. None when either end is missing."""
        if self.temp_min is None or self.temp_max is None:
            return None
        return (self.temp_min + self.temp_max) / 2

    def satisfies(
        self, humidity_min: float, temp_min: float, temp_max: float
    ) -> bool:
        """Was this day favourable under the given band?

        The temperature test is the daily MEAN inside the band, which is what
        favourability models actually use.

        It was an overlap test — the day counted if any part of its min-max
        range touched the band. In monsoon Maharashtra almost every day overlaps
        22-30C, so the test passed everywhere and carried no information: the
        job fired on 14 of 15 farm-target pairs. A rule that is true of every
        day is not a rule.

        A day with a missing reading is NOT favourable. Treating None as a pass
        would let a data gap manufacture a consecutive-day run.
        """
        if self.humidity_max is None:
            return False
        mean = self.temp_mean
        if mean is None:
            return False
        return self.humidity_max >= humidity_min and temp_min <= mean <= temp_max


@dataclass
class WeatherWindow:
    """The trailing-plus-forecast window for one point."""

    region: str
    days: list[DayWeather]

    def longest_run(self, humidity_min: float, temp_min: float, temp_max: float) -> int:
        """Longest run of consecutive favourable days in the window."""
        best = run = 0
        for day in self.days:
            run = run + 1 if day.satisfies(humidity_min, temp_min, temp_max) else 0
            best = max(best, run)
        return best

    def describe_run(
        self, humidity_min: float, temp_min: float, temp_max: float
    ) -> tuple[int, date | None, date | None]:
        """(length, first_day, last_day) of the longest favourable run."""
        best = run = 0
        best_end = end = None
        for day in self.days:
            if day.satisfies(humidity_min, temp_min, temp_max):
                run += 1
                end = day.on
            else:
                run = 0
                end = None
            if run > best:
                best, best_end = run, end
        if best == 0 or best_end is None:
            return 0, None, None
        start_index = next(i for i, d in enumerate(self.days) if d.on == best_end) - best + 1
        return best, self.days[start_index].on, best_end


@dataclass
class WeatherCache:
    """Per-run cache keyed by REGION.

    Twenty farms in Nashik make one HTTP call, not twenty. Keyed by region
    rather than by coordinate because the favourability signal here is a
    district-scale weather pattern — humidity and temperature bands over days —
    and neighbouring farms do not have meaningfully different ones. Keying by
    rounded coordinate would issue a separate call for farms 1.5 km apart.

    The first farm seen for a region supplies the coordinates for its call.
    """

    _client: httpx.AsyncClient | None = None
    _windows: dict[str, WeatherWindow] = field(default_factory=dict)
    calls: int = 0

    async def __aenter__(self) -> WeatherCache:
        self._client = httpx.AsyncClient(timeout=WEATHER_TIMEOUT_SECONDS)
        return self

    async def __aexit__(self, *_exc) -> None:
        if self._client is not None:
            await self._client.aclose()

    async def window(self, lat: float, lng: float, region: str) -> WeatherWindow:
        if region in self._windows:
            return self._windows[region]

        assert self._client is not None, "use WeatherCache as an async context manager"
        params = {
            "latitude": round(lat, 4),
            "longitude": round(lng, 4),
            "daily": "relative_humidity_2m_max,temperature_2m_min,temperature_2m_max",
            "past_days": WEATHER_PAST_DAYS,
            "forecast_days": 3,
            "timezone": "auto",
        }
        try:
            response = await self._client.get(settings.open_meteo_base_url, params=params)
            response.raise_for_status()
            payload = response.json()
        except (httpx.HTTPError, ValueError) as exc:
            raise WeatherUnavailable(
                f"Open-Meteo call failed for {region} ({lat:.4f}, {lng:.4f}): {exc}"
            ) from exc

        self.calls += 1
        window = WeatherWindow(region=region, days=_parse_daily(payload))
        self._windows[region] = window
        return window


def _parse_daily(payload: dict) -> list[DayWeather]:
    daily = payload.get("daily") or {}
    dates = daily.get("time") or []
    humidity = daily.get("relative_humidity_2m_max") or []
    tmin = daily.get("temperature_2m_min") or []
    tmax = daily.get("temperature_2m_max") or []

    if not dates:
        raise WeatherUnavailable("Open-Meteo returned no daily series")

    def at(series: list, index: int):
        return series[index] if index < len(series) else None

    return [
        DayWeather(
            on=date.fromisoformat(day),
            humidity_max=at(humidity, i),
            temp_min=at(tmin, i),
            temp_max=at(tmax, i),
        )
        for i, day in enumerate(dates)
    ]
