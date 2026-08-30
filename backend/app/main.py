"""FastAPI app factory, /api/v1 mount and health.

Owner: Shreekumar. Spec: docs/API_CONTRACT.md §0, docs/DESIGN.md §12.

Phase 0 mounts health and nothing else. Routers land in app/core/routers/ from
Phase 1 onward and are included here.
"""

from __future__ import annotations

import logging
from contextlib import asynccontextmanager

from fastapi import APIRouter, FastAPI

from app import config
from app.config import settings
from app.core.routers import (
    alerts,
    assets,
    auth,
    cases,
    farms,
    followups,
    officials,
    problems,
)
from app.db import dispose_engine
from app.errors import register_exception_handlers
from app.scheduler import shutdown_scheduler, start_scheduler

logging.basicConfig(level=settings.log_level)
log = logging.getLogger("bhoomi")

health_router = APIRouter(tags=["health"])


@health_router.get("/health")
async def health() -> dict:
    """Liveness plus the flag values.

    The flags are in the body on purpose. docs/DESIGN.md §12: "Silent stubs are
    how a demo dies." Anyone can read off this endpoint whether they are looking
    at a real classifier or a stub, without reading a config file on a laptop
    that may not be the one serving the port.
    """
    return {
        "status": "ok",
        "app_env": settings.app_env,
        "api_version": "v1",
        "flags": {
            "VISION_MODEL": settings.vision_model,
            "ASR_PROVIDER": settings.asr_provider,
            "LLM_ENABLED": settings.llm_enabled,
        },
        "thresholds": {
            "GATE": config.GATE,
            "FLOOR": config.FLOOR,
            "MARGIN": config.MARGIN,
            "RAG_THRESHOLD": config.RAG_THRESHOLD,
        },
    }


@asynccontextmanager
async def lifespan(_: FastAPI):
    log.info(
        "bhoomi starting | env=%s VISION_MODEL=%s ASR_PROVIDER=%s LLM_ENABLED=%s",
        settings.app_env,
        settings.vision_model,
        settings.asr_provider,
        settings.llm_enabled,
    )
    if settings.vision_model == "stub":
        log.warning(
            "VISION_MODEL=stub - every TopK carries is_stub=true and clients MUST "
            "render a stub banner. See docs/DESIGN.md section 12."
        )
    start_scheduler()
    yield
    shutdown_scheduler()
    await dispose_engine()


def create_app() -> FastAPI:
    app = FastAPI(
        title="Bhoomi v2",
        version="2.0.0",
        description=(
            "SIH26131 — early detection and management of crop diseases and pest "
            "infestations. Wire format is frozen in docs/API_CONTRACT.md."
        ),
        lifespan=lifespan,
    )

    register_exception_handlers(app)

    api = APIRouter(prefix=settings.api_prefix)
    api.include_router(health_router)
    api.include_router(auth.router)
    api.include_router(assets.router)
    api.include_router(farms.router)
    api.include_router(problems.router)
    api.include_router(alerts.router)
    api.include_router(followups.router)
    api.include_router(cases.router)
    api.include_router(officials.router)
    # Phase 2+: problems, timeline. Phase 3+: alerts, followups. Each router
    # module is included here as its owner implements it.
    app.include_router(api)

    return app


app = create_app()
