"""Health endpoint. Definition of done step 3."""

from __future__ import annotations

from app import config


def test_health_returns_200_with_flags(client) -> None:
    res = client.get("/api/v1/health")
    assert res.status_code == 200

    body = res.json()
    assert body["status"] == "ok"
    assert body["api_version"] == "v1"
    assert set(body["flags"]) == {"VISION_MODEL", "ASR_PROVIDER", "LLM_ENABLED"}


def test_health_reports_the_real_thresholds(client) -> None:
    """The body must echo app.config, not a copy. docs/DESIGN.md section 6."""
    thresholds = client.get("/api/v1/health").json()["thresholds"]
    assert thresholds["GATE"] == config.GATE
    assert thresholds["FLOOR"] == config.FLOOR
    assert thresholds["MARGIN"] == config.MARGIN
    assert thresholds["RAG_THRESHOLD"] == config.RAG_THRESHOLD
