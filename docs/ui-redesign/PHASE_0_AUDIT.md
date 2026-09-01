# BHOOMI UI REDESIGN — PHASE 0 AUDIT
**Document Version:** 1.0.0 · **Date:** 2026-09-01  
**Project:** BHOOMI — SIH26131  
**Lead / Author:** Santheesh (Frontend Lead / App Apprentice)  
**Scope:** `portal/` Desktop Application  
**Phase Status:** PHASE 0 COMPLETE — ANALYSIS ONLY (No Application Source Code Modified)

---

## 1. Executive Summary

This document establishes the comprehensive visual, UX, component, layout, and architectural design foundation for the upcoming UI redesign of the **BHOOMI Desktop Portal** (`portal/`).

The BHOOMI portal serves two distinct enterprise user groups:
1. **F12 Agronomist Portal (`role: agronomist`)**: High-throughput expert validation workspace enabling agricultural officers to evaluate AI-escalated crop disease/pest cases in under 3 minutes.
2. **F15 Agriculture Officials Dashboard (`role: official`)**: Operational surveillance dashboard providing regional outbreak monitoring, model accuracy analytics, and confirmation queue tracking.

### Core Audit Findings
- **Functional Completeness:** Both F12 and F15 surfaces are functionally complete, 100% compliant with the frozen wire format (`docs/API_CONTRACT.md` v3.0), and achieve full passing test coverage (88/88 tests passing across 10 test suites).
- **Visual Gaps:** The current UI relies on functional baseline styling with inconsistent color depth, low contrast boundaries between card surfaces and page background, uniform card heights leading to awkward vertical whitespace, and generic button weights.
- **Redesign Opportunity:** Elevating the interface to a world-class, modern agricultural enterprise design standard (BHOOMI Deep Green `#2E7D32` accents, crisp `#FFFFFF` cards, refined `#F8FAFC` canvas, Slate typography `#0F172A`/`#475569`, 16px radius, and subtle border depth `#E2E8F0`) while maintaining 100% adherence to frozen contracts and hard architectural invariants.

---

## 2. Existing Portal Structure

### Technology Stack
- **Framework:** React 18.3 + TypeScript 5.5 + Vite 6.4
- **State & Server Cache:** TanStack React Query v5
- **Routing:** React Router v6 with Role-Based Route Guards (`RoleRoute`, `ProtectedRoute`)
- **Styling:** Tailwind CSS + Semantic CSS Tokens (`src/styles/tokens.css`)
- **Geospatial Visualization:** Leaflet 1.9 + React-Leaflet 4.2
- **Analytics Visualization:** Recharts 2.12
- **Data Validation:** Zod Schema Validation at boundaries

### Directory Hierarchy (`portal/src/`)
```text
portal/src/
├── app/                  # App shell, Router, and Provider setup
│   ├── App.tsx
│   ├── providers.tsx
│   └── router.tsx
├── components/           # Shared reusable UI primitives & feedback
│   ├── feedback/         # EmptyState, ErrorState, LoadingState
│   ├── layout/           # AppShell, Header, Sidebar, PageContainer
│   └── ui/               # Badge, Button, Card, Dialog, Input, Select, Skeleton, Table, Tooltip
├── features/
│   ├── agronomist/       # F12 components, pages, hooks, and schemas
│   ├── auth/             # Authentication provider, login page, hooks, demo bypass
│   └── officials/        # F15 components, pages, hooks, charts, and map
├── lib/
│   ├── api/              # ApiClient, endpoints inventory, demo data fallback, error handling
│   ├── auth/             # Token and user profile local storage
│   └── utils/            # Label formatters, date parsers, cn utility
├── routes/               # RoleRoute, ProtectedRoute, ForbiddenPage
├── styles/               # tokens.css, globals.css
└── types/                # api.ts, enums.ts, common.ts
```

---

## 3. F12 Agronomist Portal Audit

### Current Surfaces & Workflow
1. **Case Queue (`/agronomist/cases`)**:
   - Displays chronological stream of open/assigned cases (`status=assigned`) from `GET /api/v1/agronomist/case-queue`.
   - Visual elements: Status filter badge, queue depth counter, table list with `queue_position`, `eta_minutes`, region, crop label, opened time, and action link.
2. **Case Workspace (`/agronomist/cases/:caseId`)**:
   - Single-case inspection canvas consuming `GET /api/v1/cases/:id`.
   - Modules: Farm context, problem severity & farmer description, ranked model hypotheses (Top-3 with softmax bars), Decision Gate summary, Doubt Doctor field observations, dual-image evidence viewer with lightbox, treatments tried, pesticide label checks, and follow-up trend.
   - Action Bar: Fixed floating/sticky footer with authoritative actions (`Confirm Diagnosis`, `Correct Diagnosis`, `Request Farmer Info`).

### F12 Three-Minute Scanning Evaluation
| Criteria | Current State | Assessment | Redesign Recommendation |
| :--- | :--- | :--- | :--- |
| **Information Density** | High density, but flat card hierarchy | `NEEDS IMPROVEMENT` | Group related evidence into a cohesive 3-column operational cockpit. |
| **Visual Scanning** | Text-heavy evidence sections | `NEEDS IMPROVEMENT` | Use structured key-value chips and distinct confidence meters. |
| **Decision Flow** | Action bar at the bottom requires full page scroll | `NEEDS IMPROVEMENT` | Pin action bar into sticky viewport header or right-hand action drawer. |
| **Dual Image Review** | Side-by-side thumbnails with lightbox modal | `GOOD` | Retain lightbox modal; enlarge thumbnail preview container with zoom cue. |
| **Doubt Doctor / Gate** | Rendered as separate stacked cards | `NEEDS IMPROVEMENT` | Combine Gate outcome badge and Doubt Doctor Q&A into single AI Gate tile. |

---

## 4. F15 Official Portal Audit

### Current Surfaces
1. **Official Dashboard (`/official`)**: Aggregated surveillance overview featuring KPI metrics cards, mini-hotspot preview card, model accuracy snippet, and confirmation queue status.
2. **Confirmed Hotspots Map (`/official/hotspots`)**: Full-screen interactive Leaflet map rendering confirmed outbreak clusters from `GET /api/v1/officials/hotspots`.
3. **Model Accuracy Analytics (`/official/accuracy`)**: Recharts horizontal bar visualization comparing confirmed vs. corrected cases from `GET /api/v1/officials/accuracy`.
4. **Official Confirmation Queue (`/official/queue`)**: Regional operational table listing cases requiring surveillance attention from `GET /api/v1/officials/queue`.

### Invariant Checks
- **Hotspot Invariant:** Verified 100% compliant. Map only consumes confirmed outbreak coordinates; raw AI predictions and unconfirmed cases are structurally excluded.
- **Accuracy Invariant:** Verified 100% compliant. Zero client-side mathematical recomputations (e.g. `confirmed / total`). Server values are displayed verbatim.
- **Queue Segregation:** Verified 100% compliant. Dedicated query hook consumes `GET /api/v1/officials/queue` and never touches agronomist case queue.

---

## 5. Global Shell Audit

- **Structure:** `AppShell.tsx` wraps `Header` (top 64px) and a flex row containing `Sidebar` (left 256px) and scrollable main content area (`<Outlet />`).
- **Background Canvas:** Current `#FAFCF8` is subtly tinted warm green, which reduces perceived contrast against pure white `#FFFFFF` cards.
- **Layout Spacing:** Content container padding alternates between `p-6` and `p-8` across pages without a single layout shell token.

---

## 6. Header Audit

- **Current Implementation:** Fixed 64px height (`h-16`), white background, border-b (`#E5E7E3`), BHOOMI sprout logo, portal badge, user avatar chip, and "Sign Out" button.
- **Visual Gaps:**
  - Lack of breadcrumb or live surface breadcrumbs.
  - Avatar is a simple icon box without user initials fallback badge.
  - Portal role badge uses flat green styling that competes with the primary logo.
- **Recommended Direction:**
  - Clean border `#E2E8F0`, subtle shadow `0 1px 2px 0 rgba(0, 0, 0, 0.05)`.
  - Structured brand header: Logo + bold title + refined role pill (`Agronomist Workspace` / `Officials Surveillance`).
  - User profile menu with crisp avatar, name, and clean sign-out action.

---

## 7. Sidebar Audit

- **Current Implementation:** Fixed width 256px (`w-64`), border-r (`#E5E7E3`), navigation links with icon + label, role section header, and footer version pill (`BHOOMI v3.0 Desktop Portal Foundation`).
- **Visual Gaps:**
  - Active item uses light green tint (`#E8F5E9`) with dark green text (`#14532D`), which lacks modern elevation or accent bar indicators.
  - Inactive links have low contrast text (`#374151`) on light background.
  - No collapsible state for lower resolution desktop viewports (1024px).
- **Recommended Direction:**
  - Subtle slate sidebar (`#FFFFFF` with `#F8FAFC` accents and `#E2E8F0` border).
  - Active state: `#EAF4EA` background, `#2E7D32` text, 3px solid left green indicator pill.
  - Count badges for pending queue items.

---

## 8. Navigation Audit

- **Routing Model:** Declarative React Router v6 with `RoleRoute` guarding `/agronomist/*` and `/official/*`.
- **Integrity:** Zero dead links; active state matching correctly updates on route transitions.

---

## 9. Workspace Audit

- **Background:** `#FAFCF8` (slightly muted green-tinted white).
- **Max Width:** Unbounded `max-w-7xl` or full-width flex container.
- **Card Spacing:** Grid gaps range from `gap-4` to `gap-6`. Needs unification to a strict 16px/24px rhythm.

---

## 10. Color Audit

### Current Color Palette Extraction
| Token Name | Current Hex | Current Usage | Status |
| :--- | :--- | :--- | :--- |
| `bhoomi.green.900` | `#14532D` | Heavy headers, active brand text | Needs softening |
| `bhoomi.green.800` | `#166534` | Logo background, primary badges | Good |
| `bhoomi.green.700` | `#15803D` | Primary button backgrounds | Low contrast |
| `bhoomi.green.600` | `#2E7D32` | Primary brand accent | **Master Primary** |
| `bhoomi.green.500` | `#66BB6A` | Soft highlights | Accent |
| `bhoomi.green.100` | `#E8F5E9` | Active nav, soft badges | Retain |
| `bhoomi.green.50` | `#F1F8E9` | Table row alternate highlights | Replace with slate |
| `bhoomi.background` | `#FAFCF8` | Canvas background | Update to `#F8FAFC` |
| `bhoomi.border` | `#E5E7E3` | Card borders | Update to `#E2E8F0` |
| `bhoomi.text` | `#17201A` | Body and heading text | Update to `#0F172A` |
| `bhoomi.text-secondary`| `#374151` | Subtitles, metadata | Update to `#475569` |
| `bhoomi.danger` | `#C62828` | Critical severity, error alerts | Update to `#DC2626` |
| `bhoomi.warning` | `#D97706` | Moderate severity, warnings | Update to `#F59E0B` |
| `bhoomi.info` | `#2563EB` | Information notices | Retain `#2563EB` |

---

## 11. Proposed BHOOMI Color Tokens

```css
:root {
  /* Brand Core */
  --bhoomi-primary: #2E7D32;
  --bhoomi-primary-dark: #1B5E20;
  --bhoomi-primary-light: #EAF4EA;
  --bhoomi-primary-soft: #F3F8F3;

  /* Surfaces & Canvas */
  --bhoomi-canvas: #F8FAFC;
  --bhoomi-surface: #FFFFFF;
  --bhoomi-surface-hover: #F1F5F9;

  /* Borders & Dividers */
  --bhoomi-border: #E2E8F0;
  --bhoomi-border-strong: #CBD5E1;

  /* Typography */
  --bhoomi-text-primary: #0F172A;
  --bhoomi-text-secondary: #475569;
  --bhoomi-text-muted: #64748B;
  --bhoomi-text-disabled: #94A3B8;

  /* Semantic Status */
  --bhoomi-success: #16A34A;
  --bhoomi-warning: #F59E0B;
  --bhoomi-danger: #DC2626;
  --bhoomi-info: #2563EB;
  --bhoomi-escalation: #9333EA;
}
```

---

## 12. Typography Audit

- **Font Family:** Inter, system-ui, sans-serif.
- **Hierarchy Audit:**
  - Page Titles: Currently `text-2xl font-bold` (24px). Proposed: `24px / font-bold / text-slate-900 / tracking-tight`.
  - Section Headings: Currently `text-lg font-semibold` (18px). Proposed: `18px / font-semibold / text-slate-800`.
  - Card Titles: Currently `text-base font-semibold` (16px). Proposed: `15px / font-semibold / text-slate-800`.
  - Body Text: Currently `text-sm font-normal` (14px). Proposed: `14px / font-normal / text-slate-700 / leading-relaxed`.
  - Metadata / Captions: Currently `text-xs` (12px). Proposed: `12px / font-medium / text-slate-500`.
  - Badges / Chips: Currently `text-xs font-medium`. Proposed: `11px / font-semibold / uppercase / tracking-wider`.

---

## 13. Spacing Audit

- **Current Practice:** Inconsistent mix of `p-4`, `p-5`, `p-6`, `space-y-4`, `space-y-6`.
- **Proposed Unified Scale:** Strict 4px/8px modular scale:
  - 4px (`gap-1`), 8px (`gap-2`), 12px (`gap-3`), 16px (`gap-4`), 20px (`gap-5`), 24px (`gap-6`), 32px (`gap-8`), 48px (`gap-12`).

---

## 14. Card Audit

- **Current Card Styling:** `rounded-card` (14px), white background, border `#E5E7E3`, subtle shadow.
- **Proposed Redesign:**
  - Background: Pure White `#FFFFFF`.
  - Border: 1px solid `#E2E8F0`.
  - Radius: `rounded-2xl` (16px).
  - Shadow: `shadow-xs` / `0 1px 3px 0 rgba(0, 0, 0, 0.04)`.
  - Header: Integrated divider with clear title and optional action/badge slot.

---

## 15. Button Audit

| Variant | Current Style | Proposed Redesign |
| :--- | :--- | :--- |
| **Primary** | Solid green `#15803D` with text `#FFFFFF` | Solid brand green `#2E7D32` with hover `#1B5E20`, `shadow-xs`, 8px radius |
| **Secondary** | Gray border `#E5E7E3` with soft fill | Clean white card `#FFFFFF` with border `#CBD5E1` and text `#0F172A` |
| **Destructive**| Red border with red text | Red soft `#FEF2F2` with border `#FCA5A5` and text `#DC2626` |
| **Ghost** | Transparent with gray hover | Transparent with hover `#F1F5F9` and text `#475569` |

---

## 16. Badge Audit

| Semantic Category | Current Colors | Proposed Redesign |
| :--- | :--- | :--- |
| **Confirmed / Resolved** | Green bg `#E8F5E9` + `#14532D` text | Emerald `#ECFDF5` + `#047857` text + 1px `#A7F3D0` border |
| **Assigned / In Review** | Amber bg `#FEF3C7` + `#92400E` text | Amber `#FFFBEB` + `#B45309` text + 1px `#FDE68A` border |
| **Escalated / Critical** | Red bg `#FEE2E2` + `#B91C1C` text | Rose `#FFF1F2` + `#BE123C` text + 1px `#FECDD3` border |
| **Info Requested** | Blue bg `#EFF6FF` + `#1E40AF` text | Sky `#F0F9FF` + `#0369A1` text + 1px `#BAE6FD` border |
| **Target Label** | Slate bg `#F1F5F9` + `#334155` text | Slate `#F8FAFC` + `#334155` text + 1px `#E2E8F0` border |

---

## 17. Form Audit

- **Inputs / Textareas:** Currently use `rounded-lg`, border `#E5E7E3`, focus ring `#2E7D32`.
- **Proposed Redesign:** Refined 8px radius, border `#CBD5E1`, placeholder `#94A3B8`, focused outline `ring-2 ring-[#2E7D32]/20 border-[#2E7D32]`.

---

## 18. Table Audit

- **Current Table:** Clean semantic `<table>`, `<thead>` with light gray background, padded rows (`py-3.5`).
- **Proposed Redesign:**
  - Header: `#F8FAFC` background, uppercase 11px font, tracking-wider, text `#64748B`.
  - Row: Hover effect `#F8FAFC`, transition duration 150ms.
  - Cell padding: `px-4 py-3.5`.
  - Border: 1px bottom border `#F1F5F9`.

---

## 19. Map Audit

- **Leaflet Integration:** Contained in 480px height container with zoom control, custom tile layer, and circle markers sized by `confirmed_count`.
- **Proposed Redesign:**
  - Clean rounded-2xl container with 1px border `#E2E8F0`.
  - Floating translucent map legend in top-right corner.
  - Modern popup styling with high-contrast text and quick-filter button.

---

## 20. Chart Audit

- **Recharts Integration:** Responsive container rendering horizontal bar chart with custom tooltip.
- **Proposed Redesign:**
  - Rounded bar corners (`radius={[0, 4, 4, 0]}`).
  - Dual bars: Confirmed (`#16A34A`) vs. Corrected (`#F59E0B`).
  - Elevated custom HTML tooltip with shadow and crisp metric callouts.

---

## 21. Responsive Audit

| Viewport | Surface | Current Status | Findings |
| :--- | :--- | :--- | :--- |
| **1920×1080 (FHD)** | All | `GOOD` | Generous space; cards should maintain max-w constraint to prevent line stretch. |
| **1440×900 (Desktop)** | All | `GOOD` | Optimal layout presentation. |
| **1280×800 (Laptop)** | F12 / F15 | `GOOD` | Table and grid scale naturally. |
| **1024×768 (Tablet-L)** | F12 Workspace | `NEEDS IMPROVEMENT` | 3-column workspace compresses; should collapse to 2-column + sticky action drawer. |
| **768×1024 (Tablet-P)** | Tables / Map | `NEEDS IMPROVEMENT` | Sidebar needs collapsible drawer mode; tables require horizontal scroll container. |
| **390×844 (Mobile)** | All | `NEEDS IMPROVEMENT` | Portal is desktop-focused, but should maintain single-column readability. |

---

## 22. Accessibility Audit

- **Focus Visibility:** Custom focus rings (`*:focus-visible` with 2px offset) implemented.
- **Motion:** `@media (prefers-reduced-motion)` implemented in CSS.
- **Color Contrast:** All proposed primary text (`#0F172A`) on white (`#FFFFFF`) exceeds WCAG AAA (16.2:1). Secondary text (`#475569`) exceeds WCAG AA (7.0:1).
- **Semantics:** Proper heading hierarchy (`h1` per page, `h2` per major card section).

---

## 23. Component Inventory

| Component | Location | Shared? | F12 | F15 | Current Style | Redesign Priority |
| :--- | :--- | :---: | :---: | :---: | :--- | :--- |
| **AppShell** | `components/layout/AppShell.tsx` | Yes | Yes | Yes | Basic flex column | `P0 — High` |
| **Header** | `components/layout/Header.tsx` | Yes | Yes | Yes | Fixed white bar | `P0 — High` |
| **Sidebar** | `components/layout/Sidebar.tsx` | Yes | Yes | Yes | 256px fixed aside | `P0 — High` |
| **PageContainer** | `components/layout/PageContainer.tsx` | Yes | Yes | Yes | Simple padding wrapper | `P1 — Medium` |
| **Badge** | `components/ui/Badge.tsx` | Yes | Yes | Yes | Pill badges with variants | `P1 — Medium` |
| **Button** | `components/ui/Button.tsx` | Yes | Yes | Yes | Standard button variants | `P0 — High` |
| **Card** | `components/ui/Card.tsx` | Yes | Yes | Yes | White card with 14px radius | `P0 — High` |
| **Dialog / Modal**| `components/ui/Dialog.tsx` | Yes | Yes | No | Fixed overlay modal | `P1 — Medium` |
| **Input / Select** | `components/ui/Input.tsx` | Yes | Yes | Yes | Standard input controls | `P1 — Medium` |
| **Table** | `components/ui/Table.tsx` | Yes | Yes | Yes | Generic table wrapper | `P1 — Medium` |
| **CaseHeader** | `features/agronomist/components/CaseHeader.tsx` | No | Yes | No | Top metadata bar | `P0 — High` |
| **FarmContext** | `features/agronomist/components/FarmContext.tsx` | No | Yes | No | 2-col key-value grid | `P1 — Medium` |
| **HypothesesPanel**| `features/agronomist/components/HypothesesPanel.tsx` | No | Yes | No | Top-3 ranked list with bars | `P0 — High` |
| **GateSummary** | `features/agronomist/components/GateSummary.tsx` | No | Yes | No | Outcome badge + reason code | `P1 — Medium` |
| **EvidenceGallery**| `features/agronomist/components/EvidenceGallery.tsx` | No | Yes | No | Side-by-side photo cards | `P0 — High` |
| **CaseActionBar** | `features/agronomist/components/CaseActionBar.tsx` | No | Yes | No | Bottom action bar | `P0 — High` |
| **OfficialHotspotMap**| `features/officials/components/OfficialHotspotMap.tsx` | No | No | Yes | Leaflet map container | `P0 — High` |
| **AccuracyChart** | `features/officials/components/AccuracyChart.tsx` | No | No | Yes | Recharts bar container | `P1 — Medium` |
| **OfficialQueueTable**| `features/officials/components/OfficialQueueTable.tsx` | No | No | Yes | Full queue table | `P1 — Medium` |

---

## 24. Existing Design Token System

Existing tokens defined in `portal/src/styles/tokens.css` and mapped into `portal/tailwind.config.ts`:
- Colors prefixed with `bhoomi-*`
- Radius variable `--radius-card: 14px;`
- Shadow variable `--shadow-subtle`

---

## 25. Existing Styling Architecture

- **Tailwind Utility Convention:** Direct utility class combination in TSX files using `cn()` helper (clsx + tailwind-merge).
- **CSS Architecture:** Semantic CSS custom properties in `tokens.css` imported at root `globals.css`.

---

## 26. Visual Inconsistency Report

| Inconsistency | Location | Current State | Target Design System | Severity |
| :--- | :--- | :--- | :--- | :--- |
| **Card Radii** | App-wide | `14px` (`rounded-card`) mixed with `8px` (`rounded-lg`) | Unified `16px` (`rounded-2xl`) for cards, `8px` for buttons/inputs | `MEDIUM` |
| **Primary Green Shifting**| Header vs Buttons | `#166534` vs `#15803D` vs `#2E7D32` | Strictly `#2E7D32` primary across all interactive controls | `HIGH` |
| **Border Contrast** | Sidebar / Cards | `#E5E7E3` has low contrast against `#FAFCF8` | Distinct `#E2E8F0` border on crisp `#FFFFFF` cards over `#F8FAFC` | `HIGH` |
| **Status Badge Semantics**| Tables / Workspace | Inconsistent padding (`px-2 py-0.5` vs `px-2.5 py-1`) | Unified badge tokens with 11px font and 1px border | `MEDIUM` |
| **Action Bar Elevation** | Case Workspace | Flat card at bottom of scrollable page | Elevated sticky bottom bar with backdrop blur | `HIGH` |

---

## 27. UX Issues

### Priority Classification
- **P0 — Critical (Immediate Visual / Scanning Impact):**
  - F12 Workspace action buttons are located at the bottom of the page; agronomists must scroll past all evidence to confirm or correct.
  - High-confidence model predictions lack clear visual hierarchy distinguishing the top hypothesis from lower-tier alternatives.
- **P1 — Important (Readability & Polish):**
  - Table headers lack distinct background shading from row content.
  - Hotspot map controls and legends are unstyled default Leaflet elements.
  - Metric cards in Official Dashboard lack comparative change indicators or trend icons.
- **P2 — Polish (Micro-interactions):**
  - Button hover states lack subtle elevation transitions.
  - Modal dialogues lack smooth entrance scaling animation.

---

## 28. F12 Redesign Priorities

1. **Agronomist Header & Quick Sticky Action Bar:** Elevate authoritative actions (`Confirm`, `Correct`, `Request Info`) to be permanently visible without scrolling.
2. **Top Model Hypothesis Card:** Highlight the top AI prediction with a prominent confidence meter, clear diagnostic rationale, and immediate comparison against Doubt Doctor cues.
3. **Structured Dual-Photo Lightbox Inspector:** Enhance photographic evidence display with direct side-by-side zoom and view-type badges (`leaf` vs. `canopy`).
4. **3-Column Operational Layout:** Arrange Farm Context + Gate Summary (Col 1), Hypotheses + Doubt Doctor (Col 2), and Photo Evidence + Treatments (Col 3) for instant scanning.

---

## 29. F15 Redesign Priorities

1. **Surveillance KPI Grid:** Modernize top summary metrics (Active Outbreak Points, Top Regional Target, Queue Pressure, Overall Accuracy) with crisp icons and subtle status pills.
2. **Geospatial Hotspot Map Card:** Full-width modern map card with embedded floating legend, crop filter chip bar, and high-contrast cluster popups.
3. **Model Accuracy Analytics Surface:** Polished comparison charts displaying server accuracy per target label with clear confirmation volume badges.
4. **Confirmation Queue Operational View:** High-density, sortable surveillance queue table with district tags and severity badges.

---

## 30. Proposed Future Design System

### Design Tokens
- **Canvas:** `#F8FAFC` (Slate 50)
- **Surfaces:** `#FFFFFF` (White)
- **Primary Accent:** `#2E7D32` (BHOOMI Green 600)
- **Primary Hover:** `#1B5E20` (BHOOMI Green 800)
- **Primary Tint:** `#EAF4EA` (Soft Green 50)
- **Typography Primary:** `#0F172A` (Slate 900)
- **Typography Secondary:** `#475569` (Slate 600)
- **Typography Muted:** `#64748B` (Slate 500)
- **Borders:** `#E2E8F0` (Slate 200)
- **Radius Tokens:** Small `6px`, Medium `8px`, Large `12px`, Card `16px` (`rounded-2xl`), Full `9999px` (`rounded-full`).

---

## 31. Proposed Global Shell Specification

```text
+-----------------------------------------------------------------------------------+
|  [Logo] BHOOMI  |  [Agronomist Portal / Officials Surveillance]      [User] [Logout] |  (64px H)
+-------------------+---------------------------------------------------------------+
|                   |  [Page Title / Breadcrumb]                [Header Actions]     |
|  [Nav Item 1]     +---------------------------------------------------------------+
|  [Nav Item 2]     |                                                               |
|  [Nav Item 3]     |                     WORKSPACE CANVAS                          |
|                   |                       (#F8FAFC)                               |
|                   |                                                               |
|                   |  +---------------------+  +--------------------------------+  |
|                   |  | Card 1 (#FFFFFF)    |  | Card 2 (#FFFFFF)               |  |
|                   |  +---------------------+  +--------------------------------+  |
|                   |                                                               |
|  [Footer Pill]    |                                                               |
+-------------------+---------------------------------------------------------------+
 (256px W Sidebar)                           (100% Flex Main Content)
```

---

## 32. API Contract Safety Notes

> [!IMPORTANT]
> **API CONTRACT PRESERVATION:**
> All upcoming redesign phases will strictly preserve all endpoint paths, query parameters, request bodies, response shapes, and field names defined in `docs/API_CONTRACT.md` v3.0. Zero contract modifications will occur.

---

## 33. PRD Compliance Notes

- F12 Agronomist Case Workspace retains all multimodal evidence sections required by PRD §12.
- F15 Agriculture Officials Surveillance retains confirmed-only map points and server-authoritative accuracy reporting required by PRD §15.
- The redesign directly supports the PRD requirement of completing expert validation reviews in **under 3 minutes**.

---

## 34. Phase 1 Implementation Scope

In **UI Redesign Phase 1**, the following foundation tasks will be executed:
1. Update `portal/src/styles/tokens.css` with the approved BHOOMI Color & Radius Design Tokens.
2. Update `portal/tailwind.config.ts` with the new design tokens.
3. Redesign `AppShell`, `Header`, `Sidebar`, and `PageContainer` to match the Enterprise Global Shell specification.
4. Refine shared UI components: `Card`, `Button`, `Badge`, `Input`, `Table`.
5. Verify test pass rates (`npm run test`), lint (`npm run lint`), and build (`npm run build`).

---

## 49. API Contract Matrix

| UI Surface | Endpoint | Method | Data Used | Status |
| :--- | :--- | :---: | :--- | :---: |
| **Login Surface** | `/api/v1/auth/login` | `POST` | `email`, `password` $\rightarrow$ `access_token`, `user` | **PASS** |
| **Case Queue** | `/api/v1/agronomist/case-queue` | `GET` | `status`, `limit`, `cursor` $\rightarrow$ `cases`, `next_cursor` | **PASS** |
| **Case Workspace** | `/api/v1/cases/:id` | `GET` | Path `id` $\rightarrow$ `CaseBundle` (farm, problem, hypotheses, gate, observations, photos, treatments, label checks) | **PASS** |
| **Confirm Action** | `/api/v1/cases/:id/confirm` | `POST` | `verdict="confirmed"`, `treatment`, `notes` $\rightarrow$ `confirmation_id`, `spread_alerts_issued` | **PASS** |
| **Correct Action** | `/api/v1/cases/:id/confirm` | `POST` | `verdict="corrected"`, `corrected_label`, `treatment`, `notes` $\rightarrow$ `confirmation_id`, `spread_alerts_issued` | **PASS** |
| **Request Info Action** | `/api/v1/cases/:id/request-info`| `POST` | `question`, `question_localized` $\rightarrow$ `case_id`, `status="assigned"`, `info_requested_at` | **PASS** |
| **Hotspot Map** | `/api/v1/officials/hotspots` | `GET` | `region`, `crop`, `from`, `to` $\rightarrow$ `points`, `totals_by_label` | **PASS** |
| **Model Accuracy** | `/api/v1/officials/accuracy` | `GET` | `from`, `to` $\rightarrow$ `by_label`, `window` | **PASS** |
| **Official Queue** | `/api/v1/officials/queue` | `GET` | `limit`, `cursor` $\rightarrow$ `queue`, `next_cursor` | **PASS** |

---

## 50. PRD Matrix

| Requirement | Surface | Existing Implementation | UI Issue | Priority |
| :--- | :--- | :--- | :--- | :---: |
| **< 3 Min Expert Review** | F12 Case Workspace | Stacked evidence cards | Bottom action bar requires scrolling | `P0` |
| **Ranked AI Hypotheses** | F12 Hypotheses Panel | Top-3 list with softmax percentage | Top hypothesis needs elevated visual prominence | `P0` |
| **Dual Photo Inspection** | F12 Evidence Gallery | Side-by-side thumbnails with modal | Thumbnails need larger preview container | `P1` |
| **Decision Gate Summary** | F12 Gate Summary | Outcome badge + reason code | Needs unified visual card with Doubt Doctor | `P1` |
| **Confirmed-Only Hotspots**| F15 Hotspots Map | Leaflet circle markers | Map container needs modern rounded card styling | `P0` |
| **Confirmed vs. Corrected**| F15 Accuracy Analytics | Recharts horizontal bars | Bar chart needs modern tooltips and metric badges | `P1` |
| **Queue Depth Tracking** | F15 Confirmation Queue | Status summary table | Table headers need distinct background elevation | `P1` |

---

## 51. Component Matrix

| Component | Location | Shared? | F12 | F15 | Redesign Priority |
| :--- | :--- | :---: | :---: | :---: | :---: |
| `AppShell` | `components/layout/AppShell.tsx` | Yes | Yes | Yes | `P0` |
| `Header` | `components/layout/Header.tsx` | Yes | Yes | Yes | `P0` |
| `Sidebar` | `components/layout/Sidebar.tsx` | Yes | Yes | Yes | `P0` |
| `Card` | `components/ui/Card.tsx` | Yes | Yes | Yes | `P0` |
| `Button` | `components/ui/Button.tsx` | Yes | Yes | Yes | `P0` |
| `Badge` | `components/ui/Badge.tsx` | Yes | Yes | Yes | `P1` |
| `Table` | `components/ui/Table.tsx` | Yes | Yes | Yes | `P1` |
| `Input` / `Select` | `components/ui/Input.tsx` | Yes | Yes | Yes | `P1` |
| `Dialog` | `components/ui/Dialog.tsx` | Yes | Yes | No | `P1` |
| `CaseHeader` | `features/agronomist/components/CaseHeader.tsx` | No | Yes | No | `P0` |
| `CaseActionBar` | `features/agronomist/components/CaseActionBar.tsx` | No | Yes | No | `P0` |
| `HypothesesPanel` | `features/agronomist/components/HypothesesPanel.tsx` | No | Yes | No | `P0` |
| `OfficialHotspotMap`| `features/officials/components/OfficialHotspotMap.tsx` | No | No | Yes | `P0` |
| `AccuracyChart` | `features/officials/components/AccuracyChart.tsx` | No | No | Yes | `P1` |
| `OfficialQueueTable`| `features/officials/components/OfficialQueueTable.tsx` | No | No | Yes | `P1` |

---

## 52. Color Matrix

| Token | Current Value | Proposed Value | Usage |
| :--- | :--- | :--- | :--- |
| **Primary Brand** | `#15803D` / `#166534` | `#2E7D32` | Primary buttons, brand logo, active navigation indicators |
| **Primary Dark** | `#14532D` | `#1B5E20` | Hover states, deep brand contrast |
| **Primary Light** | `#E8F5E9` | `#EAF4EA` | Active navigation pill fill, badge backgrounds |
| **Canvas Background** | `#FAFCF8` | `#F8FAFC` | Main app background canvas |
| **Card Surface** | `#FFFFFF` | `#FFFFFF` | Elevated card surfaces |
| **Border Subdued** | `#E5E7E3` | `#E2E8F0` | Card borders, dividers |
| **Border Strong** | `#D1D5D1` | `#CBD5E1` | Input borders, table headers |
| **Text Primary** | `#17201A` | `#0F172A` | Page titles, primary content, card headings |
| **Text Secondary** | `#374151` | `#475569` | Metadata, subtitles, secondary navigation |
| **Text Muted** | `#6B7280` | `#64748B` | Table headers, timestamps, helper text |
| **Semantic Success** | `#2E7D32` | `#16A34A` | Resolved badges, confirmed cases |
| **Semantic Warning** | `#D97706` | `#F59E0B` | Moderate severity, pending alerts |
| **Semantic Danger** | `#C62828` | `#DC2626` | Critical severity, destructive actions |
| **Semantic Info** | `#2563EB` | `#2563EB` | Information callouts, links |
| **Semantic Escalation** | `#7C3AED` | `#9333EA` | Gate escalation badges, expert review flags |

---

## 53. Final Phase 0 Summary

- **CURRENT STATE:** Functionally complete, 100% contract-compliant frontend with all 88 unit and integration tests passing. UI is cleanly organized but visually flat.
- **DESIGN DIRECTION:** Modern, high-trust agricultural enterprise interface inspired by top-tier operational dashboards (BHOOMI Green `#2E7D32` accents, Slate typography `#0F172A`, `#F8FAFC` canvas, and `#FFFFFF` cards with `#E2E8F0` borders).
- **TOP 10 UI ISSUES:**
  1. Low contrast between card borders (`#E5E7E3`) and background (`#FAFCF8`).
  2. Bottom-pinned action bar in F12 workspace requiring full-page scrolling.
  3. Lack of visual hierarchy differentiating Top-1 hypothesis from ranked alternatives.
  4. Inconsistent primary green values (`#15803D`, `#166534`, `#2E7D32`).
  5. Flat active navigation states in the sidebar.
  6. Lack of distinct background fill on table headers.
  7. Unstyled default Leaflet map control buttons.
  8. Missing quick metric trends / indicator chips on dashboard cards.
  9. Inconsistent card border radii across layout modules.
  10. Compact viewports (1024px) lack responsive action drawer adaptation.
- **TOP 10 DESIGN PRIORITIES:**
  1. Unified BHOOMI Design Token system (`tokens.css` + `tailwind.config.ts`).
  2. Redesigned Enterprise Global Shell (`Header` + `Sidebar` + `PageContainer`).
  3. Sticky/Docked F12 Action Bar for instant < 3-minute validation.
  4. Elevated Top AI Hypothesis Card with confidence bar & margin indicators.
  5. 3-Column multimodal case review layout.
  6. High-contrast Hotspot Map with embedded floating legend.
  7. Refined Accuracy Bar Chart with tooltip metric callouts.
  8. Polished Confirmation Queue table with semantic status badges.
  9. Unified Card & Button hierarchy across all surfaces.
  10. WCAG AA/AAA compliant color contrast across all text elements.
- **F12 PRIORITIES:** Workspace information hierarchy $\rightarrow$ Sticky action bar $\rightarrow$ Dual-photo lightbox $\rightarrow$ Case queue scanning.
- **F15 PRIORITIES:** Surveillance KPI header $\rightarrow$ Full-width Hotspot map $\rightarrow$ Accuracy analytics bars $\rightarrow$ Confirmation queue table.
- **GLOBAL SHELL PRIORITIES:** Header brand bar $\rightarrow$ Sidebar active indicators $\rightarrow$ `#F8FAFC` workspace background.
- **API CONSTRAINTS:** 100% frozen wire format (`docs/API_CONTRACT.md` v3.0). Zero endpoint or field changes.
- **PRD CONSTRAINTS:** Preserve < 3-minute review target, confirmed-only hotspot invariant, and server-authoritative accuracy metrics.
- **PHASE 1 READY CHECK:** ALL CHECKS VERIFIED. READY FOR PHASE 1 IMPLEMENTATION.

---

## 54. Phase 1 Ready Check

- [x] Repository inspected
- [x] Portal structure inspected
- [x] F12 inspected
- [x] F15 inspected
- [x] Header inspected
- [x] Sidebar inspected
- [x] Navigation inspected
- [x] Colors extracted
- [x] Typography audited
- [x] Spacing audited
- [x] Cards audited
- [x] Buttons audited
- [x] Badges audited
- [x] Forms audited
- [x] Tables audited
- [x] Map audited
- [x] Charts audited
- [x] Responsive behavior audited
- [x] Accessibility audited
- [x] Shared components inventoried
- [x] Styling architecture documented
- [x] API contract reviewed
- [x] PRD reviewed
- [x] Hotspot invariant verified
- [x] Accuracy source verified
- [x] Official queue source verified
- [x] Future design system specified
- [x] Phase 1 scope defined
- [x] No application functionality changed
- [x] No API changed
- [x] No PRD changed
- [x] No routes changed
- [x] Working tree clean
