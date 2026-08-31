# Bhoomi v3 — API Contract

**PS:** SIH26131 · Early detection and management of crop diseases and pest infestations
**Status:** v3.0 · frozen
**Companions:** `Bhoomi_v2_PRD.md`, `Bhoomi_v2_Design_Doc.md`

Wire format only — request and response shapes, enums, error codes. Internal logic lives in the design doc.

---

## Changelog — v2 to v3

| Change | Why |
|---|---|
| Four crops (paddy, cotton, soybean, jowar), 26 targets | Scope decision. v2 was paddy and five targets. |
| Targets namespaced by crop (`cotton_bacterial_blight`) | Bacterial blight exists in cotton AND soybean, anthracnose in soybean AND jowar. Unprefixed, a wrong-crop match is something the system must filter out; prefixed it is not expressible. |
| `target_tier`: diagnosable \| inspection | 12 of the 26 cannot be settled by a photograph — a stem borer larva is inside the stem. Routing those through the gate would produce a confident answer about something the image never contained. |
| Growth stages became a per-crop table | The v2 enum was paddy-specific, so the phenology branch could not express "pink bollworm at boll formation". |
| Data-model addendum folded in and deleted | Six parts deep, and the base documents still said paddy. Over a month that gap becomes the thing nobody can resolve. |

The gate constants, the gate algorithm and the frozen contract shapes in
`app/contracts/` are **unchanged**. Scope grew; the principles did not move.

---

## 0. Conventions

- **Base URL:** `/api/v1`
- **Format:** JSON. Photos and audio go through presigned upload; the API never receives raw bytes.
- **IDs:** UUID strings.
- **Timestamps:** ISO 8601 UTC.
- **Auth:** `Authorization: Bearer <jwt>`. Role claim: `farmer | agronomist | official`.
- **Pagination:** `?limit=20&cursor=<opaque>` → response carries `next_cursor`, null when exhausted.
- **Localization:** requests carry `lang` (BCP-47: `mr-IN`, `hi-IN`, `ta-IN`, `en-IN`) where text is returned; responses echo it.
- **Spoken summary:** every consequential response carries `spoken_summary`, a short string the client can read aloud locally.

### Error envelope

```json
{
  "error": {
    "code": "NO_RELEVANT_SOURCE",
    "message": "No trusted source covers this. Sending to an expert.",
    "details": { "best_relevance": 0.31, "threshold": 0.60 }
  }
}
```

**One code, one status.** A client switches on `code` and can predict the
status from it. `VALIDATION_FAILED` is always 422; it is never 400.
`FIXTURES_DISABLED` (409) is a server *configuration* state — with
`VISION_MODEL=real` nobody may pull a vision fixture and with `stub` everybody
may — so it is not `FORBIDDEN`, which would claim the caller's identity was the
problem.

Stable codes: `UNAUTHENTICATED` · `FORBIDDEN` · `NOT_FOUND` · `VALIDATION_FAILED` · `BELOW_CONFIDENCE_GATE` · `AMBIGUOUS_REQUIRES_CLARIFICATION` · `OUT_OF_SCOPE_TARGET` · `NO_RELEVANT_SOURCE` · `OCR_UNREADABLE` · `PRODUCT_NOT_IN_RECORDS` · `AGRONOMIST_UNAVAILABLE` · `FIXTURES_DISABLED`

---

## 1. Enums

```
role                : farmer | agronomist | official
crop                : paddy | cotton | soybean | jowar
problem_type        : disease | pest
target_tier         : diagnosable | inspection
target_label        : 26 values, NAMESPACED BY CROP.

  paddy     paddy_blast, paddy_brown_spot, paddy_bacterial_leaf_blight,
            paddy_yellow_stem_borer, paddy_brown_planthopper
  cotton    cotton_american_bollworm, cotton_pink_bollworm, cotton_whitefly,
            cotton_thrips, cotton_bacterial_blight, cotton_leaf_curl_virus,
            cotton_fusarium_wilt
  soybean   soybean_stem_fly, soybean_girdle_beetle,
            soybean_defoliating_caterpillars, soybean_yellow_mosaic_virus,
            soybean_anthracnose, soybean_alternaria_leaf_spot,
            soybean_bacterial_blight
  jowar     jowar_shoot_fly, jowar_stem_borer, jowar_shoot_bug,
            jowar_anthracnose, jowar_grain_mold, jowar_smut,
            jowar_downy_mildew

growth_stage        : NOT an enum. Rows in `growth_stage`, keyed
                      (crop, stage_key). Farm.growth_stage holds a stage_key
                      and is constrained by a composite FK on
                      (crop, growth_stage), so a farm cannot hold a stage
                      belonging to another crop.
problem_severity    : early | moderate | severe
problem_status      : open | resolved
gate_outcome        : advise | clarify | escalate
gate_reason_code    : ABOVE_GATE | AMBIGUOUS | BELOW_FLOOR
                    | OUT_OF_SCOPE | NO_RELEVANT_SOURCE
cue_answer          : yes | no | unknown
ladder_tier         : cultural | biological | chemical
verdict_code        : NO_OBJECTION_FOUND | NOT_REGISTERED_FOR_TARGET
                    | WRONG_CROP | WRONG_CLASS | PHI_CONFLICT
                    | NOT_IN_RECORDS
alert_trigger       : weather | seasonal | spread | combined
alert_outcome       : nothing_found | found | snoozed
followup_response   : improved | no_change | got_worse
case_status         : open | assigned | resolved
confirmation_verdict: confirmed | corrected
asset_kind          : image | audio
```

---

## 2. Auth

```
POST /auth/otp/request     { phone }                    → { request_id, expires_in }
POST /auth/otp/verify      { request_id, otp }          → { access_token, refresh_token, user }
POST /auth/login           { email, password }          → same shape, role agronomist|official
```

---

## 3. Media

**`POST /assets/presign`**
```json
// req
{ "kind": "image", "content_type": "image/jpeg", "farm_id": "f_1" }
// res 200
{ "asset_id": "a_9", "upload_url": "https://storage...", "method": "PUT", "expires_in": 600 }
```
Client PUTs bytes to `upload_url`, then references `asset_id` downstream.

---

## 4. Voice

**`POST /voice/transcribe`**
```json
// req
{ "asset_id": "a_2", "lang": "mr-IN", "context": "onboarding | doubt_doctor | query" }
// res 200
{
  "text": "माझं भात तिळरी अवस्थेत आहे",
  "confidence": 0.89,
  "lang": "mr-IN",
  "parsed_intent": { "field": "growth_stage", "value": "tillering" },
  "needs_confirmation": true
}
```
Below the ASR confidence floor, `parsed_intent` is omitted and the client re-prompts. `needs_confirmation` is true for anything consequential.

**`POST /voice/synthesize`**
```json
// req  { "text": "...", "lang": "mr-IN" }
// res  { "audio_url": "https://storage/...", "expires_in": 600 }
```

---

## 5. Farm

**`POST /farms`**
```json
// req
{
  "crop": "paddy",
  "variety": "Indrayani",
  "growth_stage": "tillering",
  "region": "Nashik",
  "location": { "lat": 19.9975, "lng": 73.7898 }
}
// res 201
{ "id": "f_1", "crop": "paddy", "growth_stage": "tillering", "region": "Nashik" }
```
`location` is **required**. Spread alerts and the hotspot map are inoperable without it.

```
GET   /farms/{id}            → full profile
PATCH /farms/{id}            → update onboarding fields
GET   /farms/{id}/summary    → home screen in one call
```

**`GET /farms/{id}/summary`**
```json
{
  "farm": { "id": "f_1", "crop": "paddy", "growth_stage": "tillering", "region": "Nashik" },
  "health": { "sentence": "One open problem, being monitored.", "trend": "worsening" },
  "open_problems": 1,
  "pending_followups": 1,
  "active_alerts": 1,
  "spoken_summary": "एक समस्या सुरू आहे..."
}
```
`health` is a sentence and a trend arrow. There is no numeric score field, deliberately.

---

## 6. Diagnosis — the gated path

**`POST /farms/{id}/diagnose`**
```json
// req
{
  "image_asset_id": "a_9",
  "description_asset_id": "a_10",
  "description_text": "पानांवर ठिपके",
  "lang": "mr-IN"
}
```

Every response carries a `gate` object. Its `outcome` determines which other fields are present. Exactly one of `advisory`, `clarification`, `escalation` appears — never two, never none.

**`outcome: "advise"`**
```json
{
  "gate": {
    "outcome": "advise",
    "confidence": 0.87,
    "threshold_applied": 0.70,
    "reason_code": "ABOVE_GATE",
    "alternatives": [
      { "label": "paddy_blast", "confidence": 0.87 },
      { "label": "paddy_brown_spot", "confidence": 0.09 },
      { "label": "paddy_bacterial_leaf_blight", "confidence": 0.04 }
    ],
    "is_stub": false
  },
  "problem_id": "p_7",
  "problem_type": "disease",
  "diagnosis": { "label": "paddy_blast", "severity": "early", "confidence": 0.87 },
  "advisory": { "...see §8..." },
  "citations": [ { "doc_id": "kb_211", "title": "ICAR PoP: Rice — Blast", "reviewed_on": "2025-11-02" } ],
  "spoken_summary": "..."
}
```

**`outcome: "clarify"` — the Doubt Doctor**
```json
{
  "gate": {
    "outcome": "clarify",
    "confidence": 0.50,
    "threshold_applied": 0.15,
    "reason_code": "AMBIGUOUS",
    "alternatives": [
      { "label": "paddy_blast", "confidence": 0.50 },
      { "label": "paddy_brown_spot", "confidence": 0.46 },
      { "label": "paddy_bacterial_leaf_blight", "confidence": 0.04 }
    ],
    "is_stub": false
  },
  "problem_id": "p_7",
  "clarification": {
    "cue_id": "cue_4",
    "question": "Flip the leaf over. Do you see fuzzy grey growth?",
    "question_localized": "पान उलटून पहा. करडी बुरशी दिसते का?",
    "candidates": [
      { "label": "paddy_blast", "signature": "Diamond-shaped spots with grey centres", "image_url": "..." },
      { "label": "paddy_brown_spot", "signature": "Round spots with a yellow halo", "image_url": "..." }
    ],
    "answers": ["yes", "no", "unknown"]
  },
  "spoken_summary": "मला खात्री नाही. दोन शक्यता दिसतात..."
}
```
No `advisory` field. The client must not render treatment text on this branch.

**`outcome: "escalate"`**
```json
{
  "gate": {
    "outcome": "escalate",
    "confidence": 0.31,
    "threshold_applied": 0.45,
    "reason_code": "BELOW_FLOOR",
    "alternatives": [ "...top-3 still returned..." ],
    "is_stub": false
  },
  "problem_id": "p_7",
  "escalation": {
    "case_id": "c_5",
    "assigned_to": "agronomist:kvk_nashik",
    "queue_position": 3,
    "eta_minutes": 45
  },
  "spoken_summary": "मला खात्री नाही. तज्ञाकडे पाठवलं आहे."
}
```

`alternatives` is populated on every branch, including `advise`. The farmer always sees what else was considered.

---

## 7. Doubt Doctor answer

**`POST /problems/{id}/clarify`**
```json
// req
{ "cue_id": "cue_4", "answer": "yes" }
```

**Resolved:**
```json
{
  "resolved": true,
  "diagnosis": { "label": "paddy_blast", "severity": "early", "resolved_by": "field_observation" },
  "observation_id": "o_2",
  "advisory": { "...§8..." },
  "citations": [ ... ],
  "spoken_summary": "मग हा करपा आहे. आता काय करायचं ते सांगतो."
}
```

**Not resolved** — answer was `unknown`, or does not discriminate:
```json
{
  "resolved": false,
  "reason": "answer_did_not_discriminate",
  "observation_id": "o_2",
  "escalation": { "case_id": "c_5", "assigned_to": "...", "queue_position": 2, "eta_minutes": 30 },
  "spoken_summary": "ठीक आहे. तज्ञाकडे पाठवतो."
}
```

The observation is stored either way and travels into the case bundle. There is no tiebreak branch: an inconclusive answer escalates, it never selects the higher-confidence label.

---

## 8. Advisory object

Returned inside diagnose and clarify responses, and by `POST /advisory/query`.

```json
{
  "possible_issue": "Early blast (confidence: high).",
  "what_to_check": "Diamond-shaped lesions with grey centres on upper leaves.",
  "what_to_avoid": "Do not top-dress nitrogen now. It accelerates spread.",
  "ladder": [
    { "tier": "cultural", "action": "Drain the field and let it dry for 48 hours." },
    { "tier": "biological", "action": "Apply Pseudomonas fluorescens as a foliar spray." },
    { "tier": "chemical",
      "action": "Tricyclazole 75 WP",
      "dosage": "0.6 g per litre",
      "phi_days": 30,
      "reentry_hours": 24 }
  ],
  "expert_trigger": "If lesions cover more than 25% of leaves within 3 days, escalate."
}
```

Contract rules:
- `ladder` is ordered and **chemical is always last**. Rejected on write otherwise.
- A `chemical` rung must carry `dosage`, `phi_days` and `reentry_hours`. Missing any → the rung is omitted entirely rather than shipped incomplete.
- `what_to_avoid` precedes `ladder` in the object and must be rendered first and loudest by clients.

**`POST /advisory/query`** — standalone question
```json
// req  { "farm_id": "f_1", "query_text": "...", "lang": "mr-IN" }
// res 200 retrieved
{ "retrieved": true, "advisory": { ... }, "citations": [ ... ] }
// res 200 not retrieved — no fabrication
{
  "retrieved": false,
  "reason": "no_relevant_source",
  "escalation_offered": true,
  "spoken_summary": "याबद्दल माझ्याकडे विश्वसनीय माहिती नाही. तज्ञाकडे पाठवू का?"
}
```

---

## 9. Pesticide label check

**`POST /problems/{id}/label-check`**
```json
// req
{ "image_asset_id": "a_20", "days_to_harvest": 18 }
```

**Verdict returned:**
```json
{
  "extracted": {
    "active_ingredient": "carbendazim",
    "concentration": "50% WP",
    "formulation": "wettable powder",
    "ocr_confidence": 0.82
  },
  "verdict": {
    "code": "WRONG_CLASS",
    "message": "This is a fungicide. Your problem is an insect pest.",
    "matched_row_id": "ru_14"
  },
  "spoken_summary": "हे बुरशीनाशक आहे. तुमची समस्या कीड आहे."
}
```

**Unreadable:**
```json
{
  "extracted": { "ocr_confidence": 0.21 },
  "verdict": null,
  "error": { "code": "OCR_UNREADABLE", "message": "Couldn't read the label. Try a clearer photo, or say the product name." },
  "fallback": { "accepts": ["voice", "text"] }
}
```

**Contract rules — these are safety constraints, not style:**
- `verdict.message` is a fixed server-side string. Clients render it verbatim and never compose their own pesticide copy.
- No verdict message contains "safe", "approved", "you can use", or any endorsement phrasing. `NO_OBJECTION_FOUND` reads: *"No objection found. Follow the printed label for dosage."*
- Ingredient absent from `registered_use` returns `NOT_IN_RECORDS` with escalation offered. The server never infers a verdict for an unknown chemical.

---

## 10. Alerts

**`GET /farms/{id}/alerts`**
```json
{
  "alerts": [
    {
      "id": "al_1",
      "trigger_type": "weather",
      "target": "paddy_blast",
      "risk_level": "high",
      "reason": "Humidity above 90% for 4 consecutive nights at tillering stage.",
      "inspection_tasks": [
        "Check the upper leaves on 10 plants across the field.",
        "Photograph any spot with a grey centre."
      ],
      "issued_at": "2026-08-29T04:00:00Z",
      "outcome": null,
      "spoken_summary": "..."
    }
  ],
  "next_cursor": null
}
```
`inspection_tasks` is **never empty**. An alert cannot exist without at least one task.

**`POST /alerts/{id}/respond`**
```json
// req  { "outcome": "found", "image_asset_id": "a_9" }
// res  { "alert_id": "al_1", "outcome": "found", "diagnose_suggested": true }
```
Clients keep the alert card non-dismissible until this is called.

---

## 11. Problems, timeline, follow-up

```
GET  /farms/{id}/timeline                    chronological case file
GET  /farms/{id}/problems?status=open&type=  problem list
GET  /problems/{id}                          detail with photos, observations, advisory
GET  /farms/{id}/followups/pending           due check-ins
```

**`POST /followups/{id}/respond`**
```json
// req
{ "response": "got_worse", "image_asset_id": "a_15" }
// res
{
  "problem_id": "p_7",
  "severity_change": { "from": "early", "to": "moderate" },
  "health": { "sentence": "Problem worsening despite treatment.", "trend": "worsening" },
  "escalated": true,
  "case_id": "c_5"
}
```

---

## 12. Escalation and case bundle

**`POST /problems/{id}/escalate`** *(also fires automatically)*
```json
// res 201
{ "case_id": "c_5", "assigned_to": "agronomist:kvk_nashik", "status": "assigned",
  "queue_position": 3, "eta_minutes": 45 }
```

`queue_position` is correct at the instant it is issued and **is not
authoritative afterwards**. The stored column is stale the moment anything ahead
of it resolves, and nothing recomputes it. `GET /agronomist/case-queue` computes
position from the live ordering and ignores the stored value. Treat the stored
column as a record of where the case entered the queue, not its current place in
it.

**`GET /cases/{id}`** — the bundle the agronomist opens
```json
{
  "case_id": "c_5",
  "status": "assigned",
  "farm": { "id": "f_1", "crop": "paddy", "variety": "Indrayani",
            "growth_stage": "tillering", "region": "Nashik" },
  "problem": { "id": "p_7", "type": "disease", "label": "paddy_blast", "severity": "moderate",
               "opened_at": "2026-08-25T..." },
  "model_hypotheses": [
    { "label": "paddy_blast", "confidence": 0.50 },
    { "label": "paddy_brown_spot", "confidence": 0.46 },
    { "label": "paddy_bacterial_leaf_blight", "confidence": 0.04 }
  ],
  "gate": { "outcome": "clarify", "reason_code": "AMBIGUOUS", "threshold_applied": 0.15 },
  "field_observations": [
    { "question": "Fuzzy grey growth on the underside?", "answer": "yes", "at": "2026-08-25T..." }
  ],
  "images": [ { "asset_id": "a_9", "url": "...", "at": "..." },
              { "asset_id": "a_15", "url": "...", "at": "..." } ],
  "treatments_tried": [ "Field drained 48h", "Nitrogen withheld" ],
  "label_checks": [ { "ingredient": "carbendazim", "verdict": "WRONG_CLASS", "at": "..." } ],
  "followup_trend": "got_worse",
  "spoken_summary": null
}
```

**Contract rule:** every field is populated from live data. No placeholder strings — no "Unregistered Farmer", no empty history array on a case that has history, no null confidence where a diagnosis exists. A bundle failing this on a real case is a failed feature, not a cosmetic issue. This has regressed before and needs a test.

---

## 13. Agronomist

```
GET  /agronomist/case-queue?status=assigned   → cases, oldest first, with queue_position
POST /cases/{id}/confirm
POST /cases/{id}/request-info
```

> **Ownership, v3.** `POST /cases/{id}/confirm` and `GET /agronomist/case-queue`
> moved from Thaariha to Shreekumar. Confirm has no inference in it: it takes a
> verdict, writes a `Confirmation`, and its four downstream effects — problem
> resolution, the prior, the spread fan-out, the F15 aggregates — are all `core/`
> features that touch the database, which `intelligence/` never does
> (`docs/DESIGN.md` §3). `GET /cases/{id}`, the bundle, is the part with
> judgement in it and remains Thaariha's.

**`POST /cases/{id}/confirm`**
```json
// req — confirming the model
{ "verdict": "confirmed", "treatment": "Tricyclazole per label; drain and dry 48h.", "notes": "Recheck in 5 days." }
// req — correcting it
{ "verdict": "corrected", "corrected_label": "paddy_brown_spot",
  "treatment": "...", "notes": "Halo pattern is diagnostic here." }
// res 200
{
  "case_id": "c_5",
  "status": "resolved",
  "problem_status": "resolved",
  "confirmation_id": "cf_2",
  "spread_alerts_issued": 4
}
```
`spread_alerts_issued` is the F6 fan-out count. Only `confirmed` and `corrected` verdicts propagate — unconfirmed model output never triggers neighbour alerts.

---

## 14. Referral

**`GET /farms/{id}/referrals`**
```json
{
  "referrals": [
    { "kind": "kvk", "name": "KVK Nashik", "phone": "+91...", "distance_km": 12.4,
      "accepts_samples": true },
    { "kind": "lab", "name": "District Plant Health Clinic", "phone": "+91...",
      "distance_km": 18.0, "accepts_samples": true },
    { "kind": "helpline", "name": "Kisan Call Centre", "phone": "1800-180-1551" }
  ]
}
```

---

## 15. Officials dashboard

Role `official` only.

```
GET /officials/hotspots?region=&crop=&from=&to=
GET /officials/accuracy?from=&to=
GET /officials/queue
```

**`GET /officials/hotspots`**
```json
{
  "points": [
    { "lat": 19.99, "lng": 73.78, "label": "paddy_blast", "confirmed_count": 7,
      "first_seen": "2026-08-20", "last_seen": "2026-08-29" }
  ],
  "totals_by_label": { "paddy_blast": 7, "paddy_brown_planthopper": 3 }
}
```
Only **confirmed** cases appear. Model output alone never renders on an official's map.

**`GET /officials/accuracy`**
```json
{
  "by_label": [
    { "label": "paddy_blast", "confirmed": 12, "corrected": 3, "accuracy": 0.80 },
    { "label": "paddy_brown_spot", "confirmed": 5, "corrected": 6, "accuracy": 0.45 }
  ],
  "window": { "from": "2026-08-01", "to": "2026-08-29" }
}
```

---

## 16. Endpoint index

| Method | Path | Purpose | Owner |
|---|---|---|---|
| POST | `/auth/otp/request` · `/auth/otp/verify` · `/auth/login` | Auth | Shreekumar |
| POST | `/assets/presign` | Presigned upload | Shreekumar |
| POST | `/voice/transcribe` · `/voice/synthesize` | ASR / TTS | Shruthi |
| POST/GET/PATCH | `/farms` · `/farms/{id}` · `/farms/{id}/summary` | Farm profile | Shreekumar |
| POST | `/farms/{id}/diagnose` | Gated diagnosis | Thaariha + Suchit |
| POST | `/problems/{id}/clarify` | Doubt Doctor answer | Thaariha |
| POST | `/advisory/query` | Standalone RAG | Thaariha |
| POST | `/problems/{id}/label-check` | Pesticide veto | Suchit + Shreekumar + Thaariha |
| GET/POST | `/farms/{id}/alerts` · `/alerts/{id}/respond` | Early warning | Shreekumar |
| GET | `/farms/{id}/timeline` · `/problems` · `/problems/{id}` | Case file | Shreekumar |
| GET/POST | `/farms/{id}/followups/pending` · `/followups/{id}/respond` | Follow-up loop | Shreekumar |
| POST/GET | `/problems/{id}/escalate` · `/cases/{id}` | Escalation + bundle | Thaariha |
| GET | `/agronomist/case-queue` | Case queue | **Shreekumar** (was Thaariha) |
| POST | `/cases/{id}/confirm` | Confirmation write | **Shreekumar** (was Thaariha) |
| GET | `/farms/{id}/referrals` | Referral | Tharun |
| GET | `/officials/hotspots` · `/accuracy` · `/queue` | Dashboard | Santheesh + Shreekumar |

---

## 17. Invariants

Things that must hold on every response. Each is testable and each protects a PRD guarantee.

1. Every diagnose response carries a `gate` object.
2. Exactly one of `advisory`, `clarification`, `escalation` per diagnose response.
3. `gate.alternatives` is populated on all three branches.
4. No `advisory` field appears on a `clarify` or `escalate` outcome.
5. `advisory.ladder` is chemical-last, and a chemical rung carries dosage, PHI and re-entry or is omitted.
6. `alerts[].inspection_tasks` is never empty.
7. Label-check verdict messages are server-supplied fixed strings, free of endorsement vocabulary.
8. Unknown ingredient returns `NOT_IN_RECORDS`, never an inferred verdict.
9. Case bundles contain no placeholder strings on live cases.
10. Only confirmed diagnoses drive spread alerts and hotspot points.
11. `is_stub: true` is surfaced whenever `VISION_MODEL=stub`, and clients must show it.
12. A `TopK` sums to **at most 1.0**, not exactly. It is the top three of a
    softmax over 26 classes; the other 23 hold the remainder. Asserting equality
    would be asserting the model is certain the answer is in the top three.
13. Only `diagnosable` targets reach the gate. An `inspection` target is never
    image-classified — it produces risk alerts with inspection tasks, and an
    advisory only if a human confirms it.
14. `Farm.growth_stage` is a `stage_key` valid for that farm's crop, enforced by
    a composite foreign key. A cotton farm holding `tillering` is not filtered
    out; it is not storable.

---

*End of contract v3.0. Frozen. Changes after that require a team decision, not a pull request.*
