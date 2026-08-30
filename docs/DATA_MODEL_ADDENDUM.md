# Data model addendum

**Status:** proposal, pending a team decision. Not frozen.
**Author:** Shreekumar · Phase 1
**Relates to:** `docs/DESIGN.md` §5 (frozen), `docs/API_CONTRACT.md` (frozen)

`docs/DESIGN.md` §5 is frozen and this document does not change it. It records
tables and columns that `docs/API_CONTRACT.md` requires and that §5 does not
contain. Every entry names the contract clause that forces it, so the team is
deciding on evidence rather than on a preference.

Two categories:

- **Part A — four tables the build cannot proceed without.** Agreed with
  Shreekumar as required before Phase 1's ORM lands.
- **Part B — further gaps found while transcribing §5.** B1, B2 and B3 were
  accepted by Shreekumar and land in migration `0002_initial_schema`. B4 was
  subsequently accepted too and became the `label_reference` table. B5 belongs
  to another owner and is flagged only. B6 is a watch item.
- **Part C — a team decision taken after Phase 1.** `Farm.sowing_date`, in
  migration `0003_farm_sowing_date`.
- **Part D — an ownership reassignment,** not a data-model change. Recorded
  here because it is the document the team reviews.

---

## Part A — required tables absent from §5

### A1 · `User`

```
User(id, role, phone?, email?, password_hash?, name, created_at)
```

**Forced by:** `docs/API_CONTRACT.md` §2. Three auth endpoints exist —
`/auth/otp/request` and `/auth/otp/verify` for farmers by phone, `/auth/login`
for `agronomist` and `official` by email and password. §0 requires
`Authorization: Bearer <jwt>` with a role claim of `farmer | agronomist |
official` on every request.

**Also forced by §5 itself:** `Farm.farmer_id` is declared with no table to point
at. `Case.assigned_to` and `Confirmation.agronomist_id` have the same problem.

**Why one table rather than two:** a single identity table keeps the `role` claim
and the foreign keys single-valued. The cost is that half the columns are null
for any given row, which is why the shape is constrained at the database rather
than by convention:

```sql
CHECK (
  (role = 'farmer' AND phone IS NOT NULL AND password_hash IS NULL)
  OR
  (role IN ('agronomist','official') AND email IS NOT NULL AND password_hash IS NOT NULL)
)
```

A farmer row carrying a password hash is a farmer who can bypass OTP. An
agronomist row without one is an account that cannot authenticate. Both fail
silently, so this is a CHECK rather than a validator.

### A2 · `OtpRequest`

```
OtpRequest(id, phone, code_hash, expires_at, consumed_at, attempts, created_at)
```

**Forced by:** `docs/API_CONTRACT.md` §2 —
`POST /auth/otp/request { phone } → { request_id, expires_in }`. The
`request_id` is returned to the client and presented back at
`/auth/otp/verify`, so it must be a stored row.

`expires_in` in the response forces `expires_at`. `code_hash` rather than
`code`: an OTP table readable in plaintext is a credential store. `attempts` and
`consumed_at` exist so a code can be capped and burned after use — without them
the endpoint is a brute-force oracle.

### A3 · `Asset`

```
Asset(id, kind, content_type, object_key, farm_id, uploaded_at, byte_size?)
```

**Forced by:** `docs/API_CONTRACT.md` §3 —
`POST /assets/presign → { asset_id, upload_url, method, expires_in }`, and §0's
"Photos and audio go through presigned upload; the API never receives raw
bytes."

**Also forced by §5 itself:** `Diagnosis.image_asset_id`,
`LabelCheck.image_asset_id` and `FollowUp.image_asset_id` are all declared as
asset references with no table to reference. `kind` maps to the `asset_kind`
enum (`image | audio`) already in §1 of the contract.

`object_key` is the S3/MinIO key, kept separate from `id` so the storage layout
can change without rewriting foreign keys.

### A4 · `LabelPrior`

```
LabelPrior(region, crop, growth_stage, label, confirmed_count, corrected_count, updated_at)
PRIMARY KEY (region, crop, growth_stage, label)
```

**Forced by:** `docs/DESIGN.md` §11 step 3 describes
`prior[region][crop][stage][label]` as "a count-based nudge" and never gives it a
table. The four dimensions in that expression are the composite primary key.

```sql
CHECK (confirmed_count >= 0 AND corrected_count >= 0)
```

**Note on the cap.** §11 requires the prior's influence to be bounded so it can
never move a prediction across a gate band on its own. That bound is
`PRIOR_MAX_BIAS` in `backend/app/config.py`, asserted at import time to be below
`MARGIN` and below `(GATE - FLOOR)`. This table stores counts only. The clamp
lives in `backend/app/core/services/prior.py` and is not a property of the
schema.

### Explicitly not added: a hotspot counter table

`docs/API_CONTRACT.md` §15 returns `confirmed_count`, `first_seen` and
`last_seen` per hotspot point. These derive from `Confirmation` rows joined to
`Farm` at read time. A maintained counter can drift from its source; a query
cannot. §15's own rule — only confirmed cases appear — is easier to guarantee
when the aggregate *is* the confirmation rows rather than a projection of them.

---

## Part B — further gaps found, awaiting a decision

These were found while transcribing §5 against the contract. Each is a field the
API contract returns or accepts that §5 has nowhere to store.

**B1, B2 and B3 are accepted** and are being built in `0002_initial_schema`. They
remain listed here because §5 is frozen and does not contain them — this document
is the record the team ratifies. B4 and B5 are not mine to decide and are not
built.

### B1 · `Alert.reason` — blocks F5's alert card

`docs/API_CONTRACT.md` §10 returns, per alert:

```json
"reason": "Humidity above 90% for 4 consecutive nights at tillering stage."
```

§5's `Alert` is `(id, farm_id, trigger_type, target, risk_level,
inspection_tasks, issued_at, outcome)`. There is no `reason`.

This is the sentence that tells a farmer *why* they are being asked to walk their
field. Recomputing it on read means storing the weather window that produced it,
which is strictly more state than storing the sentence.

**ACCEPTED** — `reason text NOT NULL`, in `0002_initial_schema`.

### B2 · `RegisteredUse.pesticide_class` — blocks the `WRONG_CLASS` verdict

`docs/DESIGN.md` §9 defines the verdict `WRONG_CLASS`, farmer-facing string
*"This is a fungicide. Your problem is an insect pest."* Deciding it requires
knowing whether the product is a fungicide or an insecticide.

§5's `RegisteredUse` is `(id, active_ingredient, crop, target, dosage_text,
phi_days, reentry_hours, source, last_verified)`. There is no class column, so
one of the six verdicts in §9 is underivable from the table §9 says to look it up
in.

Worth noting: `backend/seed/registered_use.csv` already carries a
`pesticide_class` column, because the seed specification included it. The seed
file and §5 currently disagree.

**ACCEPTED** — `pesticide_class text NOT NULL`, in `0002_initial_schema`.

### B3 · `Confirmation.treatment` — silently discarded today

`docs/API_CONTRACT.md` §13 accepts, on both verdict paths:

```json
{ "verdict": "confirmed", "treatment": "Tricyclazole per label; drain and dry 48h.", "notes": "Recheck in 5 days." }
```

§5's `Confirmation` has `notes` but no `treatment`. They are distinct in the
contract's own example: `treatment` is what the agronomist instructed, `notes` is
commentary. Merging them loses the instruction the farmer is supposed to act on.

**ACCEPTED** — `treatment text`, in `0002_initial_schema`.

### B4 · Label signatures for the Doubt Doctor — no home

`docs/API_CONTRACT.md` §7 returns, per candidate label:

```json
{ "label": "blast", "signature": "Diamond-shaped spots with grey centres", "image_url": "..." }
```

`DistinguishingCue` holds `cue_text` (the observable sign that separates a pair)
and `question_text`. It does not hold a per-label signature or reference image,
and neither does any other table.

This is F4 and belongs to Thaariha, so it is flagged rather than proposed. The
options are a small `LabelProfile(label, signature, image_asset_id)` table, or
static content shipped with the app. **Thaariha's call, not mine.**

### B5 · Referrals — no table at all

`docs/API_CONTRACT.md` §14 returns kvk / lab / helpline entries with `name`,
`phone`, `distance_km` and `accepts_samples`. §5 has no referral table.

`worksplitV1` calls this "static data", which may mean a config file rather than
a table. But `distance_km` is computed against the farm's location, so whatever
holds it needs coordinates. This is F13 and belongs to Tharun. **Flagged, not
proposed.**

### B6 · Severity history — watch item, not a gap yet

`docs/API_CONTRACT.md` §11 returns `severity_change: { from, to }` on a follow-up
response. `Problem.severity` is a single column, so the previous value is
available within the request that changes it and lost afterwards.

That is sufficient for §11 as written. It becomes a gap only if the §11 timeline
has to render past severity transitions. **No action proposed; recorded so it is
not discovered later as a surprise.**

---

## Part C — `Farm.sowing_date`

**Status:** team decision, taken after Phase 1. Built in migration
`0003_farm_sowing_date`.

```
ALTER TABLE farm ADD COLUMN sowing_date DATE NULL;
```

**Forced by:** an incoming phenology branch in the F5 risk engine
(`docs/DESIGN.md` §10). Weather-driven favourability scoring stays as specified
for the fungal targets, but some targets fire on crop age rather than on
humidity and temperature:

- **shoot fly** — within roughly 30 days of emergence
- **pink bollworm** — at boll formation

Neither is a function of the weather window. Both are a function of how old the
crop is, which the frozen §5 model has no way to express: `growth_stage` is a
coarse six-value enum and does not distinguish day 26 from day 34.

**Nullable on purpose.** The three seeded farms predate the column, and a sowing
date is not something to invent — the same reasoning that leaves `health` null
in the farm summary rather than fabricating a sentence. Seed rows have since
been given plausible dates consistent with their `growth_stage`, with the
arithmetic stated in `backend/seed/farms.py`.

### What is deliberately NOT stored

**`days_after_sowing`.** It is derived on read from `sowing_date`.

A stored integer is wrong the next morning, and there is no job in this system
that would refresh it. A column that silently decays into a lie is worse than a
join, and the derivation is a subtraction.

This is the same argument as the hotspot counter in Part A: a maintained
denormalisation can drift from its source; a query cannot.

### Not built here

The phenology branch itself is Phase 3. Part C is only the column it needs.

The two targets named above are also **not in the frozen `target_label` enum**,
which is bounded to five paddy targets (`docs/API_CONTRACT.md` §1), and
`crop` is bounded to `paddy`. Acting on shoot fly or pink bollworm would require
expanding both enums, which is a team decision that has not been made. The
column is forward-compatible with that decision; it does not presuppose it.

---

## Part D — `POST /cases/{id}/confirm` and the case queue move to core

**Status:** decided by Shreekumar, Phase 4. Not a schema change; recorded here
because this is the file the team reads.

`docs/API_CONTRACT.md` §16 assigns all of §12 and §13 to Thaariha. Two of those
endpoints have moved:

| Endpoint | §16 says | Now | Why |
|---|---|---|---|
| `POST /cases/{id}/confirm` | Thaariha | **Shreekumar** | a core write; see below |
| `GET /agronomist/case-queue` | Thaariha | **Shreekumar** | a read over Case rows |
| `GET /cases/{id}` | Thaariha | **Thaariha** | bundle compilation, unchanged |
| `POST /cases/{id}/request-info` | Thaariha | **Thaariha** | unchanged |

### The reasoning

Read §13's request body: a verdict, an optional corrected label, a treatment
string and notes. There is no inference in that path. The endpoint writes a
`Confirmation` row and returns `spread_alerts_issued`.

Its four downstream effects are all `core/` features:

1. resolve the `Problem` — F1, the case file
2. move the `LabelPrior` counters — F14, `services/prior.py`
3. fan out spread alerts — F6, `services/spread.py`, PostGIS
4. feed the officials aggregates — F15, `services/aggregates.py`

All four touch the database, and `docs/DESIGN.md` §3 is explicit that
`intelligence/` never queries it directly. Leaving confirm with Thaariha would
mean either she reaches into four of my tables, or I expose four functions she
calls in sequence and the transaction boundary sits in her module. Neither is
better than the endpoint living where its effects live.

**What stays hers is the part with reasoning in it.** `GET /cases/{id}` compiles
the bundle: it decides what an agronomist needs to see and in what shape, which
is judgement, and `docs/API_CONTRACT.md` §12's no-placeholder rule is a
guarantee about that judgement. It is untouched, still unimplemented, and
returns 404 rather than a plausible empty bundle.

### What this is not

It is not a claim on F12. The feature is split at the seam between "write a row
and apply its consequences" and "decide what to show a human", and the second
half is the larger and more interesting one.

If the team disagrees, moving confirm back is a file move: `services/` keeps the
four effects as callable functions either way.

---

## Summary

| # | Table / column | Status | Forced by |
|---|---|---|---|
| A1 | `User` | required | API_CONTRACT §2, §0; §5's own `farmer_id` |
| A2 | `OtpRequest` | required | API_CONTRACT §2 `request_id` |
| A3 | `Asset` | required | API_CONTRACT §3; §5's own `*_asset_id` |
| A4 | `LabelPrior` | required | DESIGN §11 step 3 |
| B1 | `Alert.reason` | **accepted, in 0002** | API_CONTRACT §10 |
| B2 | `RegisteredUse.pesticide_class` | **accepted, in 0002** | DESIGN §9 `WRONG_CLASS` |
| B3 | `Confirmation.treatment` | **accepted, in 0002** | API_CONTRACT §13 |
| B4 | label signatures | **accepted, `label_reference` in 0002** | API_CONTRACT §7 |
| B5 | referrals | flagged — Tharun | API_CONTRACT §14 |
| B6 | severity history | watch item | API_CONTRACT §11 |
| C  | `Farm.sowing_date` | **accepted, in 0003** | F5 phenology branch, DESIGN §10 |
| D  | confirm + case-queue -> core | **decided, Phase 4** | ownership, not schema |

B4, B5 and B6 are not built and need their owners' decisions.
