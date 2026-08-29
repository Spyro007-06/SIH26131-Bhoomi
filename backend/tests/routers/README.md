# tests/routers/

Endpoint-level tests, one module per router. No test code yet — each lands with
the endpoint it covers.

The invariants from `docs/DESIGN.md` §13 that belong here, with the router that
must satisfy each:

| Invariant | Guards | Router |
|---|---|---|
| Gate returns each of three outcomes on fixed inputs | F2 | `diagnose.py` |
| No advisory object exists on any non-`advise` path | F2, F7 | `diagnose.py`, `advisory.py` |
| Non-discriminating Doubt Doctor answer escalates, never tiebreaks | F4 | `clarify.py` |
| Advisory rejected when ladder is not chemical-last | F7 | `advisory.py` |
| Every label-check verdict string is free of endorsement vocabulary | F8 | `labelcheck.py` |
| Case bundle on a live case contains zero placeholder strings | F12 | `cases.py` |

Plus the response-shape invariants from `docs/API_CONTRACT.md` §17 — every
diagnose response carries a `gate` object, exactly one of `advisory` /
`clarification` / `escalation` appears, and `gate.alternatives` is populated on
all three branches.

Two of these exist because they have failed before in this project's history:
the case-bundle placeholder test and the prior-cap test in `../services/`.

`docs/DESIGN.md` §13 also sets the standard these tests are held to: a feature is
verified when a live HTTP response is pasted showing the expected output. A green
test here is necessary, not sufficient.
