# Bhoomi v2 — backend

**SIH26131** · Government of Maharashtra · early detection and management of crop
diseases and pest infestations.

A crop-health system that refuses to guess. A deterministic confidence gate sits
in front of every consequential response: above the gate it composes advice from
retrieved sources, in the ambiguous band it asks the farmer one distinguishing
question, and below the floor it sends the case to a human. Pesticide verdicts
are a table lookup, never a model output.

Specifications live in `docs/` and are frozen:

- [`docs/PRD.md`](docs/PRD.md) — what and why
- [`docs/DESIGN.md`](docs/DESIGN.md) — architecture, data model, the three algorithms
- [`docs/API_CONTRACT.md`](docs/API_CONTRACT.md) — wire format

Contributors: read [`CLAUDE.md`](CLAUDE.md) first. It carries module ownership and
the rules that are not negotiable.

---

## Quick start

Requires Docker and **Python 3.11**.

```bash
docker compose up -d
```

Brings up Postgres 16 with PostGIS and pgvector, MinIO, and a sidecar that
creates the `bhoomi-assets` bucket. The sidecar shows as `exited (0)` when it has
done its job — that is success, not a crash.

```bash
python -m venv .venv
.venv/Scripts/pip install -e ".[dev]"     # Windows
# .venv/bin/pip install -e ".[dev]"       # Linux / macOS

cp .env.example .env
alembic upgrade head
uvicorn app.main:app --reload
```

Then:

```bash
curl localhost:8000/api/v1/health
```

```json
{
  "status": "ok",
  "app_env": "local",
  "api_version": "v1",
  "flags": { "VISION_MODEL": "stub", "ASR_PROVIDER": "stub", "LLM_ENABLED": false },
  "thresholds": { "GATE": 0.7, "FLOOR": 0.45, "MARGIN": 0.15, "RAG_THRESHOLD": 0.6 }
}
```

The flags are in the body deliberately. You can tell from the port whether a stub
is serving, without trusting a config file on a laptop that may not be the one
answering.

```bash
pytest
ruff check app tests alembic
```

---

## Layout

```
app/contracts/     the three frozen contracts + wire enums
app/core/          schema, CRUD, risk engine, alerts, spread, follow-up
app/vision/        classifier + OCR
app/intelligence/  gate, Doubt Doctor, RAG, verdicts, case bundles
app/voice/         ASR, TTS, translate-before-embed
```

Ownership per module is in [`CLAUDE.md`](CLAUDE.md).

## Feature flags

`VISION_MODEL=real|stub` · `ASR_PROVIDER=live|stub` · `LLM_ENABLED=true|false`

With `VISION_MODEL=stub` every `TopK` carries `is_stub: true` and clients must
show a stub banner. The stub returns a fixed distribution that never reads the
image and cannot reach the advise band on any gate path.

## Licence

See [`LICENSE`](LICENSE).
