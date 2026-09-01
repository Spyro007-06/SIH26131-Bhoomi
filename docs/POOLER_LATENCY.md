# Test-suite flakiness against Supabase — diagnosis, not a fix

**Status:** diagnosed 2026-09-01. Root cause is infrastructure (database
region), not application code. A bounded retry is a documented stopgap in
`backend/tests/conftest.py`'s `db_session` fixture, to be removed once the
project moves database region.

## Symptom

Roughly one test in a few hundred fails, intermittently, with:

```
sqlalchemy.exc.DBAPIError: (sqlalchemy.dialects.postgresql.asyncpg.Error)
<class 'asyncpg.exceptions.ConnectionDoesNotExistError'>: connection was
closed in the middle of operation
```

Re-running the failing test alone always passes. The full backend suite
(286 tests as of this writing) takes 5–13 minutes depending on whether the
flake hits, against ~1–2 seconds of actual test logic per DB-touching test.

**Rate varies a lot within one day.** Morning runs this same day saw roughly
one failure in a few hundred tests. A run later the same day against a
19-test file hit the identical failure signature once — a much higher
apparent rate in that smaller sample. Consistent with a network-path or
pooler-side cause rather than a fixed per-connection probability: whatever
is dropping connections is itself intermittent at a coarser timescale than
"one in N attempts."

## What was ruled out, and how

**Stale pooled connections reused across a dead event loop.** The first
hypothesis: `pytest-asyncio` gives each test function its own event loop
(`asyncio_default_fixture_loop_scope = "function"`), and asyncpg connections
are bound to the loop that opened them — a connection checked out from a
pool by test N could be a connection opened under test N-1's now-closed
loop. `backend/tests/conftest.py`'s `db_session` fixture already uses
`NullPool` with a fresh `create_async_engine()` per test and explicit
`engine.dispose()` on teardown, specifically to prevent this — no connection
in this fixture is ever reused across two tests.

**Ruled out by reproduction, not just inspection:** the failure was
reproduced live (twice, independently, in different test files) with this
NullPool-per-test fixture already in place. In both cases the connection was
**brand new** for that test — opened, used for one `SAVEPOINT` or one
`SELECT`, then closed by the remote end mid-operation. A dead-loop reuse bug
cannot produce this signature: there is no reused connection to be stale.

**Sequential test execution.** No `pytest-xdist`; the suite already runs as
a single process, one test at a time. Concurrent-connection pressure from
the test runner itself is not the cause.

## The actual cause

The Supabase project's database is in `ap-northeast-1` (Tokyo). This team
develops from Maharashtra, India — round-trip latency to Tokyo is
consistently observed around 130ms, against Mumbai (`ap-south-1`) which
would be single-digit milliseconds. Every one of the ~286 tests that touches
the database opens a fresh physical connection (by design, for the reason
above), and every one of those connections is a fresh TCP+TLS handshake
across that same long-haul path. At that connection churn rate and that
latency, an occasional connection is dropped mid-operation by the network
path or by Supabase's session pooler timing out a slow handshake — this is
consistent with, though not conclusively distinguished from, the pooler
itself recycling a connection under the sustained churn. Either way, the
proximate cause is round-trip time to Tokyo, not anything about how this
codebase pools or reuses connections.

The 5–13 minute suite runtime (recent range) is the same root cause: at
~130ms RTT, a fresh connection plus a query plus a rollback plus disposal,
repeated ~286 times, adds up even when nothing fails.

## The fix

Move the Supabase project to `ap-south-1` (Mumbai). Out of scope for this
note — tracked separately by the project owner.

## The stopgap, until the move

`backend/tests/conftest.py`'s `db_session` fixture retries connection
**acquisition** (opening the connection and beginning the outer
transaction) up to 3 times with a short backoff, specifically on
`ConnectionDoesNotExistError` or `ConnectionResetError` from asyncpg. Each
attempt is also wrapped in a 15-second `asyncio.wait_for` timeout: a dropped
connection raises promptly and retries cleanly, but a connection that goes
half-open (accepted at the TCP level, never answers) does not raise at
all — without a bound, that hangs the whole suite instead of retrying.
`asyncio.TimeoutError` is treated the same as a dropped connection for retry
purposes. It does **not** retry a failure that occurs after acquisition succeeds, mid-test
— that would mask a test actually failing, not paper over a connect-time
network blip. It does **not** touch `app/db.py` or production request
handling: a retry on the request path would silently mask a real outage
behind added latency, which is the opposite of what a 503 is for. Remove the
retry loop when the region moves; it will simply stop firing before that
(a connect-time flake at Mumbai latency is not the failure mode this guards
against), but leaving retry logic in place past its reason is its own kind
of debt.
