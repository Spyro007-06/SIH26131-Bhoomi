"""F5 - weather, season and phenology risk forecasting.

OWNER: Shreekumar

Open-Meteo pull, favourability scoring, issue_alerts(). Inspection tasks come
from the corpus when it exists and from seed until then; an empty task list
means no alert.

Specified by: docs/DESIGN.md §10.

-----------------------------------------------------------------------------
The engine does not know how many targets exist.

`seed/risk_targets.json` is the registry. This module dispatches on each entry's
`driver` and is otherwise indifferent to the size of the file. A team question
is open about whether more targets are image-diagnosable or alert-and-inspect
only; whichever way it lands, it is a data edit here rather than a refactor.

Two drivers, one dispatcher:

    weather    scores from the Open-Meteo window (consecutive favourable days)
    phenology  scores from days-after-sowing, derived from Farm.sowing_date

An entry may declare both (`"driver": "weather+phenology"`), in which case BOTH
must be satisfied — hopper burn needs a humid canopy and a crop old enough to
have one.

The registry is validated against the FROZEN enums on load and the file is
refused otherwise. `target_label` and `crop` are frozen in
app/contracts/enums.py; a registry entry naming something outside them is a
silent no-op at best and an expansion nobody agreed to at worst.
-----------------------------------------------------------------------------
"""

from __future__ import annotations

import json
import pathlib
from dataclasses import dataclass, field
from datetime import UTC, date, datetime
from typing import Any

from sqlalchemy import func, select, text
from sqlalchemy.exc import IntegrityError
from sqlalchemy.ext.asyncio import AsyncSession

from app.config import MAX_ALERTS_PER_FARM_PER_DAY, RISK_ALERT_MIN_LEVEL, RISK_LEVELS
from app.contracts.enums import AlertTrigger, Crop, GrowthStage, TargetLabel
from app.core.models import Alert, Farm, Problem
from app.core.weather import WeatherCache, WeatherWindow

SEED = pathlib.Path(__file__).resolve().parents[3] / "seed"
REGISTRY_PATH = SEED / "risk_targets.json"
TASKS_PATH = SEED / "inspection_tasks.json"

VALID_DRIVERS = {"weather", "phenology", "weather+phenology"}


class RegistryError(ValueError):
    """The registry or task file is malformed. Raised at load, never swallowed."""


# ===========================================================================
# Part 1 - the registry
# ===========================================================================


@dataclass(frozen=True, slots=True)
class RiskTarget:
    target: str
    crop: str
    driver: str
    susceptible_stages: tuple[str, ...]
    history_bump: bool
    weather_rule: dict[str, Any] | None = None
    phenology_rule: dict[str, Any] | None = None

    @property
    def uses_weather(self) -> bool:
        return "weather" in self.driver

    @property
    def uses_phenology(self) -> bool:
        return "phenology" in self.driver


def _validate_entry(raw: dict, index: int, errors: list[str]) -> RiskTarget | None:
    where = f"entry {index}"
    target = raw.get("target")
    crop = raw.get("crop")
    driver = raw.get("driver")

    if target not in {t.value for t in TargetLabel}:
        errors.append(
            f"{where}: target {target!r} is not in the frozen target_label enum "
            f"({', '.join(t.value for t in TargetLabel)}). Expanding it is a team "
            "decision, not a registry edit."
        )
    if crop not in {c.value for c in Crop}:
        errors.append(
            f"{where}: crop {crop!r} is not in the frozen crop enum "
            f"({', '.join(c.value for c in Crop)})"
        )
    if driver not in VALID_DRIVERS:
        errors.append(f"{where}: driver {driver!r} is not one of {sorted(VALID_DRIVERS)}")

    stages = raw.get("susceptible_stages") or []
    unknown = [s for s in stages if s not in {g.value for g in GrowthStage}]
    if unknown:
        errors.append(f"{where}: unknown growth stages {unknown}")
    if not stages:
        errors.append(f"{where}: susceptible_stages is empty - the entry can never fire")

    if driver and "weather" in str(driver) and not raw.get("weather_rule"):
        errors.append(f"{where}: driver names weather but weather_rule is missing")
    if driver and "phenology" in str(driver) and not raw.get("phenology_rule"):
        errors.append(f"{where}: driver names phenology but phenology_rule is missing")

    if errors:
        return None

    return RiskTarget(
        target=target,
        crop=crop,
        driver=driver,
        susceptible_stages=tuple(stages),
        history_bump=bool(raw.get("history_bump", False)),
        weather_rule=raw.get("weather_rule"),
        phenology_rule=raw.get("phenology_rule"),
    )


def load_registry(path: pathlib.Path | None = None) -> list[RiskTarget]:
    """Read and validate the risk registry. Refuses the whole file on any error.

    All-or-nothing on purpose. A partially-loaded registry means some targets
    silently stop being scored, and nothing in a nightly job would surface that.
    """
    path = path or REGISTRY_PATH
    raw = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(raw, list):
        raise RegistryError(f"{path.name}: expected a JSON array of entries")

    errors: list[str] = []
    targets: list[RiskTarget] = []
    for index, entry in enumerate(raw):
        entry_errors: list[str] = []
        parsed = _validate_entry(entry, index, entry_errors)
        errors.extend(entry_errors)
        if parsed:
            targets.append(parsed)

    seen = [t.target for t in targets]
    duplicates = {t for t in seen if seen.count(t) > 1}
    if duplicates:
        errors.append(f"duplicate targets in registry: {sorted(duplicates)}")

    if errors:
        raise RegistryError(
            f"{path.name} refused, {len(errors)} problem(s):\n  " + "\n  ".join(errors)
        )
    return targets


# ===========================================================================
# Part 3 - inspection tasks
# ===========================================================================

MIN_TASKS_PER_TARGET = 2


def load_inspection_tasks(
    path: pathlib.Path | None = None, corpus_tasks: dict[str, list[str]] | None = None
) -> dict[str, list[str]]:
    """Tasks per target, corpus first and seed second.

    docs/DESIGN.md §10 sources these from the corpus. The corpus has zero
    documents and no owner (§14), so `corpus_tasks` is the hook for when it
    exists and the seed file is the fallback until then.

    A target with fewer than two tasks raises HERE, at load. The alternative is
    an alert issued at 3am that the `inspection_tasks` non-empty CHECK rejects,
    which is a failure nobody sees until the morning.
    """
    path = path or TASKS_PATH
    raw = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(raw, dict):
        raise RegistryError(f"{path.name}: expected a JSON object keyed by target")

    tasks = {k: v for k, v in raw.items() if not k.startswith("_")}
    merged: dict[str, list[str]] = {**tasks, **(corpus_tasks or {})}

    errors: list[str] = []
    for target, entries in merged.items():
        if target not in {t.value for t in TargetLabel}:
            errors.append(f"{target!r} is not in the frozen target_label enum")
            continue
        if not isinstance(entries, list):
            errors.append(f"{target!r}: expected a list of task strings")
            continue
        if len(entries) < MIN_TASKS_PER_TARGET:
            errors.append(
                f"{target!r} has {len(entries)} task(s), minimum is "
                f"{MIN_TASKS_PER_TARGET} - an alert with no task is noise"
            )
        for entry in entries:
            if not isinstance(entry, str) or len(entry.strip()) < 20:
                errors.append(f"{target!r}: task is too short to name where and when: {entry!r}")

    if errors:
        raise RegistryError(
            f"{path.name} refused, {len(errors)} problem(s):\n  " + "\n  ".join(errors)
        )
    return merged


# ===========================================================================
# Part 4 - scoring
# ===========================================================================


@dataclass
class Score:
    """One farm scored against one registry entry."""

    target: str
    level: str
    reason: str
    fired: bool
    detail: dict[str, Any] = field(default_factory=dict)


def days_after_sowing(farm: Farm, on: date | None = None) -> int | None:
    """Derived, never stored. See docs/DATA_MODEL_ADDENDUM.md Part C."""
    if farm.sowing_date is None:
        return None
    return ((on or datetime.now(UTC).date()) - farm.sowing_date).days


def _bump(level: str, steps: int = 1) -> str:
    index = min(RISK_LEVELS.index(level) + steps, len(RISK_LEVELS) - 1)
    return RISK_LEVELS[index]


def score_farm_target(
    farm: Farm,
    entry: RiskTarget,
    window: WeatherWindow | None,
    has_history: bool,
    today: date | None = None,
) -> Score:
    """Score one farm against one registry entry.

    Returns a Score with `fired=False` and a stated reason whenever a
    precondition fails, rather than silently returning nothing — the job's
    below-threshold count is only meaningful if every non-firing case is
    accounted for.
    """
    stage = farm.growth_stage.value if hasattr(farm.growth_stage, "value") else str(
        farm.growth_stage
    )
    if stage not in entry.susceptible_stages:
        return Score(
            entry.target, "low",
            f"Crop is at {stage}, which is not a susceptible stage for this target.",
            fired=False, detail={"stage": stage},
        )

    detail: dict[str, Any] = {"stage": stage}
    clauses: list[str] = []

    if entry.uses_weather:
        rule = entry.weather_rule or {}
        needed = int(rule.get("consecutive_days", 1))
        if window is None:
            return Score(
                entry.target, "low", "No weather window available.", fired=False,
                detail=detail,
            )
        run, first, last = window.describe_run(
            rule.get("humidity_min", 0), rule.get("temp_min", -99), rule.get("temp_max", 99)
        )
        detail |= {"consecutive_days": run, "needed": needed}
        if run < needed:
            return Score(
                entry.target, "low",
                f"Humidity and temperature favoured this target on {run} consecutive "
                f"day(s); the rule needs {needed}.",
                fired=False, detail=detail,
            )
        span = f" ({first} to {last})" if first and last else ""
        clauses.append(
            f"humidity stayed above {rule.get('humidity_min')}% with temperature "
            f"between {rule.get('temp_min')} and {rule.get('temp_max')}C for {run} "
            f"consecutive days{span}"
        )

    if entry.uses_phenology:
        rule = entry.phenology_rule or {}
        das = days_after_sowing(farm, today)
        detail |= {"days_after_sowing": das}
        if das is None:
            return Score(
                entry.target, "low",
                "No sowing date recorded, so crop age cannot be established.",
                fired=False, detail=detail,
            )
        low, high = int(rule.get("das_min", 0)), int(rule.get("das_max", 10_000))
        if not (low <= das <= high):
            return Score(
                entry.target, "low",
                f"Crop is {das} days after sowing; this target is a risk between "
                f"{low} and {high} days.",
                fired=False, detail=detail,
            )
        # Lower case: clauses are joined with " and " and only the first
        # character of the finished sentence is capitalised, so a clause that
        # capitalises itself produces "... and Crop is ..." mid-sentence.
        clauses.append(
            f"the crop is {das} days after sowing, inside the {low}-{high} day "
            "window for this target"
        )

    # `high` requires BOTH a susceptible stage AND a history bump. The stage
    # check above is a hard precondition — anything reaching this line already
    # matched — so the bump below is the second half of that conjunction, not an
    # alternative route to it. There is no path to `high` on history alone.
    level = "moderate"
    history_clause = ""
    if entry.history_bump and has_history:
        level = _bump(level)
        history_clause = f" This farm has recorded {entry.target.replace('_', ' ')} before."
        detail["history_bump"] = True

    # Farmer-facing text. The stage qualifier attaches to the conditions that
    # triggered the alert, and the history note is its own sentence — folding it
    # into the same clause reads as though the history happened at this stage.
    body = " and ".join(clauses)
    reason = (
        f"{body[0].upper()}{body[1:]}, at {stage} stage.{history_clause}" if body else ""
    )

    return Score(entry.target, level, reason, fired=True, detail=detail)


# ===========================================================================
# issue_alerts
# ===========================================================================


@dataclass
class RunReport:
    """Observable outcome of one job run. Re-running must be safe AND legible."""

    farms: int = 0
    scored: int = 0
    issued: int = 0
    skipped_duplicate: int = 0
    below_threshold: int = 0
    suppressed_by_cap: int = 0
    no_tasks: int = 0
    weather_calls: int = 0
    errors: list[str] = field(default_factory=list)

    def render(self) -> str:
        lines = [
            f"  farms scored        {self.farms}",
            f"  farm x target pairs {self.scored}",
            f"  alerts issued       {self.issued}",
            f"  skipped, duplicate  {self.skipped_duplicate}",
            f"  below threshold     {self.below_threshold}",
            f"  suppressed, cap     {self.suppressed_by_cap}",
            f"  skipped, no tasks   {self.no_tasks}",
            f"  weather HTTP calls  {self.weather_calls}",
        ]
        if self.errors:
            lines.append(f"  errors              {len(self.errors)}")
            lines.extend(f"      - {e}" for e in self.errors)
        return "\n".join(lines)


def _meets_threshold(level: str) -> bool:
    return RISK_LEVELS.index(level) >= RISK_LEVELS.index(RISK_ALERT_MIN_LEVEL)


async def issue_alerts(session: AsyncSession, today: date | None = None) -> RunReport:
    """Score every farm against its crop's registry entries and issue Alerts.

    Idempotent by database constraint, not by a Python pre-check. A unique index
    on (farm_id, target, issued-on-date) is what makes a second run in the same
    day a no-op; a SELECT-then-INSERT would still race two concurrent runs.
    """
    registry = load_registry()
    tasks = load_inspection_tasks()
    report = RunReport()

    farms = list((await session.execute(select(Farm))).scalars().all())
    report.farms = len(farms)

    async with WeatherCache() as weather:
        for farm in farms:
            crop = farm.crop.value if hasattr(farm.crop, "value") else str(farm.crop)
            entries = [e for e in registry if e.crop == crop]

            window: WeatherWindow | None = None
            if any(e.uses_weather for e in entries):
                from geoalchemy2.shape import to_shape

                point = to_shape(farm.location)
                try:
                    window = await weather.window(point.y, point.x, farm.region)
                except Exception as exc:  # noqa: BLE001 - reported, never silent
                    report.errors.append(f"{farm.region}: {exc}")

            history = {
                row
                for row in (
                    await session.execute(
                        select(Problem.label).where(Problem.farm_id == farm.id)
                    )
                ).scalars().all()
                if row is not None
            }
            history_values = {h.value if hasattr(h, "value") else str(h) for h in history}

            # Score everything first, then rank and cap. Issuing inside the
            # scoring loop would let registry order decide which two targets a
            # farmer sees, which is arbitrary.
            candidates: list[tuple[RiskTarget, Score]] = []
            for entry in entries:
                report.scored += 1
                score = score_farm_target(
                    farm, entry, window, entry.target in history_values, today
                )
                if not score.fired or not _meets_threshold(score.level):
                    report.below_threshold += 1
                    continue
                candidates.append((entry, score))

            # Ranked by risk level, then by whether this farm has seen the target
            # before. A high-risk target the farmer has already had is the one
            # worth their walk across the field.
            candidates.sort(
                key=lambda pair: (
                    RISK_LEVELS.index(pair[1].level),
                    bool(pair[1].detail.get("history_bump")),
                ),
                reverse=True,
            )

            # Alerts already issued to this farm today count against the cap,
            # including F6 spread alerts — the farmer sees one list of cards, not
            # one per subsystem.
            already_today = int(
                await session.scalar(
                    select(func.count())
                    .select_from(Alert)
                    .where(
                        Alert.farm_id == farm.id,
                        text(
                            "(alert.issued_at AT TIME ZONE 'UTC')::date "
                            "= (now() AT TIME ZONE 'UTC')::date"
                        ),
                    )
                )
                or 0
            )
            budget = max(0, MAX_ALERTS_PER_FARM_PER_DAY - already_today)

            if len(candidates) > budget:
                # Suppressed, not lost: tomorrow's run re-evaluates every target
                # from scratch, so a target held back today reappears if it is
                # still favourable and still ranks.
                report.suppressed_by_cap += len(candidates) - budget
                candidates = candidates[:budget]

            for entry, score in candidates:
                target_tasks = tasks.get(entry.target, [])
                if len(target_tasks) < MIN_TASKS_PER_TARGET:
                    # Unreachable if load_inspection_tasks did its job; kept so a
                    # future corpus-sourced list cannot produce a taskless alert.
                    report.no_tasks += 1
                    continue

                alert = Alert(
                    farm_id=farm.id,
                    trigger_type=(
                        AlertTrigger.SEASONAL
                        if entry.driver == "phenology"
                        else AlertTrigger.WEATHER
                    ),
                    target=TargetLabel(entry.target),
                    risk_level=score.level,
                    # Frozen at issue time. It states what was true when the
                    # alert fired, not what the weather is now.
                    reason=score.reason,
                    inspection_tasks=target_tasks,
                )
                # SAVEPOINT per insert. A duplicate raises IntegrityError, and
                # on a plain session that aborts the WHOLE transaction — every
                # alert issued earlier in the run would be discarded, and the
                # next flush fails with MissingGreenlet. begin_nested confines
                # the rollback to this one row.
                try:
                    async with session.begin_nested():
                        session.add(alert)
                    report.issued += 1
                except IntegrityError:
                    report.skipped_duplicate += 1

        report.weather_calls = weather.calls

    await session.commit()
    return report
