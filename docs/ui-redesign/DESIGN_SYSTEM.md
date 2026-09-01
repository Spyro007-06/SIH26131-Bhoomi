# BHOOMI Portal Design System
**Version:** 1.0.0 · **Date:** 2026-09-01  
**Project:** BHOOMI — SIH26131  
**Lead:** Santheesh (Frontend Lead / App Apprentice)  
**Scope:** Shared UI Component Layer for F12 Agronomist & F15 Official Portals  

---

## 1. Design Principles

1. **Trust & Precision:** Clean, high-contrast layouts designed for high-consequence agricultural diagnostics and regional outbreak surveillance.
2. **Operational Efficiency:** Dense, scannable information hierarchy supporting < 3-minute agronomist decision turnaround.
3. **Restrained Brand Accent:** BHOOMI Green (`#2E7D32`) is used deliberately for identity, active navigation, and primary decisions over a calm `#F8FAFC` slate canvas and crisp `#FFFFFF` cards.
4. **Zero Layout Shift & Accessibility:** Full WCAG AAA contrast for primary content, strict keyboard focus indicators, and smooth 150ms state transitions.

---

## 2. Design Tokens

### 2.1 Color System

#### Brand & Canvas Tokens
| Token Name | Hex Code | Purpose / Application |
| :--- | :--- | :--- |
| `--bhoomi-primary` | `#2E7D32` | Primary brand accent, primary buttons, active state indicators |
| `--bhoomi-primary-dark` | `#1B5E20` | Primary hover and active click states |
| `--bhoomi-primary-light`| `#EAF4EA` | Active navigation pills, soft badge backgrounds |
| `--bhoomi-primary-soft` | `#F3F8F3` | Navigation hover fills, subtle container highlights |
| `--bhoomi-canvas` | `#F8FAFC` | Main application background canvas (Slate 50) |
| `--bhoomi-surface` | `#FFFFFF` | Elevated card surfaces, modals, popovers |
| `--bhoomi-surface-soft` | `#F1F5F9` | Secondary chip backgrounds, table header fills |

#### Border & Divider Tokens
| Token Name | Hex Code | Purpose / Application |
| :--- | :--- | :--- |
| `--bhoomi-border` | `#E2E8F0` | Default card borders, header/sidebar dividers (Slate 200) |
| `--bhoomi-border-strong` | `#CBD5E1` | Input outlines, active table borders (Slate 300) |

#### Typography Tokens
| Token Name | Hex Code | Purpose / Application |
| :--- | :--- | :--- |
| `--bhoomi-text-primary` | `#0F172A` | Page titles, card titles, key metric numbers (Slate 900) |
| `--bhoomi-text-secondary`| `#475569` | Body copy, secondary labels, navigation text (Slate 600) |
| `--bhoomi-text-muted` | `#64748B` | Table headers, timestamps, helper text (Slate 500) |
| `--bhoomi-text-disabled`| `#94A3B8` | Section uppercase labels, disabled controls (Slate 400) |

#### Semantic Status Tokens
| Semantic Category | Base Color | Soft Background | Border Color | Typical Usage |
| :--- | :--- | :--- | :--- | :--- |
| **Success** | `#16A34A` | `#ECFDF3` | `#A7F3D0` | Confirmed verdicts, resolved cases |
| **Warning** | `#F59E0B` | `#FFF7DB` | `#FDE68A` | Moderate severity, pending validations |
| **Danger** | `#DC2626` | `#FEF2F2` | `#FECDD3` | Critical severity, destructive actions |
| **Info** | `#2563EB` | `#EFF6FF` | `#BAE6FD` | System guidance, informational chips |
| **Escalation** | `#9333EA` | `#FAF5FF` | `#E9D5FF` | Gate escalations, expert review tags |

---

### 2.2 Typography Scale
- **Display / Page Title:** `24px` / `font-bold` (700) / line-height 1.25 (`tracking-tight`)
- **Section Heading:** `18px` / `font-semibold` (600) / line-height 1.3
- **Card Title:** `16px` / `font-semibold` (600) / line-height 1.3
- **Body Text:** `14px` / `font-normal` (400) / line-height 1.5
- **Body Medium / Action:** `14px` / `font-medium` (500) / line-height 1.4
- **Metadata / Caption:** `12px` / `font-medium` (500) / line-height 1.4
- **Badge / Micro Tag:** `11px` / `font-semibold` (600) / uppercase / tracking-wider

---

### 2.3 Spacing & Radius Scale
- **Spacing Steps:** `4px` (`gap-1`), `8px` (`gap-2`), `12px` (`gap-3`), `16px` (`gap-4`), `20px` (`gap-5`), `24px` (`gap-6`), `32px` (`gap-8`), `48px` (`gap-12`).
- **Corner Radii:**
  - `rounded-md` (`6px`): Small badges and tooltips.
  - `rounded-xl` (`12px`): Buttons, inputs, selects, and icon containers.
  - `rounded-2xl` (`16px`): Cards, dialog modals, and tables.
  - `rounded-full` (`9999px`): Status pills and user avatar chips.

---

### 2.4 Elevation & Shadows
- **Border-First Design:** All surfaces maintain a 1px solid border (`#E2E8F0` or `#CBD5E1`).
- **Shadows:**
  - `shadow-xs`: `0 1px 2px 0 rgba(0, 0, 0, 0.05)` (Buttons, subtle chips)
  - `shadow-card`: `0 1px 3px 0 rgba(15, 23, 42, 0.04), 0 1px 2px -1px rgba(15, 23, 42, 0.02)` (Cards, tables)
  - `shadow-xl`: `0 20px 25px -5px rgba(0, 0, 0, 0.1), 0 10px 10px -5px rgba(0, 0, 0, 0.04)` (Modals)

---

## 3. Shared Component Inventory

| Component | Location | Variants / Types | Key States Supported |
| :--- | :--- | :--- | :--- |
| **`Button`** | `src/components/ui/Button.tsx` | `primary`, `secondary`, `outline`, `danger`, `ghost` | Default, hover, active, focus, disabled, loading |
| **`Badge`** | `src/components/ui/Badge.tsx` | `primary`, `secondary`, `success`, `warning`, `danger`, `info`, `escalation`, `neutral`, `outline` | `sm` (11px), `md` (12px) |
| **`Card`** | `src/components/ui/Card.tsx` | `Card`, `CardHeader`, `CardTitle`, `CardDescription`, `CardContent`, `CardFooter` | Default, hover, custom padding |
| **`Input`** | `src/components/ui/Input.tsx` | Text, password, search (with `icon` slot) | Default, focus, disabled, error, helperText |
| **`Select`** | `src/components/ui/Select.tsx` | Native select wrapper with placeholder | Default, focus, disabled, error |
| **`Table`** | `src/components/ui/Table.tsx` | `Table`, `TableHeader`, `TableBody`, `TableRow`, `TableHead`, `TableCell`, `TableFooter` | Default, row hover, row selected |
| **`Dialog`** | `src/components/ui/Dialog.tsx` | Modal dialogue with backdrop blur | Open, closing, Escape key dismiss, backdrop click |
| **`Alert`** | `src/components/ui/Alert.tsx` | `success`, `warning`, `danger`, `info`, `escalation` | Inline feedback with semantic icon |
| **`Tooltip`** | `src/components/ui/Tooltip.tsx` | Hover/focus tooltip with dark navy surface | Hover, focus, dismiss on blur |
| **`Skeleton`** | `src/components/ui/Skeleton.tsx` | Neutral pulse placeholder | Responsive height/width |
| **`EmptyState`** | `src/components/feedback/EmptyState.tsx` | Icon + title + description + action slot | Empty queue, zero results |
| **`ErrorState`** | `src/components/feedback/ErrorState.tsx` | Error icon + message + code chip + retry action | API error, network fault |
| **`LoadingState`**| `src/components/feedback/LoadingState.tsx`| Spinner + loading message | Query loading, background refresh |

---

## 4. Accessibility & Interaction Rules

1. **Focus Ring:** Every interactive element uses `focus-visible:ring-2 focus-visible:ring-bhoomi-primary focus-visible:ring-offset-2`.
2. **Contrast Standards:** All text-to-background combinations meet or exceed WCAG 2.1 AA (4.5:1) and AAA (7:1 for headers).
3. **Motion Sensitivity:** All transitions (150ms duration) respect `@media (prefers-reduced-motion: reduce)`.
4. **Semantic HTML:** Pure HTML5 primitives (`<button>`, `<header>`, `<aside>`, `<table>`, `<dialog>`) with minimal ARIA.

---

## 5. Feature Compatibility Validation

- **F12 Agronomist Workspace:** Fully supports multimodal case evidence cards, Top-1 confidence meter, dual-image lightbox, and sticky action buttons.
- **F15 Official Surveillance:** Fully supports KPI summary tiles, full-width Leaflet map card wrappers, accuracy comparison chart containers, and high-density queue tables.
