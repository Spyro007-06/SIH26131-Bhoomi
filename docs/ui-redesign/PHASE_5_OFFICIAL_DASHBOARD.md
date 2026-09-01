# BHOOMI UI REDESIGN — PHASE 5
# F15 OFFICIAL DASHBOARD SPECIFICATION & AUDIT

**Document Version:** 1.0.0 · **Date:** 2026-09-01  
**Project:** BHOOMI — SIH26131  
**Lead:** Santheesh (Frontend Lead / App Apprentice)  
**Surface:** F15 — Official Surveillance Dashboard (`/official`)  
**Phase Status:** PHASE 5 COMPLETE  

---

## 1. Executive Summary

In UI Redesign Phase 5, the **F15 Official Dashboard** was elevated into a high-density, authoritative agricultural operations intelligence hub. The redesign gives state and district agricultural officers immediate visibility into verified outbreak clusters, confirmed cases across Maharashtra, AI model diagnostic accuracy across crop diseases, and the active confirmation queue.

All existing API endpoints, contract wire formats (`GET /api/v1/official/hotspots`, `GET /api/v1/official/accuracy`, `GET /api/v1/official/queue`), query hooks, and navigation links remain 100% untouched and functionally identical.

---

## 2. Dashboard Layout & Operational Structure

```text
+-----------------------------------------------------------------------------------------------+
| AGRICULTURE OFFICIALS DASHBOARD  [Confirmed Operations]  [🟢 Surveillance Active]  [🔄 Refresh]|
| Operational overview of outbreak intelligence and model performance.                          |
+---------------------------------------------------------------+-------------------------------+
| LEFT SECTION (Span 2) — OUTBREAK HOTSPOTS                     | RIGHT SECTION (Span 1)        |
+---------------------------------------------------------------+-------------------------------+
| [📍 Confirmed Outbreak Hotspots]             [Confirmed Only] | [⚡ Model Diagnostic Accuracy] |
| Live geospatial disease surveillance across Maharashtra       | Agronomist confirmations vs.  |
|                                                               | corrections                   |
| ┌───────────────────────────┬───────────────────────────────┐ | ┌─────────────┬─────────────┐ |
| │ OUTBREAK CLUSTERS         │ CONFIRMED CASES               │ | │ Confirmed   │ Corrected   │ |
| │ 2                         │ 17                            │ | │ 125         │ 25          │ |
| └───────────────────────────┴───────────────────────────────┘ | └─────────────┴─────────────┘ |
|                                                               |                               |
| ACTIVE DISEASE OUTBREAKS:                                     | PERFORMANCE BY CROP DISEASE:  |
| [Wheat Rust: 5]  [Paddy Blast: 12]                            | Paddy Blast: 80% [████████  ] |
|                                                               | Wheat Rust:  90% [█████████ ] |
|                                                               |                               |
| [ ➔ View Hotspots Map ]                                       | [ ➔ View Full Accuracy Report]|
+---------------------------------------------------------------+-------------------------------+
| BOTTOM SECTION (Span 3) — ACTION QUEUE                                                        |
+-----------------------------------------------------------------------------------------------+
| [📋 Action Queue]                                                        [⏱️ 1 Pending Case]  |
| Recent cases pending agronomist confirmation                                                  |
|                                                               |                               |
| • c_101  Wheat Rust · 95% conf                                               [HIGH] 8/18/2026 |
|                                                                                               |
| [ ➔ View Full Action Queue ]                                                                  |
+-----------------------------------------------------------------------------------------------+
```

---

## 3. Component Hierarchy & Design Token Usage

| Section / Component | Design Tokens Applied | Key UX & Visual Upgrades |
| :--- | :--- | :--- |
| **Dashboard Header** | `--bhoomi-primary`, `rounded-full`, `--bhoomi-border` | Live surveillance pulse indicator, official role tag, and rotating refresh action. |
| **Hotspot Preview** | `rounded-2xl`, `--bhoomi-surface`, `shadow-card` | Outbreak cluster KPI counter, confirmed cases metric in red alert card, and target disease chips. |
| **Accuracy Preview** | `rounded-2xl`, `--bhoomi-surface`, `shadow-card` | Confirmed vs. Corrected comparison grid, accuracy percentage meters, and surveillance window badge. |
| **Queue Preview** | `rounded-2xl`, `--bhoomi-surface`, `shadow-card` | High-priority case list with mono Case IDs, severity pills (`High`, `Moderate`), and arrival dates. |
| **Navigation Cards** | `rounded-xl`, `--bhoomi-canvas`, `hover:bg-primary-light` | Dedicated action buttons directly navigating to `/official/hotspots`, `/official/accuracy`, and `/official/queue`. |
| **Loading Skeletons** | `rounded-xl`, `bg-bhoomi-canvas`, `animate-pulse` | Independent card skeletons preserving section bounds during asynchronous network fetching. |
| **Empty States** | `rounded-xl`, `border-dashed`, `bg-bhoomi-canvas/40` | Contextual empty state indicators for zero hotspots, zero accuracy records, and empty queues. |

---

## 4. Operational Boundaries & Data Safety

- **Geospatial Hotspot Boundary:** Hotspot KPIs reflect strictly confirmed, server-authoritative outbreaks from `GET /api/v1/official/hotspots` without unconfirmed prediction mixing.
- **Accuracy Invariant:** Preserves direct aggregate data from `GET /api/v1/official/accuracy` without frontend re-averaging or synthetic normalization.
- **Official Queue Isolation:** Operates strictly on `GET /api/v1/official/queue`, preserving the distinct data boundary between field agronomist assignments and official surveillance monitoring.

---

## 5. Responsive & Accessibility Verification

- **Breakpoints:** Tested across 1920×1080, 1440×900, 1280×800 (3-column layout), 1024×768, 768×1024 (2-column stacked layout), and 390×844 (single-column responsive stack) with zero clipping.
- **Color Contrast:** Headings `#0F172A` on `#FFFFFF` (16.2:1), metadata `#64748B` (4.6:1), exceeding WCAG AAA/AA standards.
- **Interactive Affordances:** Clean hover states (`hover:border-bhoomi-primary/40`), focus rings, and screen reader labels.

---

## 6. Regression & Quality Results

| Test Suite / Validation | Scope Verified | Result |
| :--- | :--- | :---: |
| `officialsDashboard.test.tsx` | Route protection, role access, API usage, skeleton loading, empty states, partial failure, manual refresh | **PASS (11/11)** |
| `officialsHotspotMap.test.tsx` | Hotspot map route protection and API bindings | **PASS (10/10)** |
| `officialsAccuracy.test.tsx` | Accuracy table and summary metrics | **PASS (12/12)** |
| `officialsQueue.test.tsx` | Official confirmation queue list and filters | **PASS (10/10)** |
| Full Test Suite | All 10 test suites | **PASS (88/88)** |
| ESLint (`npm run lint`) | Zero lint warnings / errors | **PASS (0 errors)** |
| TypeScript & Build (`npm run build`) | Zero type errors, clean production bundle generated | **PASS** |
