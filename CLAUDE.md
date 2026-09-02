# CLAUDE.md — Bhoomi v3 backend

SIH26131 · Government of Maharashtra · early detection and management of crop
diseases and pest infestations. Six people.

**Scope is v3: four crops (paddy, cotton, soybean, jowar) and 26 targets.**
Targets are namespaced by crop — `cotton_bacterial_blight`, not
`bacterial_blight` — because the same disease name occurs in more than one crop,
and the prefix makes a wrong-crop match unrepresentable rather than filtered.
Each carries a `target_tier`: `diagnosable` (14, in the vision label set) or
`inspection` (12, never image-classified). `docs/DATA_MODEL_ADDENDUM.md` is gone;
every decision it held is folded into the three frozen documents.

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
| `backend/app/contracts/` | **team — frozen** | C1, C2, C3 and every wire enum |
| `backend/app/core/` | Shreekumar | ORM models, CRUD, risk engine, alerts, spread, follow-up, confirmation |
| `backend/app/vision/` | Suchit | `classify(image) -> TopK`, `extract_label(image) -> LabelExtract` |
| `backend/app/intelligence/` | Thaariha | `decide()`, `compose()`, `verdict()`, `compile_bundle()` |
| `backend/app/voice/` | Shruthi | `transcribe()`, `synthesize()`, `to_embedding_text()` |
| `backend/app/` root modules: `main.py` `config.py` `db.py` `deps.py` `errors.py` | Shreekumar | app foundation |
| `app/` (repo root) | Tharun (Santheesh support) | Flutter farmer app |
| `portal/` | Santheesh | agronomist portal F12, officials dashboard F15 |

Review routing is in `CODEOWNERS`. Do not edit a module you do not own
without telling its owner. If you need
something from another module, ask for a function, not a table.

**`backend/app/core/` is the only package that touches the database.** `intelligence/`
never queries directly — `core/` reads the rows and hands it typed objects
(`docs/DESIGN.md` §3).

---

## The rules that are not negotiable

### 1. `backend/app/contracts/` is frozen

Frozen at hour 2. Four workstreams and two clients build against these shapes.
Reopening one costs more than living with an imperfect shape. If something in
there is wrong, raise it with the team — do not edit it in a pull request.

- **C1** `backend/app/contracts/vision.py` — `Prediction`, `TopK` · vision → intelligence
- **C2** `backend/app/contracts/farm.py` — `Farm`, `GeoPoint` · core → everyone
  (v3: `growth_stage` is a `stage_key` string, not an enum — stages are rows in
  `growth_stage` keyed (crop, stage_key), and a composite FK stops a farm holding
  another crop's stage)
- **C3** `backend/app/contracts/gate.py` — `GateDecision`, the six verdict strings · intelligence → clients
- `backend/app/contracts/enums.py` — every wire enum, exact string values from API_CONTRACT §1

### 2. Constants live only in `backend/app/config.py`

`docs/DESIGN.md` §6, verbatim: *"Constants live here and nowhere else. A
threshold literal appearing in a second file is a bug."*

`GATE`, `FLOOR`, `MARGIN`, `RAG_THRESHOLD`, `OCR_FLOOR`, `ASR_FLOOR`,
`SPREAD_RADIUS_M`, `FOLLOWUP_DUE_DAYS`, `PRIOR_MAX_BIAS`. Import them. Do not
re-declare one locally, and do not inline the number.

`backend/tests/test_config.py::test_thresholds_are_declared_only_in_config` walks
the AST of every module under `backend/app/` and fails if one is bound outside
`config.py`.

The gate thresholds are **module constants, not settings fields** — the gate must
not be tunable by whoever controls the environment at demo time. Only deployment
wiring and the three feature flags read from env.

### 3. One error envelope

`docs/API_CONTRACT.md` §0. Raise `BhoomiError` (or a subclass) from
`backend/app/errors.py`; the handler registered in `backend/app/main.py` renders
it. No endpoint
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

The pull request template makes the pasted response a required field. A PR with
no HTTP surface — a migration, a README, a scaffold commit — says so and pastes
whatever does verify it.

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

### 7. Structure-only modules stay structure-only

`backend/app/core/routers/` and `backend/app/core/services/` are headers: a
docstring naming the owner, the feature and the specifying docs section, and
nothing else. Do not add a placeholder class, a stub route or a "just to get
something working" model to a module you do not own — its owner has to delete it
before they can start, which is worse than an empty file.

`backend/tests/test_structure.py` enforces this by AST: one top-level statement
per module, and it must be the docstring. When you implement a module you own,
drop it from that test's coverage in the same commit.

### 8. Commit after every change, however small

One logical change = one commit = one push. Not batched at the end of a task.
Not "I'll commit once the tests pass." Fixing a comment is a commit. Changing
one number is a commit. Adding one test is a commit. Every version must be
recorded and independently revertible.

Before each push: `git fetch && git rebase origin/main`, re-run pytest. Never
commit `backend/.env`.

---

## Layout — three stacks

```
backend/           Python API          Shreekumar
app/               Flutter farmer app  Tharun
portal/            React portal        Santheesh
docs/              frozen specs — read, do not edit. Shared by all three.
```

### The name collision — read this before you grep

**`app/` at repo root is the Flutter app. `backend/app/` is the Python package.**

Both names come from `docs/DESIGN.md` §3, which calls the Flutter module `app/`,
and from the Phase 0 layout, which calls the Python package `app/`. The docs are
frozen, so both names stay and the prefix disambiguates them.

Consequences worth internalising:

- `from app.config import ...` in Python always means `backend/app/`. Python never
  sees the Flutter directory.
- A repo-wide `grep -rn "app/"` will hit both. Scope your searches to a stack.
- CODEOWNERS routes `/app/` to Tharun and `/backend/app/` to the backend owners.
  A path pattern that forgets the prefix routes reviews to the wrong person.

### Inside `backend/`

```
backend/
  app/
    main.py          app factory, /api/v1 mount, health
    config.py        EVERY tunable constant, and nothing else has any
    db.py            async engine, Base, session dependency
    errors.py        error envelope + the stable code enum
    deps.py          auth dependency, role guard
    contracts/       THE THREE FROZEN CONTRACTS
    core/            Shreekumar — models.py, schemas/, routers/, services/
    vision/          Suchit
    intelligence/    Thaariha
    voice/           Shruthi
  alembic/versions/  migrations
  tests/  seed/  scripts/
```

---

## Running it

Every backend command runs from `backend/`, not from the repo root.

```bash
cd backend
docker compose up -d
python -m venv .venv && .venv/bin/pip install -e ".[dev]"   # Scripts\ on Windows
cp .env.example .env
alembic upgrade head
uvicorn app.main:app --reload
pytest
ruff check app tests alembic
```

`docker compose up -d` leaves `bhoomi-minio-bucket` in state `exited (0)`. That
is the bucket sidecar finishing successfully, not a crash.

### Machine note — techpark-9 has no Docker

**The compose stack above is the canonical setup and stays that way.** If you
have Docker, use it; nothing in `docker-compose.yml` or
`backend/docker/postgres/Dockerfile` has been changed for the exception below.

On **techpark-9** Docker cannot be installed — no sudo, blocked indefinitely. That
machine verifies against a **Supabase** Postgres instead, configured entirely in
`backend/.env` (gitignored), which nobody else needs to change:

- Connect through the **Session pooler** (`aws-0-<region>.pooler.supabase.com:5432`,
  user `postgres.<project-ref>`). The direct `db.<ref>.supabase.co` host is
  **AAAA-only** and does not resolve on an IPv4-only machine.
- If the password contains a URL-reserved character, percent-encode it. `@`
  becomes `%40`, otherwise the URL splits at the wrong `@`.
- That deployment is **PostgreSQL 17** with PostGIS 3.3 and pgvector 0.8, against
  the pinned `postgis/postgis:16-3.4` everywhere else. Schema verified on 17 is
  not automatically verified on 16 — worth a second run by someone with Docker
  before the freeze.
- Supabase installs `postgis` and `vector` into `public`, not `extensions`, so
  `alembic/env.py` filters PostGIS's catalog tables out of autogenerate.

### Test database

`backend/tests/conftest.py`'s `db_session` fixture reads `TEST_DATABASE_URL`,
not `DATABASE_URL` — set it in `backend/.env` (gitignored) to a database
separate from the one `DATABASE_URL` points at, so a live-verification curl
and the pytest suite can never collide on the same seed rows (`LabelPrior`,
the demo `Problem`/`Diagnosis` case, `registered_use`). Unset falls back to
`DATABASE_URL`, so nobody's local `docker-compose` setup needs to change.

**A second database, not a second schema.** A schema can't be selected from
a bare connection URL on the asyncpg driver this project pins — SQLAlchemy's
asyncpg dialect does not forward the `options=-csearch_path=...` query
parameter psycopg accepts, and `conftest.py`'s engine creation is
URL-only by design (`docs/POOLER_LATENCY.md`'s stopgap already touches that
function; this phase deliberately doesn't touch it further). A second
database needs nothing beyond a different path segment in the URL, works
with the engine-creation code exactly as it stands, and is genuinely
isolated at the Postgres level rather than sharing a `search_path`.

On the Supabase Session pooler specifically: `CREATE DATABASE` from the
project's own `postgres` role works, and the pooler happily routes to the
new database by name in the connection path — confirmed live, not assumed.
Docker Compose users: create a second local Postgres database the same way
(`createdb bhoomi_test`) and run `alembic upgrade head` against it with
`ALEMBIC_DATABASE_URL` pointed there for that one run.

`app/` and `portal/` are scaffolded by their owners with their own tools. See
`app/README.md` and `portal/README.md`.

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
