# seed/

Demo and development seed data. Seed scripts are idempotent: running one twice
must not duplicate rows.

## Contents

| Path | Phase | Status |
|---|---|---|
| `registered_use.csv` | 2 | **Empty — unowned blocker.** Header row only |
| `corpus/` | 2 | **Empty — unowned blocker.** See `corpus/README.md` |
| Nashik farms | 1 | Not written yet. Three farms with real coordinates |
| Demo scenario | 5 | Not written yet. `docs/PRD.md` §6 end to end |

## registered_use.csv — F8's lookup table

`docs/DESIGN.md` §5 and §9. Twenty rows covering common paddy products, sourced
from **CIB&RC** and the **Maharashtra package of practices**.

Columns:

```
active_ingredient,crop,target,pesticide_class,dosage_text,phi_days,reentry_hours,source,last_verified
```

| Column | Notes |
|---|---|
| `active_ingredient` | Lowercase, the ingredient not the brand. `carbendazim`, not `Bavistin` |
| `crop` | `paddy` in v2 |
| `target` | One of the five `target_label` values, `docs/API_CONTRACT.md` §1 |
| `pesticide_class` | Drives the `WRONG_CLASS` verdict — a fungicide against an insect pest, or the reverse |
| `dosage_text` | As printed on the label. The system never computes a dose |
| `phi_days` | Pre-harvest interval. Compared against `days_to_harvest` for `PHI_CONFLICT` |
| `reentry_hours` | Required on any chemical rung of an advisory ladder |
| `source` | The document the row came from, so a verdict is traceable |
| `last_verified` | Date the row was checked against that source |

**Why an empty table is safe and a wrong one is not.** With no rows, every check
returns `NOT_IN_RECORDS` — "I do not have a record of this product. Ask an expert
before using it." That is a valid, honest verdict and `docs/PRD.md` §9 lists it as
the accepted degradation. A row with a wrong `pesticide_class` or a wrong
`phi_days`, by contrast, produces a confident verdict about a chemical going onto
a field. Leave a row out rather than guess it.

`docs/DESIGN.md` §14 flags this table as a hard blocker with no owner in the work
split. It blocks all of F8.
