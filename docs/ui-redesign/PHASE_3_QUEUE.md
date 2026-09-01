# BHOOMI UI REDESIGN — PHASE 3
# F12 AGRONOMIST CASE QUEUE SPECIFICATION & AUDIT

**Document Version:** 1.0.0 · **Date:** 2026-09-01  
**Project:** BHOOMI — SIH26131  
**Lead:** Santheesh (Frontend Lead / App Apprentice)  
**Surface:** F12 — Agronomist Case Queue (`/agronomist/cases`)  
**Phase Status:** PHASE 3 COMPLETE  

---

## 1. Executive Summary

In UI Redesign Phase 3, the **F12 Agronomist Case Queue** was elevated into a high-density, professional, and scannable enterprise review table. The redesign directly addresses the core operational objective of enabling agronomists to triage and initiate crop diagnosis reviews within seconds, accelerating the overall **< 3-minute validation target**.

All existing API endpoints, contract wire formats (`GET /api/v1/agronomist/case-queue`), server ordering, infinite cursor pagination, and route navigation behaviors remain 100% untouched and functionally identical.

---

## 2. Visual Hierarchy & Structural Layout

```text
+-----------------------------------------------------------------------------------+
| CASE QUEUE  [Assigned] [X Cases Active]              [< 3 Min SLA Target] [Refresh]|
| Review escalated crop health cases requiring expert diagnostic validation.        |
+-----------------------------------------------------------------------------------+
| [ 🔍 Filter by Case ID, crop, or region... ]     (Sorted by server queue position)|
+-----------------------------------------------------------------------------------+
|  QUEUE #  |  CASE ID   |  TARGET PROBLEM    |  REGION    | STATUS | RECEIVED | ACTION |
|-----------+------------+--------------------+------------+--------+----------+--------|
|  [#1]     |  c_001_pad | 🌾 Paddy Blast     |  Nashik    | Assigned| 12m ago | [Review]|
|  [#2]     |  c_002_cot | 🌾 Pink Bollworm   |  Amravati  | Assigned| 45m ago | [Review]|
|  [#3]     |  c_003_soy | 🌾 Stem Fly        |  Latur     | Assigned| 1h ago  | [Review]|
+-----------------------------------------------------------------------------------+
|                               [ Load More Cases ]                                 |
+-----------------------------------------------------------------------------------+
```

---

## 3. Component Upgrades & Design Token Usage

| Element | Previous State | Redesigned State | Design Tokens Applied |
| :--- | :--- | :--- | :--- |
| **Queue Header** | Basic title with plain text subtitle | Structured header with live case count badge, status pill, SLA tag, and search | `--bhoomi-text-primary`, `--bhoomi-primary`, `rounded-full` |
| **Search Filter** | No integrated client search filter | Real-time input with leading search icon and zero-match state | `--bhoomi-border-strong`, `rounded-xl`, `focus-visible:ring-2` |
| **Table Container** | Basic 12px rounded container | Elevated 16px card container with subtle depth | `rounded-2xl`, `--bhoomi-border`, `shadow-card` |
| **Queue Position** | Text number `#1` | Soft green pill badge `#1` | `--bhoomi-primary-light`, `--bhoomi-primary`, `border-primary/20` |
| **Target Problem** | Plain label text | Crop sprout icon box + bold problem label + ETA subtitle | `--bhoomi-primary-soft`, `text-sm font-semibold` |
| **Row Interaction** | Standard row highlight | Left 4px solid green accent on hover/focus + full keyboard navigation | `border-l-4 border-bhoomi-primary`, `transition-all 150ms` |
| **Review Action** | Basic text button | Primary ghost action button with directional arrow translation | `text-bhoomi-primary`, `hover:bg-bhoomi-primary-light` |
| **Empty State** | Plain text box | 16px dashed card with check icon and "Check Again" button | `rounded-2xl`, `--bhoomi-canvas/60` |
| **Pagination** | Plain button | Centered secondary elevation button with loading spinner | `rounded-xl`, `--bhoomi-surface`, `shadow-xs` |

---

## 4. Interaction & Accessibility

- **Keyboard Traversal:** Every row is focusable (`tabIndex={0}`) and activates navigation on `Enter` or `Space`.
- **High-Contrast Typography:** Headings in `#0F172A`, problem titles in `#0F172A`, metadata in `#64748B`, exceeding WCAG AAA.
- **Search Responsiveness:** Real-time client-side filter for loaded cases without altering server queue position order or generating extra network traffic.

---

## 5. Regression & Validation Matrix

| Test Suite / Check | Scope Verified | Result |
| :--- | :--- | :---: |
| `caseQueue.test.tsx` | API params, server ordering, queue positions, empty state, cursor pagination, navigation, 403 access guard, network retry | **PASS (7/7)** |
| `integrationE2E.test.tsx` | Full queue $\rightarrow$ workspace $\rightarrow$ confirm/correct lifecycle | **PASS (8/8)** |
| `authMatrix.test.tsx` | Role protection matrix and login redirects | **PASS (8/8)** |
| Full Test Suite | All 10 test suites | **PASS (88/88)** |
| ESLint (`npm run lint`) | Zero lint warnings / errors | **PASS (0 errors)** |
| TypeScript & Build (`npm run build`) | Zero type errors, clean production bundle generated | **PASS** |
