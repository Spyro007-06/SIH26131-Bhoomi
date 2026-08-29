# tests/services/

Service-layer tests, one module per service. No test code yet.

The invariants from `docs/DESIGN.md` §13 that belong here:

| Invariant | Guards | Service |
|---|---|---|
| Alert insert fails with empty `inspection_tasks` | F5 | `risk.py` |
| Prior adjustment cannot move a prediction across a gate band | F14 | `prior.py` |

The first must fail at the **database**, not in Python. `docs/DESIGN.md` §5 puts
it in the schema as a CHECK precisely so that a test asserting a Python-side
guard would be testing the wrong thing — write it so it would still fail if the
Python validation were deleted.

The second is guarded twice: `app/config.py` asserts the cap at import time, and
`tests/test_config.py` states the property. The test here covers the applied
bias, not just the constant.

Also belonging here, from `docs/DESIGN.md` §10 and §11:

- Only confirmed diagnoses drive spread alerts and hotspot points — `spread.py`,
  `aggregates.py`. An unconfirmed model output must not trigger village-wide
  alarm.
- An ingredient absent from `registered_use` returns `NOT_IN_RECORDS`, never an
  inferred verdict — `registered_use.py`.

The cross-language retrieval invariant (a Marathi query and its English
equivalent retrieve overlapping docs, F9) is not here. It belongs with
`app/voice/to_embedding_text()` and `app/intelligence/rag.py`, which are
Shruthi's and Thaariha's.
