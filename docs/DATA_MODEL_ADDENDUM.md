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
- **Part B — further gaps found while transcribing §5.** Not yet built. These
  need a decision before anyone creates them.

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

These were found while transcribing §5 against the contract. **None has been
created.** Each is a field the API contract returns or accepts that §5 has
nowhere to store.

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

**Recommendation: add `reason text NOT NULL`.**

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

**Recommendation: add `pesticide_class text NOT NULL`.**

### B3 · `Confirmation.treatment` — silently discarded today

`docs/API_CONTRACT.md` §13 accepts, on both verdict paths:

```json
{ "verdict": "confirmed", "treatment": "Tricyclazole per label; drain and dry 48h.", "notes": "Recheck in 5 days." }
```

§5's `Confirmation` has `notes` but no `treatment`. They are distinct in the
contract's own example: `treatment` is what the agronomist instructed, `notes` is
commentary. Merging them loses the instruction the farmer is supposed to act on.

**Recommendation: add `treatment text`.**

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

## Summary

| # | Table / column | Status | Forced by |
|---|---|---|---|
| A1 | `User` | required | API_CONTRACT §2, §0; §5's own `farmer_id` |
| A2 | `OtpRequest` | required | API_CONTRACT §2 `request_id` |
| A3 | `Asset` | required | API_CONTRACT §3; §5's own `*_asset_id` |
| A4 | `LabelPrior` | required | DESIGN §11 step 3 |
| B1 | `Alert.reason` | proposed | API_CONTRACT §10 |
| B2 | `RegisteredUse.pesticide_class` | proposed | DESIGN §9 `WRONG_CLASS` |
| B3 | `Confirmation.treatment` | proposed | API_CONTRACT §13 |
| B4 | label signatures | flagged — Thaariha | API_CONTRACT §7 |
| B5 | referrals | flagged — Tharun | API_CONTRACT §14 |
| B6 | severity history | watch item | API_CONTRACT §11 |

Nothing in Part B has been built.
