"""Bhoomi v2 configuration — the single home for every tunable constant.

Owner: Shreekumar. Spec: docs/DESIGN.md §6, §11, §12.

RULE (docs/DESIGN.md §6): "Constants live here and nowhere else. A threshold
literal appearing in a second file is a bug." Import from this module. Do not
re-declare a threshold, a radius or a floor anywhere else in the tree.
"""

from __future__ import annotations

from functools import lru_cache
from typing import Literal

from pydantic import Field
from pydantic_settings import BaseSettings, SettingsConfigDict

# ---------------------------------------------------------------------------
# Gate thresholds — docs/DESIGN.md §6.
# These three carry the product's "never fabricate" guarantee. They are module
# constants rather than settings fields because the gate must not be tunable by
# whoever controls the environment at demo time.
# ---------------------------------------------------------------------------

GATE = 0.70
"""Top-1 confidence at or above this, and clear of the runner-up, → advise."""

FLOOR = 0.45
"""Top-1 confidence below this → never engage the farmer, escalate."""

MARGIN = 0.15
"""Minimum top1-top2 gap to call a prediction clear. Below → clarify."""

RAG_THRESHOLD = 0.60
"""Minimum retrieval relevance before an advisory may be composed."""

# ---------------------------------------------------------------------------
# Perception floors — docs/DESIGN.md §9, docs/API_CONTRACT.md §4, §9.
# Below these the system says it could not read/hear rather than guessing.
# ---------------------------------------------------------------------------

OCR_FLOOR = 0.60
"""Below this OCR confidence the label check returns OCR_UNREADABLE."""

ASR_FLOOR = 0.60
"""Below this ASR confidence parsed_intent is omitted and the client re-prompts."""

# ---------------------------------------------------------------------------
# Spread, follow-up and the confirmation prior — docs/DESIGN.md §10, §11.
# ---------------------------------------------------------------------------

SPREAD_RADIUS_M = 2000
"""Radius for F6 spread alerts, metres. docs/PRD.md §10 leaves the exact value
open; 2 km is the working default and is overridable per deployment only by
editing this line, not by environment."""

RISK_LEVELS = ("low", "moderate", "high")
"""Ordered, lowest first. Index position is the comparison."""

RISK_ALERT_MIN_LEVEL = "moderate"
"""Score at or above this level issues an Alert. Below it, nothing is written.

A module constant, not a settings field: an environment that can lower this can
flood every farmer with low-confidence alerts, and an alert nobody trusts is
worse than no alert. docs/PRD.md section 5."""

WEATHER_PAST_DAYS = 7
"""Trailing days requested from Open-Meteo alongside the forecast.

The favourability rules need a multi-day window ("humidity above 90% for 4
consecutive nights"). That looks like it needs a stored weather history; it does
not, because Open-Meteo's past_days returns the trailing week in the same call.
A weather-observation table would be state someone has to keep fresh, and a gap
in it silently weakens every rule that reads it."""

WEATHER_TIMEOUT_SECONDS = 15

CASE_ETA_MINUTES_PER_POSITION = 15
"""Minutes of expected wait per place in the agronomist queue.

docs/API_CONTRACT.md §12 returns eta_minutes on escalation. A crude linear
estimate, stated as such: the alternative is either no ETA at all, or a
model of agronomist throughput this build has no data to fit."""

FOLLOWUP_DUE_DAYS = 4
"""Days after an advisory before the follow-up check-in falls due.

Four, not five, to match the demo scenario: docs/PRD.md §6 step 8 is "Day 4: got
worse, with a new photo. Severity promotes, auto-escalation fires."
"""

OTP_LENGTH = 6
"""Digits in a one-time code. docs/API_CONTRACT.md §2."""

OTP_MAX_ATTEMPTS = 5
"""Verification attempts allowed against one OtpRequest before it is dead.

A module constant rather than a settings field: an environment that can raise
this can turn the verify endpoint back into a brute-force oracle."""

PRIOR_FULL_CONFIDENCE_COUNT = 10
"""Net confirmations that earn the full PRIOR_MAX_BIAS nudge.

Ten gets the whole nudge, five gets half, and a label corrected as often as it
is confirmed gets nothing. Linear and readable off a screen on purpose —
docs/DESIGN.md §11 warns that dressing this up as learning invites a question
with no good answer on stage."""

PRIOR_MAX_BIAS = 0.05
"""Cap on the additive bias the confirmation prior may apply to a vision
confidence before the gate sees it. docs/DESIGN.md §11: the prior must never be
able to move a prediction across a gate band on its own."""

# ---------------------------------------------------------------------------
# The §11 invariant, asserted rather than commented.
#
# A bias smaller than MARGIN cannot turn an ambiguous pair into a clear one, and
# a bias smaller than (GATE - FLOOR) cannot carry a prediction from below the
# floor to above the gate. Both must hold, at import time, on every process.
# ---------------------------------------------------------------------------

assert PRIOR_MAX_BIAS < MARGIN, (
    f"PRIOR_MAX_BIAS ({PRIOR_MAX_BIAS}) must be smaller than MARGIN ({MARGIN}): "
    "otherwise the confirmation prior could resolve an ambiguous pair by itself. "
    "docs/DESIGN.md §11."
)

assert PRIOR_MAX_BIAS < (GATE - FLOOR), (
    f"PRIOR_MAX_BIAS ({PRIOR_MAX_BIAS}) must be smaller than GATE - FLOOR "
    f"({GATE - FLOOR:.2f}): otherwise the confirmation prior could carry a "
    "prediction from escalate to advise by itself. docs/DESIGN.md §11."
)


class Settings(BaseSettings):
    """Environment-driven configuration.

    Deployment wiring and feature flags only. Decision thresholds are the module
    constants above and are deliberately not settable from the environment.
    """

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        extra="ignore",
        case_sensitive=False,
    )

    app_env: str = "local"
    log_level: str = "INFO"
    api_prefix: str = "/api/v1"

    # --- Database ---
    database_url: str = "postgresql+asyncpg://bhoomi:bhoomi@localhost:5432/bhoomi"
    alembic_database_url: str = "postgresql+psycopg://bhoomi:bhoomi@localhost:5432/bhoomi"
    db_echo: bool = False

    # --- Object storage ---
    s3_endpoint_url: str = "http://localhost:9000"
    s3_public_endpoint_url: str = "http://localhost:9000"
    s3_access_key: str = "bhoomi"
    s3_secret_key: str = "bhoomi123"
    s3_bucket: str = "bhoomi-assets"
    s3_region: str = "us-east-1"
    presign_expiry_seconds: int = Field(default=600, ge=60, le=3600)

    # --- Auth ---
    jwt_secret: str = "dev-secret-change-me"
    jwt_algorithm: str = "HS256"
    access_token_expire_minutes: int = 720
    refresh_token_expire_days: int = 30
    otp_expire_seconds: int = 300

    dev_fixed_otp: str | None = None
    """Local-only escape hatch so the demo does not need an SMS provider.

    Applies ONLY when app_env == "local" AND this is set. Unset means codes are
    always generated, in every environment — see core/security.py, which refuses
    to apply it rather than falling back to a default."""

    scheduler_enabled: bool = False
    """Off by default so running the API locally does not fire live jobs
    against shared data. The risk sweep is idempotent by database constraint,
    so enabling it on more than one replica is safe."""

    # --- Feature flags, docs/DESIGN.md §12 ---
    vision_model: Literal["real", "stub"] = "stub"
    asr_provider: Literal["live", "stub"] = "stub"
    llm_enabled: bool = False

    # --- Weather, F5 ---
    open_meteo_base_url: str = "https://api.open-meteo.com/v1/forecast"


@lru_cache
def get_settings() -> Settings:
    """Process-wide settings singleton."""
    return Settings()


settings = get_settings()
