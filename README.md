# Bhoomi v2

**SIH26131** · Government of Maharashtra · early detection and management of crop
diseases and pest infestations.

A crop-health system that refuses to guess. A deterministic confidence gate sits
in front of every consequential response: above the gate it composes advice from
retrieved sources, in the ambiguous band it asks the farmer one distinguishing
question, and below the floor it sends the case to a human. Pesticide verdicts
are a table lookup, never a model output.

## The three stacks

```
backend/    Python · FastAPI · Postgres+PostGIS+pgvector    the API
app/        Flutter · Android                               farmer app
portal/     React · Vite · Tailwind · Leaflet               agronomist + officials
docs/       frozen specifications, shared by all three
```

> **Name collision, on purpose.** Root `app/` is the **Flutter** app.
> `backend/app/` is the **Python** package. Both names come from frozen docs —
> `docs/DESIGN.md` §3 calls the Flutter module `app/`, and the Phase 0 layout
> calls the Python package `app/` — so the prefix disambiguates rather than a
> rename. Scope repo-wide greps to one stack.

## Ownership

From `docs/DESIGN.md` §3 and `worksplitV1`. Review routing is in
[`CODEOWNERS`](CODEOWNERS).

| Directory | Owner | Delivers |
|---|---|---|
| `backend/app/core/` | Shreekumar | schema, CRUD, risk engine, alerts, spread, follow-up, confirmation |
| `backend/app/vision/` | Suchit | classifier, OCR extraction |
| `backend/app/intelligence/` | Thaariha | gate, Doubt Doctor, RAG, verdicts, case bundle |
| `backend/app/voice/` | Shruthi | ASR, TTS, translate-before-embed |
| `backend/app/contracts/` | team — **frozen** | C1, C2, C3 and every wire enum |
| `app/` | Tharun (Santheesh support) | Flutter farmer app |
| `portal/` | Santheesh | agronomist portal (F12), officials dashboard (F15) |

Modules talk through typed functions, not by reaching into each other's tables.
`backend/app/core/` is the only package that touches the database.

## Specifications — frozen

- [`docs/PRD.md`](docs/PRD.md) — what and why, the fifteen features, the demo scenario
- [`docs/DESIGN.md`](docs/DESIGN.md) — architecture, data model, the three algorithms
- [`docs/API_CONTRACT.md`](docs/API_CONTRACT.md) — wire format, enums, error codes, invariants

Contributors read [`CLAUDE.md`](CLAUDE.md) first: it carries module ownership and
the rules that are not negotiable.

---

## Running each stack

### backend/

Requires Docker and **Python 3.11**.

```bash
cd backend
docker compose up -d
python -m venv .venv && .venv/Scripts/pip install -e ".[dev]"   # Windows
# python -m venv .venv && .venv/bin/pip install -e ".[dev]"     # Linux / macOS
cp .env.example .env
alembic upgrade head
uvicorn app.main:app --reload
```

`docker compose up -d` brings up Postgres 16 with PostGIS and pgvector, MinIO,
and a sidecar that creates the `bhoomi-assets` bucket. The sidecar shows as
`exited (0)` when it has done its job — that is success, not a crash.

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

### app/

Not scaffolded yet — the tree is directories and a README. See
[`app/README.md`](app/README.md).

```bash
cd app && flutter create . --project-name bhoomi
```

### portal/

Not scaffolded yet. See [`portal/README.md`](portal/README.md).

```bash
npm create vite@latest portal -- --template react-ts
```

---

## Verification standard

`docs/DESIGN.md` §13, and the one required field on every pull request:

> A feature is verified when a live HTTP response is pasted showing the expected
> output. Import success, build success, and "I ran it" are not verification.
> Before trusting any curl result, confirm which process is answering on the port
> and when it started; a stale server from a previous session has previously made
> working fixes appear broken for hours.

## Licence

See [`LICENSE`](LICENSE).
