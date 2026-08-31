# Bhoomi v2 — Design Document

**PS:** SIH26131 · Early detection and management of crop diseases and pest infestations
**Status:** v2.0 · frozen for the build
**Companions:** `Bhoomi_v2_PRD.md` (what and why), `Bhoomi_v2_API_Contract.md` (wire format)

This document covers structure: stack, modules, data model, the three algorithms that carry the product, and the contracts that freeze at hour 2.

---

## 1. Stack

| Layer | Choice | Why |
|---|---|---|
| Farmer app | Flutter (Android) | One codebase, good camera and audio access on low-end devices |
| Agronomist portal + officials dashboard | React + Vite + Tailwind, Leaflet for maps | Desktop users; separable from the Flutter workstream so two people build in parallel without merge contention |
| Backend | Python + FastAPI, SQLAlchemy 2.0 async, Pydantic v2 | Pydantic models *are* the API contract; best ecosystem for the RAG and vision glue |
| Database | PostgreSQL + PostGIS + pgvector | Relational rows, farm geolocation for hotspot queries, and RAG embeddings in one service |
| Object storage | S3-compatible (MinIO local) | Presigned uploads keep photo bytes off the API |
| Vision | PyTorch, bounded classifier, served in-process | Confidence is native to the model and drives the gate |
| OCR | Lightweight on-device or server-side OCR (Tesseract or PaddleOCR) | Label text only; no layout understanding needed |
| Embeddings | BGE-m3 via pgvector | Multilingual — handles Devanagari alongside English |
| LLM | Hosted API, strict grounding prompt | Composition only, never retrieval and never verdicts |
| ASR/TTS | Sarvam — Saaras (STT), Bulbul (TTS), Mayura (translate-before-embed) | Regional-language PS clause; one Indic vendor across the voice path. Embeddings stay BGE-m3 — the translator changed, the embedder did not |
| Weather | Open-Meteo | Free, no key, returns the fields F5 needs |
| Scheduling | APScheduler | Follow-up check-ins; one dependency |

### Three choices worth defending out loud

**One database, three jobs.** Postgres carries relational data, farm geometry for the hotspot radius query, and RAG vectors. Fewer services to keep alive during a demo, and "which farms are within 2km of this confirmed outbreak" is plain SQL rather than an application-layer loop.

**The gate is code, not a prompt.** The vision model returns probabilities; the retriever returns relevance. A deterministic function compares both against constants and emits one outcome. The "never fabricate" guarantee is enforceable in a function you can point at, not hoped for in prompt wording.

**The LLM composes, it does not decide.** It never chooses whether to answer, never retrieves, and never produces a pesticide verdict. Every consequential decision happens in Python before the LLM is called, and the LLM receives retrieved text plus a schema to fill.

---

## 2. Architecture

```
┌──────────────────────┐   ┌──────────────────────────────┐
│ Farmer app (Flutter) │   │ Portal + dashboard (React)   │
└──────────┬───────────┘   └──────────────┬───────────────┘
           │ photo / voice / yes-no       │ confirm / correct
           ▼                              ▼
┌───────────────────────────────────────────────────────────┐
│                    FastAPI · orchestration                 │
│                                                            │
│   ┌────────────────────────────────────────────────────┐   │
│   │  CONFIDENCE GATE  (the choke point — F2)           │   │
│   │  above → compose · ambiguous → cue · below → esc.  │   │
│   └───┬──────────────┬───────────────┬─────────────────┘   │
│       │              │               │                     │
│   ┌───▼────┐   ┌─────▼──────┐   ┌────▼────────┐            │
│   │ RAG    │   │ Doubt      │   │ Escalation  │            │
│   │ advisory│  │ Doctor     │   │ compiler    │            │
│   └───┬────┘   └─────┬──────┘   └────┬────────┘            │
└───────┼──────────────┼───────────────┼─────────────────────┘
        │              │               │
   ┌────▼────┐   ┌─────▼─────┐   ┌─────▼──────┐   ┌──────────┐
   │ Vision  │   │  Corpus   │   │ Case store │   │ Risk     │
   │ service │   │ (pgvector │   │            │   │ engine   │
   │ + OCR   │   │  + cues)  │   │            │   │ (weather)│
   └─────────┘   └───────────┘   └────────────┘   └──────────┘
                       │
                 ┌─────▼──────────┐
                 │ registered_use │  ← F8 label check lookup
                 └────────────────┘
```

Everything consequential passes through the gate. That is the point of the shape.

---

## 3. Module boundaries and ownership

| Module | Owner | Exposes |
|---|---|---|
| `vision/` — classifier, OCR extraction | Suchit | `classify(image) → TopK`, `extract_label(image) → LabelExtract` |
| `core/` — schema, CRUD, risk engine, alerts, spread, follow-up, confirmation | Shreekumar | ORM models, `issue_alerts()`, `propagate(confirmation)` |
| `intelligence/` — gate, Doubt Doctor, RAG, verdict, bundle | Thaariha | `decide(topk, retrieval) → GateDecision`, `compose(...) → Advisory`, `verdict(...) → LabelVerdict`, `compile_bundle(...) → CaseBundle` |
| `voice/` — ASR, TTS, translate-before-embed | Shruthi | `transcribe()`, `synthesize()`, `to_embedding_text()` |
| `app/` — Flutter | Tharun (Santheesh support) | — |
| `portal/` — agronomist screens + officials dashboard | Santheesh | — |

Modules talk through typed functions, not by reaching into each other's tables. `intelligence/` never queries the DB directly; `core/` hands it what it needs.

---

## 4. The three frozen contracts

These lock at hour 2. Four people build against them, so reopening one costs more than living with an imperfect shape.

**C1 · Vision → Intelligence**

```python
class Prediction(BaseModel):
    label: str          # pest species or disease, from the bounded set
    confidence: float   # 0.0–1.0

class TopK(BaseModel):
    predictions: list[Prediction]   # exactly 3, descending by confidence
    out_of_scope: bool              # True if crop/target outside the set
    model_version: str
    is_stub: bool                   # True → UI must show a stub banner
```

**C2 · Core → everyone: farm shape**

Farm carries `id, crop, variety, growth_stage, region, location (Point, SRID 4326), created_at`. Geolocation is required at creation. F6 and F15 are inoperable without it, and retrofitting geometry after seed data exists is painful.

**C3 · Intelligence → clients: gate object and verdict strings**

```python
class GateDecision(BaseModel):
    outcome: Literal["advise", "clarify", "escalate"]
    confidence: float
    threshold_applied: float
    reason_code: str                # BELOW_FLOOR | AMBIGUOUS | OUT_OF_SCOPE | NO_RELEVANT_SOURCE | ABOVE_GATE
    alternatives: list[Prediction]  # always populated, even on advise
```

Verdict strings for F8 are fixed constants owned by `intelligence/` and rendered verbatim by the app. The app never composes pesticide-safety copy.

---

## 5. Data model

```
Farm(id, farmer_id, crop, variety, growth_stage, region,
     location: geography(Point,4326), created_at)

Problem(id, farm_id, problem_type: disease|pest, label, severity,
        status: open|resolved, opened_at, resolved_at)

Diagnosis(id, problem_id, image_asset_id, topk: jsonb, gate_outcome,
          gate_confidence, reason_code, model_version, is_stub, created_at)

Observation(id, problem_id, kind: doubt_doctor|field_note,
            question, answer: yes|no|unknown, cue_id, created_at)
    -- the Doubt Doctor answer lives here and travels into the bundle

Advisory(id, problem_id, possible_issue, what_to_check, what_to_avoid,
         ladder: jsonb, expert_trigger, citations: jsonb, created_at)
    -- ladder = [{tier: cultural|biological|chemical, action, dosage?,
    --            phi_days?, reentry_hours?}]  ordered, chemical last

LabelCheck(id, problem_id, image_asset_id, extracted: jsonb,
           ocr_confidence, verdict_code, matched_row_id?, created_at)

RegisteredUse(id, active_ingredient, crop, target, dosage_text,
              phi_days, reentry_hours, source, last_verified)
    -- F8's lookup table. CIB&RC + state PoP. Unowned; see work split.

FollowUp(id, problem_id, due_at, response: improved|no_change|got_worse,
         image_asset_id?, responded_at)

Alert(id, farm_id, trigger_type: weather|seasonal|spread|combined,
      target, risk_level, inspection_tasks: jsonb NOT NULL,
      issued_at, outcome: nothing_found|found|snoozed|null)
    -- CHECK (jsonb_array_length(inspection_tasks) > 0)

Case(id, problem_id, assigned_to, status: open|assigned|resolved,
     queue_position, eta_minutes, bundle: jsonb, created_at)

Confirmation(id, case_id, problem_id, agronomist_id,
             verdict: confirmed|corrected, corrected_label?,
             notes, created_at)
    -- F14 reads from here

CorpusDoc(id, title, source, reviewed_on, target, crop,
          content, embedding: vector(1024))

DistinguishingCue(id, cue_text, question_text, discriminates:
                  [label_a, label_b], answer_yes_implies: label,
                  doc_id)
    -- F4 reads from here. Structured, not free text.
```

Two constraints carry real weight and belong in the schema rather than application code:

- `Alert.inspection_tasks` non-empty, enforced by CHECK. An alert without a task is noise, and enforcing it in Python means someone will bypass it at hour 25.
- `Advisory.ladder` chemical-last, enforced on write. The PRD's structural claim about pesticide ordering is only true if the database refuses to store it otherwise.

---

## 6. The gate (F2)

The single most important function in the build.

```python
GATE   = 0.70   # above this, and clear of the runner-up → advise
FLOOR  = 0.45   # below this → never engage the farmer, escalate
MARGIN = 0.15   # minimum gap between top-1 and top-2 to call it clear

def decide(topk: TopK, retrieval_score: float | None) -> GateDecision:
    if topk.out_of_scope:
        return GateDecision(outcome="escalate", reason_code="OUT_OF_SCOPE", ...)

    top1, top2 = topk.predictions[0], topk.predictions[1]

    if top1.confidence < FLOOR:
        return GateDecision(outcome="escalate", reason_code="BELOW_FLOOR", ...)

    if top1.confidence - top2.confidence < MARGIN:
        return GateDecision(outcome="clarify", reason_code="AMBIGUOUS", ...)

    if top1.confidence < GATE:
        return GateDecision(outcome="escalate", reason_code="BELOW_FLOOR", ...)

    if retrieval_score is None or retrieval_score < RAG_THRESHOLD:
        return GateDecision(outcome="escalate", reason_code="NO_RELEVANT_SOURCE", ...)

    return GateDecision(outcome="advise", reason_code="ABOVE_GATE", ...)
```

Properties that must hold and must have tests:

- Exactly one outcome. Never both advice and escalation; never neither.
- `alternatives` populated on every branch, including `advise` — the farmer sees what else it considered.
- No advisory composition happens before this returns `advise`.
- Constants live here and nowhere else. A threshold literal appearing in a second file is a bug.

Ordering note: the ambiguity check runs before the absolute-gate check. A model that is 0.68 on blast and 0.12 on brown spot is clear but slightly under the gate — that escalates. A model that is 0.58 and 0.49 is ambiguous — that goes to the Doubt Doctor even though neither clears the gate. Ambiguity is the more informative signal and is worth a question.

---

## 7. The Doubt Doctor (F4)

```
ambiguous (top1, top2)
        │
        ▼
find cue where discriminates == {top1.label, top2.label}
        │
   ┌────┴────┐
 found    not found ──────────────► escalate
   │
   ▼
render question (via voice, in Marathi/Hindi) + both signatures
   │
   ├── Yes / No that maps to a label ──► resolve, store Observation, advise
   └── "Can't tell", or answer maps to neither ──► escalate
```

Design rules:

- Cues are **retrieved, not generated**. The question text lives in `DistinguishingCue.question_text`, authored alongside the corpus. An LLM composing a differential diagnostic question at runtime is exactly the fabrication risk the whole product exists to avoid.
- The system asks **one** question. Not a decision tree. If one cue does not settle it, a human should look.
- No tiebreak fallback. When the answer does not discriminate, the system escalates rather than picking the higher confidence. This is the rule most likely to be quietly broken under time pressure, so it needs a test.
- The answer is persisted as an `Observation` and appears in the case bundle. The agronomist sees that the farmer checked the leaf underside and reported grey growth — that is genuinely useful clinical information and it is the reason this feature is not decoration.

---

## 8. Advisory pipeline (F7)

```
query (or resolved diagnosis)
  → to_embedding_text()      ← translate-before-embed, Shruthi
  → embed (BGE-m3)
  → pgvector similarity search, filter by crop + target
  → max relevance < threshold?  ──► retrieved:false, escalation offered, STOP
  → LLM composes into the fixed schema, grounded strictly on retrieved chunks
  → validate: ladder ordered, chemical last, citations present
  → persist Advisory
```

The validation step is not optional. If the LLM returns a ladder with a chemical rung first, the response is rejected and recomposed, not shipped. Structural guarantees enforced only by prompt wording are not guarantees.

**The Devanagari trap.** Any normalisation step that strips non-ASCII produces a zero vector for a Marathi query, which produces a degenerate similarity score, which sails past the relevance threshold and yields confident fabricated advice. This has bitten this codebase before. `to_embedding_text()` translates to a common language before embedding, and there is a test asserting a Marathi query and its English equivalent retrieve overlapping documents.

The translator is **Sarvam Mayura**, formal mode, pinned — one engine for both voice-origin and typed-origin queries, so the same Marathi sentence yields the same English yields the same vector, and the overlap test stays reproducible. A voice query is transcribed once (Saaras, native script); that single transcript is both read back for confirmation and fed here — it is **not** re-translated by Saaras's translate mode, because two engines means two English renderings and a flaky test. Order inside `to_embedding_text()`: translate → normalise the **English only** → glossary-pin domain terms to the `target_label` vocabulary (करपा → `blast`) → length-guard against a degenerate empty vector. The model pins live in `config.py` as module constants, not settings, so the environment cannot swap them at demo time.

---

## 9. Label check (F8)

```
photo → OCR → {active_ingredient, concentration, formulation, ocr_confidence}
   │
   ├── ocr_confidence < OCR_FLOOR ──► "couldn't read it" → clearer photo,
   │                                   or speak/type the product name
   ▼
lookup RegisteredUse WHERE active_ingredient = ? AND crop = ?
   │
   ├── no row ──────────────► NOT_IN_RECORDS  (+ escalation offered)
   ├── target mismatch ─────► NOT_REGISTERED_FOR_TARGET
   ├── crop mismatch ───────► WRONG_CROP
   ├── class mismatch ──────► WRONG_CLASS
   ├── phi_days > days_to_harvest ──► PHI_CONFLICT
   └── all clear ───────────► NO_OBJECTION_FOUND
```

The verdict is a **table lookup**. No model is consulted. The LLM is not in this path at all.

Fixed copy, owned by `intelligence/`, rendered verbatim by the app:

| Code | Farmer-facing string |
|---|---|
| `NO_OBJECTION_FOUND` | "No objection found. Follow the printed label for dosage." |
| `NOT_REGISTERED_FOR_TARGET` | "This product is not registered for this pest. Do not use it here." |
| `WRONG_CROP` | "This product is not registered for paddy." |
| `WRONG_CLASS` | "This is a fungicide. Your problem is an insect pest." |
| `PHI_CONFLICT` | "Harvest is too close. This product needs N days before harvest." |
| `NOT_IN_RECORDS` | "I do not have a record of this product. Ask an expert before using it." |

Note what is absent: any string containing "safe", "approved", "you can use". The vocabulary itself makes endorsement impossible. This is a review checklist item, not a style preference.

---

## 10. Risk engine and spread (F5, F6)

**F5.** A scheduled job pulls weather per region, scores each target against a favourability rule (humidity band, temperature band, consecutive-days counter, growth-stage susceptibility, plus a bump if the farm's own history contains this target), and issues alerts above a level. Every alert pulls its inspection tasks from the corpus for that target. Empty task list means no alert — the CHECK constraint enforces it.

**F6.** On a `Confirmation` with verdict `confirmed`, a PostGIS query finds same-crop farms within `SPREAD_RADIUS_M` and issues alerts with `trigger_type = spread`.

```sql
SELECT id FROM farm
WHERE crop = :crop
  AND id != :origin
  AND ST_DWithin(location, :origin_point, :radius);
```

**Only confirmed diagnoses propagate.** An unconfirmed model output must not trigger village-wide alarm — that is how a system loses trust in one afternoon.

---

## 11. Confirmation loop (F14)

On confirmation or correction:

1. Write `Confirmation`.
2. Increment hotspot counters for region × crop × label.
3. Adjust the prior: `prior[region][crop][stage][label]` as a count-based nudge, applied as a small additive bias to the vision output before the gate, capped so it can never move a prediction across a band on its own.
4. Update dashboard aggregates for confirmed-versus-corrected.

The cap in step 3 matters. A prior that can push a prediction over the gate threshold means the system becomes confident because of history rather than evidence — which is a fabrication path wearing a statistics hat.

**Language discipline:** this is "learns from field confirmations." It is not fine-tuning and not reinforcement learning. Nothing here trains a model, and saying otherwise invites a question with no good answer on stage.

---

## 12. Environments and flags

- Secrets by environment variable, never in the client.
- Version pinned in the path: `/api/v1`.
- Flags: `VISION_MODEL = real | stub`, `ASR_PROVIDER = live | stub`, `LLM_ENABLED = true | false`.
- When `VISION_MODEL = stub`, the API sets `is_stub: true` on every TopK and the app **must** render a stub banner. Silent stubs are how a demo dies.

---

## 13. Testing — the minimum that actually protects the guarantees

| Test | Guards |
|---|---|
| Gate returns each of three outcomes on fixed inputs | F2 |
| No advisory object exists on any non-`advise` path | F2, F7 |
| Non-discriminating Doubt Doctor answer escalates, never tiebreaks | F4 |
| Marathi query and English equivalent retrieve overlapping docs | F9 |
| Advisory rejected when ladder is not chemical-last | F7 |
| Alert insert fails with empty `inspection_tasks` | F5 |
| Every label-check verdict string is free of endorsement vocabulary | F8 |
| Case bundle on a live case contains zero placeholder strings | F12 |
| Prior adjustment cannot move a prediction across a gate band | F14 |

The last two exist because both have failed before in this project's history.

**Verification rule, carried forward:** a feature is verified when a live HTTP response is pasted showing the expected output. Import success, build success, and "I ran it" are not verification. Before trusting any curl result, confirm which process is answering on the port and when it started — a stale server from a previous session has previously made working fixes appear broken for hours.

---

## 14. Sequencing

```
Shreekumar: schema (F1) ─────────┬──────────────► everything
Suchit: TopK contract ───────────┴► Thaariha: gate (F2) ─┬─► F4
                                                          ├─► F7
                                                          └─► F12
corpus + distinguishing_cues ─────────────────────────────┴─► F4, F7  [BLOCKING]
registered_use table ─────────────────────────────────────────► F8    [BLOCKING]
```

Checkpoint B at hour 10: `diagnose → gate → advise → follow-up → escalate` runs end to end on seed data. Nothing in tiers 2–4 starts before that is green.

Two blocking inputs have no owner in the current split — the corpus cues and the registered-use table. Both are writing work rather than code, which is exactly why they get assumed away. Assign at hour 0.
