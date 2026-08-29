# Bhoomi v2 — Product Requirements

**PS:** SIH26131 · Government of Maharashtra · Early detection and management of crop diseases and pest infestations
**Status:** v2.0 · frozen for the build
**Companions:** `Bhoomi_v2_Design_Doc.md` (how it's built), `Bhoomi_v2_API_Contract.md` (wire format), `Bhoomi_SIH26131_Feature_Set_v2.pdf` (feature rationale)

**One line:** A voice-first crop-health system that tells a farmer when and where to look, identifies what it finds or admits it cannot, asks one clarifying question instead of guessing, and vetoes the wrong pesticide before it is sprayed.

---

## 1. The problem, in the PS's own terms

Farmers notice disease and pest damage after it has spread. Extension staff cover too much ground, labs are slow, and the inputs that predict risk — weather, crop stage, variety, soil, local pest history — are never combined into anything a farmer can act on at farm level. When diagnosis is wrong, the consequences are not neutral: delayed treatment, over-spraying, residue violations, cost, and yield loss.

Note the shape of that. The named harm is not "no answer." It is **the confident wrong answer**. A system that guesses well most of the time and badly some of the time is worse for this problem than one that answers less often and says so.

That single observation drives the whole product. Every design decision below traces to it.

---

## 2. Principles

These are not aspirations. Each one is enforced somewhere in code and is testable.

**Never fabricate.** No retrieval above threshold means no advice. No corpus entry for a chemical means no verdict on that chemical. The system says what it doesn't know.

**Uncertainty is a feature surface, not an error state.** When the model is torn, the farmer sees both possibilities and gets asked one question. Uncertainty becomes the most trustworthy moment in the interaction rather than a hidden failure.

**Veto, never endorse.** On pesticides the system may say "this is wrong here." It may never say "this is safe." The printed label remains the authority on dosage.

**Chemical last, structurally.** The action ladder is cultural → biological → chemical as schema, not as writing style. The system is incapable of leading with a pesticide because the field ordering forbids it.

**Every alert carries a task.** "Risk is high" without "go look at the base of the stems" is noise. Inspection tasks are non-nullable.

**The farm is a case file.** Persistent history, not a session. Local pest history is a PS-named risk input.

---

## 3. Users

| User | Needs | Gives back |
|---|---|---|
| **Smallholder farmer** (primary) | Spoken guidance in Marathi or Hindi, a clear "go look here" instruction, an honest answer or an honest escalation | Photos, voice, yes/no field observations, follow-up responses |
| **Agronomist** (KVK/expert) | Pre-analysed case bundles so a review takes under three minutes | Confirmation or correction — which becomes labelled data |
| **Agriculture official** | Surveillance: where outbreaks are, how fast, how accurate the system is in the field | Nothing; read-only consumer |

The farmer never sees a keyboard-first flow. The agronomist's time is the system's scarcest resource and the case bundle exists to protect it.

---

## 4. Scope

### In scope
Paddy only. Three diseases (blast, brown spot, bacterial leaf blight) and two pests (yellow stem borer, brown planthopper). Marathi and Hindi voice; Tamil if hours allow.

### Bounded by design
Anything outside that crop/target set escalates. This is not a limitation to hide — it is the confidence gate working, and it is what the demo shows.

### Explicitly out
Pest-trap and sensor inputs (see §11). Subsidy and scheme matching. Land registry and boundary verification. Irrigation planning. Live government API integrations. True offline operation. Any claim of model fine-tuning or reinforcement learning.

---

## 5. Feature requirements

Numbering matches the feature-set PDF and the work split.

### Tier 0 — Spine

**F1 · Farm persistent memory.**
Each farm holds crop, variety, growth stage, region, geolocation, and the full history of problems, photos, diagnoses, treatments, follow-ups and expert confirmations. Geolocation is required at creation — features 6 and 15 are inoperable without it. History is a risk input, not an archive.

**F2 · Confidence gate.**
One function decides the outcome of every diagnosis. Three bands:

| Band | Condition | Outcome |
|---|---|---|
| Above gate | `top1 ≥ GATE` and `top1 − top2 ≥ MARGIN` | Compose advisory |
| Ambiguous | `top1 ≥ FLOOR` and `top1 − top2 < MARGIN` | Doubt Doctor |
| Below floor | `top1 < FLOOR`, or target out of scope, or no relevant source | Escalate |

Starting values: `GATE = 0.70`, `FLOOR = 0.45`, `MARGIN = 0.15`. These are tunable constants in one module, not scattered literals.

The gate returns a **gate object** to the client — confidence, threshold applied, reason code, ranked alternatives — so the UI can show the farmer why the system is unsure. Exactly one outcome per call; never advice and escalation together, never neither.

The gate sits **before** advisory composition. Nothing composes text when a threshold fails.

**Requirement:** no code path produces treatment advice below the gate. This is testable and must have tests for all three bands before anything downstream is wired.

### Tier 1 — Detection

**F3 · Image-based symptom identification.**
Photo in, ranked top-3 labels with confidences out, plus an out-of-scope signal. Bounded to the declared set.

Labels are **pest species, not damage type**. Several pests produce similar damage; an advisory cannot recommend treatment against a damage pattern. The overlap is what F4 resolves.

The model must handle damage-sign photographs (dead heart, whiteheads, leaf rolling, frass, honeydew, sooty mould), not only clean insect shots, because damage is what farmers actually notice and photograph.

**Requirement:** if the real model is not ready, the stub must be visibly labelled as a stub in the UI. A stub that returns confident output on arbitrary input is worse than no feature.

**F4 · The Doubt Doctor.**
On the ambiguous band, the app states its confidence, shows both candidates side by side with their visual signatures, and asks one physical question that discriminates between them — for example, whether there is fuzzy grey growth on the leaf underside.

Requirements:
- The question is selected from structured `distinguishing_cues` in the corpus. It is never composed by a model at runtime.
- The farmer answers Yes, No, or **Can't tell**.
- Yes/No that discriminates cleanly resolves the diagnosis and proceeds to advisory.
- An answer that does not discriminate, or "Can't tell", **escalates**. The system never falls back to picking the higher-confidence label.
- The answer is stored as a field observation on the problem and appears in the case bundle. Without this the interaction is theatre.

### Tier 2 — Forecasting and surveillance

**F5 · Weather, season and soil risk forecasting.**
Combines weather (temperature, humidity, rainfall, leaf-wetness proxy), growth stage, soil condition, region and the farm's own pest history into a forward-looking risk level per target. Output is a proactive alert, not a diagnosis.

Requirements:
- Every alert carries at least one inspection task. Non-nullable at the schema level.
- The task names **where on the plant to look and when** — "part the canopy and photograph the base of the stems this week." This is what replaces trap inputs as an early signal.
- Alerts are non-dismissible in the app until the farmer records an outcome: inspected-nothing, inspected-found, or remind-tomorrow.

**F6 · Nearby-farm spread alerts.**
A confirmed diagnosis at one farm triggers warnings to same-crop farms within a radius, each carrying inspection tasks. Radius is a tunable constant. Only **confirmed** diagnoses propagate — an unconfirmed model output must not trigger village-wide alarm.

### Tier 3 — Management and advice

**F7 · Grounded advisory with IPM ladder.**
Retrieval from a curated, dated, cited corpus. Below the relevance threshold: no advice, escalation offered.

Fixed structure, in this order:
1. Possible issue, with confidence stated plainly
2. What to check
3. **What to avoid** — first thing the farmer sees, visually loudest
4. Action ladder: cultural → biological → chemical
5. Expert trigger

The ladder is structured fields, not prose. The chemical rung carries dosage, pre-harvest interval and re-entry period from the corpus, and is collapsed by default in the UI.

**Requirement:** 100% of advisories carry at least one citation. Zero advisories on no-retrieval.

**F8 · Pesticide label check (lightweight OCR).**
The farmer photographs a pesticide bottle label before spraying. OCR extracts active ingredient, concentration and formulation. The system checks that product against the current diagnosis, crop and growth stage and answers one question: is this the wrong thing to spray here.

Verdicts: not registered for this target · wrong crop · wrong class (fungicide against an insect pest, or the reverse) · pre-harvest interval exceeds days to harvest · **no objection found** · not in our records.

Two rules, both non-negotiable:

- **Veto, never endorsement.** The positive outcome reads "no objection found — follow the printed label." The system never says a product is safe. OCR on a faded bottle in field light will misread digits, and a misread concentration is a real poisoning or residue risk. The dosage decision stays on the printed label.
- **Corpus lookup, never model inference.** Ingredient + crop + target is matched against a registered-use table sourced from CIB&RC and state package-of-practices. Ingredient absent from the table returns "not in our records" and offers escalation. The system never reasons its way to a verdict on a chemical it has no record of.

Low OCR confidence does not guess: it requests a clearer photo or falls back to spoken/typed product name.

**F9 · Voice-first multilingual interaction.**
Speech in, speech out. Marathi first, Hindi second, Tamil if hours allow. Covers onboarding (crop, growth stage, region), the Doubt Doctor question and answer, and advisory read-out. Consequential values are read back for confirmation before being saved.

**Requirement:** the embedding path must not strip non-Latin script. Devanagari removed by a regex produces a zero vector, a degenerate similarity, and silently fabricated advice. Translate before embed, and test that a Marathi query and its English equivalent retrieve overlapping documents.

**F10 · Closed-loop follow-up.**
Scheduled check-in after treatment: improved / no change / got worse, with an optional fresh photo. Drives severity promotion and auto-escalation on deterioration. Supplies outcome data to F14.

**F11 · Farm health (thin).**
One qualitative sentence and a trend arrow, derived from open problem severity, monitoring recency and treatment response. No composite score as a centrepiece, no weighted rubric, no scoring engine. First item on the cut list.

### Tier 4 — Human loop

**F12 · Expert validation.**
Escalation compiles a case bundle and routes it to the next available agronomist with visible queue position and ETA. The agronomist confirms, corrects, or requests more information.

Bundle contents: crop, region, growth stage, all photos, the model's ranked hypotheses with confidences, the Doubt Doctor question and answer, treatments already tried, follow-up trend, current status.

**Requirement:** every field populated from live data. A bundle rendering placeholder text on a real case is a failed feature, not a cosmetic bug.

**Target:** agronomist completes a review in under three minutes, verified by walking it with a stopwatch.

**F13 · Referral and helpline.**
Contact routing to the local KVK, extension office or diagnostic laboratory when a case exceeds what the system and a remote agronomist can settle. Static contact data, one tap to call.

**F14 · Confirmation loop.**
Every agronomist confirmation or correction becomes a labelled record with three effects: regional hotspot counts update; the prior for that label in that region/crop/growth-stage adjusts; confirmed-versus-corrected counts surface on the officials' dashboard.

**Requirement on language:** this is "learns from field confirmations," which is the PS's own phrase. It is **not** fine-tuning and **not** reinforcement learning. No training run exists to demonstrate, and claiming one invites the question that ends the demo. The prior adjustment is a count-based nudge and must remain inspectable.

**F15 · Agriculture-officials dashboard.**
Hotspot map, outbreak counts by region and crop, confirmation queue, and field accuracy (confirmed versus corrected). Read-only. Named directly in the PS.

---

## 6. End-to-end scenario

A paddy farmer near Nashik, vegetative stage.

1. **Alert.** Humidity and temperature have favoured blast for four days. The system issues a risk alert with one task: examine the upper leaves and photograph any spots. The card cannot be dismissed without an outcome.
2. **Photo.** The farmer finds lesions and photographs them. Top-3 comes back blast 0.58, brown spot 0.49, BLB 0.11.
3. **Gate.** `top1 < GATE` but `top1 ≥ FLOOR` and the gap is under MARGIN → ambiguous band → Doubt Doctor.
4. **Doubt Doctor.** In Marathi: "I am not certain — I see two possibilities." Both candidates shown with their signatures. One question: is there fuzzy grey growth on the underside? The farmer taps Yes.
5. **Resolution.** The cue discriminates for blast. Diagnosis resolves; the answer is stored as a field observation.
6. **Advisory.** What to avoid first — do not top-dress nitrogen now. Then the ladder: drain and dry, resistant-variety note, biological option, and a chemical rung collapsed by default carrying PHI and re-entry.
7. **Label check.** The farmer photographs the bottle he already owns. OCR reads the ingredient; the registered-use table says it is a fungicide registered for a different crop. Verdict: wrong crop. The spray does not happen.
8. **Follow-up.** Day 4: got worse, with a new photo. Severity promotes, auto-escalation fires.
9. **Expert.** The agronomist opens the bundle — both photos, ranked hypotheses, the Doubt Doctor answer, the label check outcome — and confirms blast in under three minutes.
10. **Surveillance.** The confirmation lights the hotspot map and warns same-crop farms in the radius with their own inspection tasks.

One run touches every clause of the PS's expected outcome.

---

## 7. What the demo must survive

Three questions a judge will ask. Rehearse the answers.

**"What happens when it's wrong?"** Show the ambiguous band live. Feed it a photo the model is torn on and let the Doubt Doctor run. Then feed it something out of scope and show it escalate rather than answer.

**"How does this reduce pesticide use?"** Point at the advisory schema — the ladder is ordered fields, so a chemical cannot be first. Then run the label check and let it veto a real bottle.

**"Does it actually learn?"** Confirm a case in the portal and watch the dashboard counts and the hotspot map move. Say "learns from field confirmations." Do not say fine-tuning.

---

## 8. Success criteria

**Trust and safety**
- 100% of advisories carry a valid citation
- Zero advisories produced on no-retrieval or below-gate — hard requirement, not a target
- Zero endorsement-phrased outputs from the label check
- Zero alerts issued with an empty inspection-task list

**Farmer outcomes**
- Share of diagnoses resolved by the Doubt Doctor rather than escalated
- Follow-up completion rate
- Time from alert issued to farmer inspection recorded

**Human loop**
- Agronomist review time, target under three minutes
- Confirmed-versus-corrected ratio, visible on the dashboard

---

## 9. Risks

| Risk | Mitigation | Residual |
|---|---|---|
| Vision model weak or late | Gate absorbs it — low confidence routes to Doubt Doctor or escalation rather than a wrong answer. Stub must be visibly a stub. | Demo shows fewer confident diagnoses |
| Corpus thin | Demo the paddy slice; everything else takes the honest no-retrieval path, which is itself a feature | Coverage breadth |
| Registered-use table incomplete | "Not in our records" is a valid, honest verdict | F8 vetoes less often than it could |
| Marathi retrieval degrades silently | Translate-before-embed; cross-language retrieval test | Translation quality |
| Doubt Doctor cue missing for a pair | Pair falls through to escalation | Fewer resolutions, no wrong answers |
| Agronomist unavailable | Next-available routing, visible queue and ETA, F13 referral as the floor | Human capacity is a real bound |
| Three owners with no commit history | Checkpoint A at hour 2–6, acted on the same hour | — |

---

## 10. Open decisions

- Exact `GATE` / `FLOOR` / `MARGIN` values after seeing real model confidence distributions. Starting values above are placeholders with reasoning, not measurements.
- Radius for F6 spread alerts.
- Whether Tamil ships or is cut with the voice fallback.
- Who authors the corpus `distinguishing_cues` and the registered-use table — unowned in the current split, and F4, F7, F8 are all hard-blocked on them.

---

## 11. Why pest traps are not in this build

The PS names "pest-trap or sensor inputs" in an **or**-list of input modalities. Trap counts would have been a form field, not hardware, so this is not about staying pure software.

It is about coverage. Trap adoption among smallholders is patchy. Making trap count a risk input splits the product into farms that have one and farms that do not — and the farms that do not are the ones this system exists for. If trap data meaningfully improves the forecast, those farms get a worse product. If it does not, it should not be in the build.

The position taken instead: risk inputs are weather, crop stage, soil, region and confirmed outbreaks on neighbouring farms — all obtained without asking any farmer to buy or install anything. F5's inspection tasks do the early-signal job a trap would have done, using a phone every farmer already holds.
