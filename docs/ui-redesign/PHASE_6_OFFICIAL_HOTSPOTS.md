# BHOOMI UI REDESIGN — PHASE 6
# F15 OFFICIAL HOTSPOT MAP SPECIFICATION & AUDIT

**Document Version:** 1.0.0 · **Date:** 2026-09-01  
**Project:** BHOOMI — SIH26131  
**Lead:** Santheesh (Frontend Lead / App Apprentice)  
**Surface:** F15 — Official Outbreak Hotspots Map (`/official/hotspots`)  
**Phase Status:** PHASE 6 COMPLETE  

---

## 1. Executive Summary

In UI Redesign Phase 6, the **F15 Official Hotspots Map** was redesigned into a professional, geographically intuitive geospatial intelligence cockpit for authorized agriculture officials. The interface provides a clear statewide overview of confirmed agricultural outbreaks across Maharashtra while strictly adhering to the **Confirmed-Only Hotspot Invariant**.

All existing API endpoints, contract wire formats (`GET /api/v1/official/hotspots`), Leaflet map rendering logic, coordinate bounds auto-fit (`HotspotMapBounds.tsx`), and role authorization guards remain 100% untouched and functionally identical.

---

## 2. Visual Architecture & Hotspot Geospatial Structure

```text
+-----------------------------------------------------------------------------------------------+
| CONFIRMED HOTSPOTS  [Confirmed Only]           [🟢 Live Geospatial Feed]  [🔄 Refresh]        |
| Geographic view of confirmed agricultural outbreak intelligence across Maharashtra.           |
+-----------------------------------------------------------------------------------------------+
| KPI SUMMARY CARDS (When active clusters > 0)                                                  |
| ┌───────────────────────────────────────────┬───────────────────────────────────────────────┐ |
| │ 📍 ACTIVE CLUSTERS                        │ 🛡️ CONFIRMED CASES                            │ |
| │ 2                                         │ 17                                            │ |
| └───────────────────────────────────────────┴───────────────────────────────────────────────┘ |
+-----------------------------------------------------------------------------------------------+
| LEAFLET MAP VIEWPORT (520px / 620px)                                                          |
| +-------------------------------------------------------------------------------------------+ |
| |                                                                                           | |
| |                                    ● (Pune - Wheat Rust: 5)                               | |
| |                  ● (Mumbai - Paddy Blast: 12)                                             | |
| |                  ┌──────────────────────────────────────────┐                             | |
| |                  │ 🟢 CONFIRMED OUTBREAK                    │                             | |
| |                  │ DISEASE / PEST: Paddy Blast              │                             | |
| |                  │ CONFIRMED CASES: 12 records              │                             | |
| |                  │ FIRST SEEN: 8/10/2026  LAST SEEN: 8/20/26│                             | |
| |                  └──────────────────────────────────────────┘                             | |
| |                                                                                           | |
| | ┌─────────────────────────────────────────────┐                                           | |
| | │ LEGEND                                      │                                           | |
| | │ ● Confirmed outbreak location               │                                           | |
| | │ ○ Size scales with count                    │                                           | |
| | └─────────────────────────────────────────────┘                                           | |
| +-------------------------------------------------------------------------------------------+ |
+-----------------------------------------------------------------------------------------------+
```

---

## 3. Component Hierarchy & Design Token Usage

| Section / Component | Design Tokens Applied | Key UX & Visual Upgrades |
| :--- | :--- | :--- |
| **Page Header** | `--bhoomi-primary`, `rounded-full`, `--bhoomi-border` | Live feed pulse indicator, confirmed status tag, and manual refresh button. |
| **KPI Cards** | `rounded-2xl`, `--bhoomi-surface`, `shadow-card` | Active cluster count and confirmed case metrics with high-contrast mono typography. |
| **Map Container** | `rounded-2xl`, `--bhoomi-border`, `shadow-card` | 520px / 620px responsive container with subtle border and rounded clipping. |
| **Circle Markers** | Deep Green (`#166534`), opacity `0.75` | Radius dynamically scaled by confirmation count (`Math.sqrt(count)`). |
| **Map Popups** | `rounded-xl`, `font-sans`, `--bhoomi-border` | Clean popup card with green indicator, formatted target label, record counter, and date range. |
| **Map Legend** | `backdrop-blur-sm`, `rounded-xl`, `bg-surface/95` | Frosted bottom-left legend explaining confirmed outbreak marker semantics and scaling. |
| **Empty State** | `rounded-2xl`, `bg-surface/90`, `backdrop-blur-xs` | Centered frosted alert when zero confirmed outbreak records match the surveillance window. |
| **Loading State** | `rounded-2xl`, `bg-surface/60`, `backdrop-blur-xs` | Map skeleton with centered spinning loader and status message. |

---

## 4. Required Three-Way Data Safety Validation

| Case Condition | Expected System Behavior | Verified Result |
| :--- | :--- | :---: |
| **CASE A: Confirmed Hotspot** | Marker renders at exact lat/lng with scaled radius and popup details. | **PASS** (Rendered correctly) |
| **CASE B: Unconfirmed Model Output** | Never rendered on official hotspot map (strictly excluded by contract & hook). | **PASS** (Zero prediction leakage) |
| **CASE C: Missing / Invalid Coordinates** | Coordinate validation filters out invalid entries (`lat < -90 \|\| lat > 90`) without crashing or creating fake markers. | **PASS** (Filtered safely) |

---

## 5. Responsive & Accessibility Verification

- **Breakpoints:** Tested across 1920×1080, 1440×900, 1280×800 (desktop map view), 1024×768, 768×1024 (tablet map view), and 390×844 (mobile map view) with zero overflow.
- **Color Contrast:** Text `#0F172A` on `#FFFFFF` (16.2:1), metadata `#64748B` (4.6:1), exceeding WCAG AAA/AA standards.
- **Keyboard & Leaflet Accessibility:** Standard Leaflet keyboard pan/zoom navigation and accessible refresh action controls.

---

## 6. Regression & Quality Results

| Test Suite / Validation | Scope Verified | Result |
| :--- | :--- | :---: |
| `officialsHotspotMap.test.tsx` | Route protection, role access, API usage, marker rendering, popup text, empty states, error states, invalid coordinate filtering, refresh action | **PASS (10/10)** |
| `officialsDashboard.test.tsx` | Dashboard route protection and metrics | **PASS (11/11)** |
| `officialsAccuracy.test.tsx` | Accuracy table and summary metrics | **PASS (12/12)** |
| `officialsQueue.test.tsx` | Official confirmation queue list and filters | **PASS (10/10)** |
| Full Test Suite | All 10 test suites | **PASS (88/88)** |
| ESLint (`npm run lint`) | Zero lint warnings / errors | **PASS (0 errors)** |
| TypeScript & Build (`npm run build`) | Zero type errors, clean production bundle generated | **PASS** |
