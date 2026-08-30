"""APScheduler jobs: the F5 risk sweep and the F10 follow-up sweep.

OWNER: Shreekumar. Spec: docs/DESIGN.md §1 and §10.

-----------------------------------------------------------------------------
The scheduler is safe to run more than once, and safe not to run at all.

The risk job's idempotency is a unique index on
(farm_id, target, issued-on-date), migration 0004 — not a Python guard. So a
second firing, an overlapping run, or a hand-run during a demo all converge on
the same rows. That is what makes it acceptable to start this in-process
alongside the API rather than as a separate worker: two API replicas both
running the job produce one set of alerts, not two.

It is disabled by default (`SCHEDULER_ENABLED=false`) so that running the API
locally, or in a test, does not fire live jobs against shared data.
-----------------------------------------------------------------------------
"""

from __future__ import annotations

import logging

from apscheduler.schedulers.asyncio import AsyncIOScheduler
from apscheduler.triggers.cron import CronTrigger

from app.config import settings
from app.core.services.risk import issue_alerts
from app.db import SessionLocal

log = logging.getLogger("bhoomi.scheduler")

_scheduler: AsyncIOScheduler | None = None


async def run_risk_sweep() -> None:
    """Score every farm and issue alerts. Logs its report either way."""
    try:
        async with SessionLocal() as session:
            report = await issue_alerts(session)
        log.info(
            "risk sweep: issued=%d duplicate=%d below_threshold=%d weather_calls=%d",
            report.issued,
            report.skipped_duplicate,
            report.below_threshold,
            report.weather_calls,
        )
        for error in report.errors:
            log.warning("risk sweep error: %s", error)
    except Exception:
        # Logged, never raised: an unhandled exception inside an APScheduler job
        # kills the job's future silently and the next fire never happens.
        log.exception("risk sweep failed")


async def run_followup_sweep() -> None:
    """Log check-ins that have come due.

    Deliberately does not notify anyone. There is no push channel in this build
    and the app reads `GET /farms/{id}/followups/pending` on open, so this sweep
    exists to make overdue check-ins visible in the logs rather than to invent a
    delivery mechanism.
    """
    from app.core.services.followup import due_followups

    try:
        async with SessionLocal() as session:
            due = await due_followups(session)
        log.info("follow-up sweep: %d check-in(s) due", len(due))
    except Exception:
        log.exception("follow-up sweep failed")


def start_scheduler() -> AsyncIOScheduler | None:
    """Start the scheduler if enabled. Returns None when it is not."""
    global _scheduler

    if not settings.scheduler_enabled:
        log.info("scheduler disabled (SCHEDULER_ENABLED=false)")
        return None

    _scheduler = AsyncIOScheduler(timezone="UTC")
    # 03:00 UTC is 08:30 IST — the alert is waiting when the farmer picks up
    # the phone, rather than arriving mid-afternoon when the field visit is over.
    _scheduler.add_job(
        run_risk_sweep, CronTrigger(hour=3, minute=0), id="risk_sweep", replace_existing=True
    )
    _scheduler.add_job(
        run_followup_sweep,
        CronTrigger(hour=3, minute=30),
        id="followup_sweep",
        replace_existing=True,
    )
    _scheduler.start()
    log.info("scheduler started: risk_sweep 03:00 UTC, followup_sweep 03:30 UTC")
    return _scheduler


def shutdown_scheduler() -> None:
    global _scheduler
    if _scheduler is not None:
        _scheduler.shutdown(wait=False)
        _scheduler = None
