# CLAUDE.md — Bhoomi v2 backend

SIH26131 · Government of Maharashtra · early detection and management of crop
diseases and pest infestations. 36-hour hackathon build, six people.

**Read `docs/` before writing anything.** `docs/PRD.md` (what and why),
`docs/DESIGN.md` (how), `docs/API_CONTRACT.md` (wire format). They are frozen
specifications, not suggestions. Where a prompt and those docs disagree, the docs
win — say so rather than picking one.

---

## Stack — fixed, do not substitute

| Layer | Choice |
|---|---|
| Runtime | Python 3.11 |
| API | FastAPI, Pydantic v2 |
| ORM | SQLAlchemy 2.0 async, asyncpg |
| Database | PostgreSQL 16 + PostGIS + pgvector (geoalchemy2, pgvector[sqlalchemy]) |
| Migrations | Alembic (sync, psycopg) |
| Object storage | MinIO / S3-compatible, **presigned uploads only** — the API never receives raw bytes |
| Vision | PyTorch, bounded classifier, in-process |
| Embeddings | BGE-m3 via pgvector |
| Scheduling | APScheduler |
| Weather | Open-Meteo |
| Tests | pytest, pytest-asyncio, httpx |

Every dependency is pinned in `pyproject.toml`. Pin anything you add.

---

## Module ownership

Modules talk through typed functions, not by reaching into each other's tables.

| Path | Owner | Exposes |
|---|---|---|
| `app/contracts/` | **team — frozen** | C1, C2, C3 and every wire enum |
| `app/core/` | Shreekumar | ORM models, CRUD, risk engine, alerts, spread, follow-up, confirmation |
| `app/vision/` | Suchit | `classify(image) -> TopK`, `extract_label(image) -> LabelExtract` |
| `app/intelligence/` | Thaariha | `decide()`, `compose()`, `verdict()`, `compile_bundle()` |
| `app/voice/` | Shruthi | `transcribe()`, `synthesize()`, `to_embedding_text()` |
| `app/main.py` `config.py` `db.py` `deps.py` `errors.py` | Shreekumar | app foundation |

Do not edit a module you do not own without telling its owner. If you need
something from another module, ask for a function, not a table.

**`app/core/` is the only package that touches the database.** `intelligence/`
never queries directly — `core/` reads the rows and hands it typed objects
(`docs/DESIGN.md` §3).

---

## The rules that are not negotiable

### 1. `app/contracts/` is frozen

Frozen at hour 2. Four workstreams and two clients build against these shapes.
Reopening one costs more than living with an imperfect shape. If something in
there is wrong, raise it with the team — do not edit it in a pull request.

- **C1** `contracts/vision.py` — `Prediction`, `TopK` · vision → intelligence
- **C2** `contracts/farm.py` — `Farm`, `GeoPoint` · core → everyone
- **C3** `contracts/gate.py` — `GateDecision`, the six verdict strings · intelligence → clients
- `contracts/enums.py` — every wire enum, exact string values from API_CONTRACT §1

### 2. Constants live only in `app/config.py`

`docs/DESIGN.md` §6, verbatim: *"Constants live here and nowhere else. A
threshold literal appearing in a second file is a bug."*

`GATE`, `FLOOR`, `MARGIN`, `RAG_THRESHOLD`, `OCR_FLOOR`, `ASR_FLOOR`,
`SPREAD_RADIUS_M`, `FOLLOWUP_DUE_DAYS`, `PRIOR_MAX_BIAS`. Import them. Do not
re-declare one locally, and do not inline the number.

`tests/test_config.py::test_thresholds_are_declared_only_in_config` walks the AST
of every module under `app/` and fails if one is bound outside `config.py`.

The gate thresholds are **module constants, not settings fields** — the gate must
not be tunable by whoever controls the environment at demo time. Only deployment
wiring and the three feature flags read from env.

### 3. One error envelope

`docs/API_CONTRACT.md` §0. Raise `BhoomiError` (or a subclass) from
`app/errors.py`; the handler registered in `app/main.py` renders it. No endpoint
hand-rolls an error body. Adding a code to `ErrorCode` is a deliberate act.

### 4. Verification — `docs/DESIGN.md` §13

> A feature is verified when a live HTTP response is pasted showing the expected
> output. Import success, build success, and "I ran it" are not verification.
> Before trusting any curl result, confirm which process is answering on the port
> and when it started; a stale server from a previous session has previously made
> working fixes appear broken for hours.

On Windows:

```powershell
Get-NetTCPConnection -LocalPort 8000 -State Listen | ForEach-Object { Get-Process -Id $_.OwningProcess | Select-Object Id, Path, StartTime }
```

On Linux/macOS: `lsof -i :8000` then `ps -o pid,lstart,cmd -p <pid>`.

### 5. The stub must be visibly a stub

`docs/DESIGN.md` §12, `docs/PRD.md` §4: a stub that returns confident output on
arbitrary input is worse than no feature.

`VISION_MODEL=stub` makes `classify()` return a fixed distribution that never
reads the image, with `is_stub=true`, and logs a warning on every call. The
values (0.34 / 0.33 / 0.33) sit below `FLOOR` and inside `MARGIN`, so the stub is
structurally incapable of producing an advisory on any gate path. Keep that
property if you touch it.

`is_stub` travels to the client and the client **must** render a banner.

### 6. Safety invariants that live in the schema, not in Python

- `Alert.inspection_tasks` non-empty — Postgres CHECK. An alert without a task is
  noise, and enforcing it in Python means someone bypasses it at hour 25.
- `Advisory.ladder` chemical-last — enforced on write. The PRD's structural claim
  about pesticide ordering is only true if the database refuses to store it
  otherwise.
- No verdict message contains "safe", "approved", "you can use" or any
  endorsement phrasing. The vocabulary itself makes endorsement impossible.
  This is a review checklist item, not a style preference.
- Only **confirmed** diagnoses drive spread alerts and hotspot points.

---

## Layout

```
app/
  main.py          app factory, /api/v1 mount, health
  config.py        EVERY tunable constant, and nothing else has any
  db.py            async engine, Base, session dependency
  errors.py        error envelope + the stable code enum
  deps.py          auth dependency, role guard
  contracts/       THE THREE FROZEN CONTRACTS
  core/            Shreekumar — models, schemas, routers/, services/
  vision/          Suchit
  intelligence/    Thaariha
  voice/           Shruthi
alembic/versions/  migrations
docs/              frozen specs — read, do not edit
tests/  seed/  scripts/
```

---

## Running it

```bash
docker compose up -d
python -m venv .venv && .venv/bin/pip install -e ".[dev]"   # Scripts\ on Windows
cp .env.example .env
alembic upgrade head
uvicorn app.main:app --reload
pytest
```

`docker compose up -d` leaves `bhoomi-minio-bucket` in state `exited (0)`. That
is the bucket sidecar finishing successfully, not a crash.

---

## Phases

| Phase | Delivers |
|---|---|
| 0 ✅ | Repo skeleton, frozen contracts, config, compose, health |
| 1 | Full ORM + both CHECKs, auth, `/assets/presign`, `/farms/*`, seed |
| 2 | `registered_use` + lookup, timeline / problems reads |
| 3 | Open-Meteo, favourability scoring, alerts, follow-ups |
| 4 | PostGIS spread fan-out, confirmation, capped prior, aggregates |
| 5 | The nine invariant tests, demo seed, error coverage |

Do not build ahead of the current phase. Phase 1 hardens the schema around the
contracts, so the contracts get reviewed first.
