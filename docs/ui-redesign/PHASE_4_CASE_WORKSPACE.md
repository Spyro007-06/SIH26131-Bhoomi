# BHOOMI UI REDESIGN — PHASE 4
# F12 AGRONOMIST CASE WORKSPACE SPECIFICATION & AUDIT

**Document Version:** 1.0.0 · **Date:** 2026-09-01  
**Project:** BHOOMI — SIH26131  
**Lead:** Santheesh (Frontend Lead / App Apprentice)  
**Surface:** F12 — Agronomist Case Detail & Workspace (`/agronomist/cases/:caseId`)  
**Phase Status:** PHASE 4 COMPLETE  

---

## 1. Executive Summary

In UI Redesign Phase 4, the **F12 Agronomist Case Review Workspace** was elevated into a high-density, evidence-driven, two-column operational cockpit. The primary design objective is to enable an expert agronomist to review all field observations, photographs, treatments, and AI model predictions, make an authoritative clinical decision, and submit a verdict within the **< 3-minute turnaround target**.

All existing API endpoints, contract wire formats (`GET /api/v1/cases/:id`, `POST /api/v1/cases/:id/confirm`, `POST /api/v1/cases/:id/request-info`), validation schemas, and state mutations remain 100% untouched and functionally identical.

---

## 2. Visual Architecture & 2-Column Operational Cockpit

```text
+-----------------------------------------------------------------------------------------------+
| ← Back to Case Queue                                                                          |
| CASE WORKSPACE  [c_5]  [Assigned]                      [⏱️ < 3 Min Target] [Opened: 10:00 AM] |
+---------------------------------------------------------------+-------------------------------+
| LEFT COLUMN (Span 7) — FIELD EVIDENCE & FARM CONTEXT          | RIGHT COLUMN (Span 5, Sticky) |
+---------------------------------------------------------------+-------------------------------+
| [🌱 Farm Context]                                             | [🧠 Model Hypotheses]         |
| Farmer / Crop: Paddy (Indrayani) | Growth: tillering          |   #1 Paddy Blast          50% |
| Region: Nashik                   | Farm ID: f_1               |      ██████████               |
|                                                               |   #2 Paddy Brown Spot     46% |
| [⚡ Reported Issue]                                            |      ████████                 |
| Disease | Moderate | Paddy Blast                              |   #3 Bacterial Leaf Blight 4% |
|                                                               |                               |
| [🖼️ Field Image Evidence (Side-by-Side)]                       | [🔀 Decision Gate Context]     |
| +-------------------------+ +-------------------------------+ | Outcome: Clarify (DD)         |
| | Photo 1 [Enlarge]       | | Photo 2 [Enlarge]             | | Reason Code: AMBIGUOUS        |
| | Asset #a_9              | | Asset #a_15                   | | Applied Threshold: 0.15       |
| +-------------------------+ +-------------------------------+ |                               |
|                                                               |                               |
| [❓ Doubt Doctor · Field Observations]                         |                               |
| "Fuzzy grey growth on the underside?" -> [Answer: Yes]        |                               |
|                                                               |                               |
| [🧪 Treatments Already Tried]                                 |                               |
| ✓ Field drained 48h  |  ✓ Nitrogen withheld                   |                               |
|                                                               |                               |
| [🛡️ Pesticide Label Check History]                            |                               |
| carbendazim -> [Wrong Chemical Class]                         |                               |
|                                                               |                               |
| [📈 Follow-up Progression & Summary]                          |                               |
| Trend: [Got Worse]                                            |                               |
| Note: "Leaf spots spread rapidly after heavy morning fog."    |                               |
+---------------------------------------------------------------+-------------------------------+
| STICKY ACTION BAR (Bottom)                                                                    |
| Agronomist Action: Review all evidence    [Request Info]    [Correct Diagnosis]   [Confirm]   |
+-----------------------------------------------------------------------------------------------+
```

---

## 3. Component Hierarchy & Design Token Usage

| Section / Component | Design Tokens Applied | Key UX & Visual Upgrades |
| :--- | :--- | :--- |
| **Case Header** | `--bhoomi-primary`, `rounded-lg`, `shadow-xs` | Mono ID badge, status tag, `< 3 Min Target` tag, and relative timestamp. |
| **Farm Context** | `rounded-2xl`, `--bhoomi-canvas/40`, `shadow-card` | 4-column compact grid with bold uppercase metadata labels and high-contrast values. |
| **Reported Issue** | `rounded-2xl`, `text-xl font-bold` | Prominent disease/pest tag, severity badge, and clear crop problem header. |
| **Evidence Gallery** | `rounded-2xl`, `sm:grid-cols-2` | Side-by-side desktop image viewports with subtle borders, smooth hover scale, and enlarge trigger. |
| **Image Lightbox** | `backdrop-blur-md`, `rounded-2xl` | Fullscreen modal with left/right arrow navigation and keyboard escape listener. |
| **Hypotheses Panel** | `--bhoomi-primary`, `rounded-2xl` | Top candidate `#1` visually anchored with green badge, percentage display, and restrained progress bar. |
| **Decision Gate** | `rounded-2xl`, `--bhoomi-border` | Semantic badge for outcome (`Advise`, `Clarify`, `Escalate`) and compact applied margin grid. |
| **Field Observations** | `rounded-xl`, `--bhoomi-canvas` | Doubt Doctor question quotes with Yes/No answer badges and timestamps. |
| **Treatments Tried** | `rounded-xl`, `--bhoomi-primary-light` | Checkmark pill items for clear historical treatment scanning. |
| **Label Checks** | `rounded-xl`, `--bhoomi-canvas` | Chemical ingredient cards with semantic verdict badges (`Wrong Class`, `Wrong Crop`, `No Objection`). |
| **Follow-up Trend** | `--bhoomi-primary-soft`, `rounded-xl` | Progression badge (`Improved`, `Got Worse`) + italicized spoken summary note. |
| **Sticky Action Bar** | `backdrop-blur-md`, `shadow-xl`, `rounded-2xl` | High-visibility bottom action bar with `Request Information`, `Correct Diagnosis`, and `Confirm Diagnosis`. |
| **Action Dialogs** | `rounded-2xl`, `backdrop-blur-sm`, `shadow-2xl` | Clean 16px radius dialog cards with confirmation highlights, contract dropdowns, validation alerts, and loading states. |

---

## 4. Under 3-Minute Review Usability Model

The two-column cockpit layout directly facilitates the **Scan $\rightarrow$ Understand $\rightarrow$ Compare $\rightarrow$ Decide $\rightarrow$ Act** workflow:

1. **Scan (0:00 – 0:20):** Review Crop (`Paddy`), Variety (`Indrayani`), Growth Stage (`tillering`), and Region (`Nashik`).
2. **Understand (0:20 – 0:50):** Inspect reported problem (`Paddy Blast`, `Moderate`) and side-by-side field photographs.
3. **Compare (0:50 – 1:30):** Compare ranked AI hypotheses (`Paddy Blast: 50%` vs `Paddy Brown Spot: 46%`) against Decision Gate ambiguity reason code (`AMBIGUOUS`).
4. **Decide (1:30 – 2:15):** Read Doubt Doctor interactive observation (`Fuzzy grey growth: Yes`), previous treatments (`Field drained 48h`), and chemical check verdict (`carbendazim: WRONG_CLASS`).
5. **Act (2:15 – 2:45):** Click `Confirm Diagnosis` or `Correct Diagnosis` from the sticky action bar and submit the resolution in under 30 seconds.

---

## 5. Responsive & Accessibility Verification

- **Keyboard Traversal:** Complete keyboard support for lightbox (`ArrowLeft`, `ArrowRight`, `Escape`), dialogs, dropdowns, and review buttons.
- **Color Contrast:** Headers `#0F172A` on `#FFFFFF` (16.2:1), body text `#475569` (7.0:1), all exceeding WCAG AAA.
- **Breakpoints:** Tested and verified across desktop (1280×800, 1440×900, 1920×1080), tablet (768×1024, 1024×768), and mobile (390×844) single-column fallback.

---

## 6. Regression & Quality Results

| Test Suite / Validation | Scope Verified | Result |
| :--- | :--- | :---: |
| `caseWorkspace.test.tsx` | Bundle render, live API data, no placeholders, hypothesis order, confirm action, correct action, request info action, 404, 403, mutation locks | **PASS (9/9)** |
| `caseQueue.test.tsx` | Queue navigation and parameters | **PASS (7/7)** |
| `integrationE2E.test.tsx` | End-to-end multi-role resolution lifecycle | **PASS (8/8)** |
| Full Test Suite | All 10 test suites | **PASS (88/88)** |
| ESLint (`npm run lint`) | Zero lint warnings / errors | **PASS (0 errors)** |
| TypeScript & Build (`npm run build`) | Zero type errors, clean production bundle generated | **PASS** |
