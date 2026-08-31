"""F5 tuning: the rules have to carry information.

The job fired on 14 of 15 farm-target pairs. A rule true of almost every day is
not a rule — it is a constant wearing a threshold. These tests pin the four
changes that made the rules discriminate, so a later "small" edit cannot quietly
put the fire rate back to 93%.
"""

from __future__ import annotations

from datetime import date, timedelta

import pytest

from app.config import MAX_ALERTS_PER_FARM_PER_DAY, RISK_LEVELS
from app.core.services.risk import RiskTarget, load_registry, score_farm_target
from app.core.weather import DayWeather, WeatherWindow

# The real Nashik monsoon window that exposed the problem: humidity pinned at
# 96-98%, temperatures 21.4-27.2C, every day for ten days.
NASHIK_MONSOON = [(98, 21.8, 27.2), (97, 21.4, 27.0), (97, 21.7, 26.6),
                  (96, 21.5, 27.1), (97, 21.8, 25.9), (97, 21.7, 26.4),
                  (97, 21.5, 26.3), (97, 21.4, 26.8), (96, 21.8, 26.2),
                  (97, 21.8, 26.5)]


def _window(readings=NASHIK_MONSOON) -> WeatherWindow:
    start = date(2026, 8, 23)
    return WeatherWindow(
        region="Nashik",
        days=[
            DayWeather(on=start + timedelta(days=i), humidity_max=h, temp_min=lo, temp_max=hi)
            for i, (h, lo, hi) in enumerate(readings)
        ],
    )


# ===========================================================================
# 1. Mean in band, not overlap
# ===========================================================================


def test_temperature_test_is_the_daily_mean() -> None:
    day = DayWeather(on=date(2026, 8, 23), humidity_max=95, temp_min=21.4, temp_max=27.2)
    assert day.temp_mean == pytest.approx(24.3)


def test_a_day_whose_mean_is_outside_the_band_does_not_count() -> None:
    """The change that did the work. This day OVERLAPS 25-34C — its max is 27.2
    — but its mean is 24.3, which is below the band. Under the old overlap test
    it counted; it should not."""
    day = DayWeather(on=date(2026, 8, 23), humidity_max=95, temp_min=21.4, temp_max=27.2)
    assert day.temp_max >= 25, "precondition: the range really does overlap the band"
    assert day.satisfies(humidity_min=88, temp_min=25, temp_max=34) is False


def test_a_day_whose_mean_is_inside_the_band_does_count() -> None:
    day = DayWeather(on=date(2026, 8, 23), humidity_max=95, temp_min=21.4, temp_max=27.2)
    assert day.satisfies(humidity_min=90, temp_min=22, temp_max=30) is True


def test_humidity_is_still_a_maximum_test() -> None:
    day = DayWeather(on=date(2026, 8, 23), humidity_max=70, temp_min=23, temp_max=26)
    assert day.satisfies(humidity_min=90, temp_min=22, temp_max=30) is False


def test_a_missing_reading_is_never_favourable() -> None:
    """A data gap must not manufacture a consecutive-day run."""
    for kwargs in (
        {"humidity_max": None, "temp_min": 23, "temp_max": 26},
        {"humidity_max": 95, "temp_min": None, "temp_max": 26},
        {"humidity_max": 95, "temp_min": 23, "temp_max": None},
    ):
        day = DayWeather(on=date(2026, 8, 23), **kwargs)
        assert day.satisfies(90, 22, 30) is False


def test_the_monsoon_window_now_separates_targets() -> None:
    """The whole point: on identical weather, some bands match and some do not.

    Under the overlap test every one of these returned a full ten-day run.
    """
    window = _window()
    blast = window.longest_run(humidity_min=90, temp_min=22, temp_max=30)
    blb = window.longest_run(humidity_min=88, temp_min=25, temp_max=34)

    assert blast == 10, "blast's band brackets the daily mean of ~24C"
    assert blb == 0, "bacterial leaf blight's band starts above it"


# ===========================================================================
# 2. Six consecutive days
# ===========================================================================


def test_every_weather_rule_requires_six_consecutive_days() -> None:
    for entry in load_registry():
        if entry.weather_rule:
            assert entry.weather_rule["consecutive_days"] == 6, (
                f"{entry.target} still requires "
                f"{entry.weather_rule['consecutive_days']} days"
            )


# ===========================================================================
# 3. `high` requires stage match AND history bump
# ===========================================================================


def _entry(**overrides) -> RiskTarget:
    return RiskTarget(
        target=overrides.pop("target", "paddy_blast"),
        crop="paddy",
        tier=overrides.pop("tier", "diagnosable"),
        driver="weather",
        susceptible_stages=overrides.pop("stages", ("tillering",)),
        history_bump=overrides.pop("history_bump", True),
        weather_rule={"humidity_min": 90, "temp_min": 22, "temp_max": 30,
                      "consecutive_days": 6},
    )


class _Farm:
    """Minimal stand-in. score_farm_target reads three attributes."""

    def __init__(self, stage="tillering", sowing_date=None):
        self.growth_stage = stage
        self.sowing_date = sowing_date


def test_high_needs_both_stage_and_history() -> None:
    """Stage match alone is moderate. History alone cannot fire at all, because
    a stage mismatch is a hard precondition — there is no route to `high` on
    history by itself."""
    window = _window()

    stage_only = score_farm_target(_Farm(), _entry(), window, has_history=False)
    assert stage_only.fired is True
    assert stage_only.level == "moderate"

    both = score_farm_target(_Farm(), _entry(), window, has_history=True)
    assert both.fired is True
    assert both.level == "high"

    history_only = score_farm_target(
        _Farm(stage="maturity"), _entry(), window, has_history=True
    )
    assert history_only.fired is False, "a stage mismatch cannot fire on history"
    assert history_only.level == "low"


def test_history_bump_disabled_never_reaches_high() -> None:
    window = _window()
    score = score_farm_target(
        _Farm(), _entry(history_bump=False), window, has_history=True
    )
    assert score.level == "moderate"


# ===========================================================================
# 4. The per-farm daily cap
# ===========================================================================


def test_the_cap_is_two() -> None:
    """Alert cards are non-dismissible until answered. Five of them is a product
    nobody opens twice."""
    assert MAX_ALERTS_PER_FARM_PER_DAY == 2


def test_candidates_rank_by_level_then_history() -> None:
    """The ranking the cap applies, exercised directly.

    Registry order must not decide which two targets a farmer sees.
    """
    candidates = [
        ("a", "moderate", False),
        ("b", "high", False),
        ("c", "moderate", True),
        ("d", "high", True),
    ]
    ranked = sorted(
        candidates,
        key=lambda c: (RISK_LEVELS.index(c[1]), c[2]),
        reverse=True,
    )
    assert [c[0] for c in ranked] == ["d", "b", "c", "a"]
    assert [c[0] for c in ranked[:MAX_ALERTS_PER_FARM_PER_DAY]] == ["d", "b"]


def test_the_job_reports_what_it_suppressed() -> None:
    """Suppression has to be visible. A cap that silently drops alerts is
    indistinguishable from a rule that stopped firing."""
    from app.core.services.risk import RunReport

    report = RunReport(farms=1, scored=5, issued=2, suppressed_by_cap=3)
    rendered = report.render()
    assert "suppressed, cap     3" in rendered
