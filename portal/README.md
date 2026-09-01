# BHOOMI Desktop Portal (`portal/`)

**Owner:** Santheesh — Frontend Lead / App Apprentice  
**Feature Scope:** F12 Agronomist Case Workspace + F15 Agriculture Officials Surveillance Dashboard  
**API Specification:** `docs/API_CONTRACT.md` (v3.0 Frozen)  
**System Principles:** `docs/PRD.md` (v3.0 Frozen) · `docs/DESIGN.md` (v3.0 Frozen)

---

## 1. Technology Stack
- **Framework:** React 18 + TypeScript + Vite
- **Routing:** React Router v6 with Role-Based Route Guards (`RoleRoute`, `ProtectedRoute`)
- **State Management & Caching:** TanStack React Query v5
- **Styling:** Tailwind CSS + Semantic BHOOMI Design Tokens (`src/styles/tokens.css`)
- **Maps:** Leaflet + React-Leaflet
- **Visualizations:** Recharts (accessible, responsive)
- **Validation:** Zod Schema Validation at the API boundary
- **Testing:** Vitest + React Testing Library

---

## 2. Getting Started & Development

### Prerequisites
- Node.js 18+
- npm 9+

### Installation & Environment Setup
```bash
# Navigate to portal directory
cd portal

# Install dependencies
npm install

# Configure environment
cp .env.example .env.local
```

### Environment Variables
| Variable | Description | Default / Example |
| :--- | :--- | :--- |
| `VITE_API_BASE_URL` | Base endpoint URL for the Bhoomi backend API | `http://localhost:8000/api/v1` (or `/api/v1` for reverse-proxy) |

### Development Scripts
```bash
# Start local development server (http://localhost:5173)
npm run dev

# Run linting (ESLint)
npm run lint

# Run test suite (Vitest)
npm run test

# Compile TypeScript and build production bundle
npm run build

# Preview production build locally
npm run preview
```

---

## 3. Application Surfaces & Routing

### Public Routes
- `/login` — Unified authentication surface for Agronomists and Officials.

### F12 — Agronomist Portal (`role: agronomist`)
- `/agronomist/cases` — **Case Queue**: Server-ordered case queue with ETA estimations, queue position tags, and region filters.
- `/agronomist/cases/:caseId` — **Case Workspace**: Pre-analysed multimodal review workspace (< 3 min review target) featuring:
  - Farm context (crop, variety, growth stage, location).
  - Problem severity and opened timestamp.
  - Ranked model hypotheses with confidence score distributions.
  - Decision Gate outcome and Doubt Doctor field observations.
  - High-resolution dual-photo evidence with lightbox inspector.
  - Treatments tried, pesticide label check verdicts, and follow-up trend.
  - Authoritative Actions: `CONFIRM` (`POST /cases/:id/confirm`), `CORRECT` (`POST /cases/:id/confirm`), `REQUEST INFO` (`POST /cases/:id/request-info`).

### F15 — Officials Surveillance Portal (`role: official`)
- `/official` — **Surveillance Dashboard Shell**: System overview aggregating active hotspot previews, model accuracy previews, and confirmation queue status.
- `/official/hotspots` — **Confirmed Hotspot Map**: Interactive geospatial map strictly visualizing confirmed outbreak clusters from `GET /officials/hotspots`.
- `/official/accuracy` — **Model Accuracy Analytics**: Server-reported validation metrics from `GET /officials/accuracy` comparing confirmed vs corrected case counts without client-side formula recalculation.
- `/official/queue` — **Official Confirmation Queue**: Dedicated operational table from `GET /officials/queue` displaying regional case load requiring attention.

---

## 4. Key Architectural & Contract Invariants

1. **Confirmed-Only Hotspot Invariant:**  
   The Official Hotspot Map displays only confirmed outbreak records from `GET /api/v1/officials/hotspots`. Raw model predictions, unconfirmed AI hypotheses, and agronomist queue records never appear on the official map.

2. **Server-Authoritative Accuracy Invariant:**  
   Accuracy values are rendered verbatim from `GET /api/v1/officials/accuracy`. The client never calculates or reconstructs accuracy metrics.

3. **Queue Segregation Invariant:**  
   The Official Queue (`/official/queue`) exclusively consumes `GET /api/v1/officials/queue` and is strictly isolated from the Agronomist Case Queue (`/agronomist/case-queue`).

4. **Zero Mock Production Data:**  
   The production build relies strictly on live backend data and fails gracefully with retryable error states upon network/server interruption. No hardcoded mock/fake fixtures exist in production paths.

---

## 5. Directory Structure
```text
portal/
├── public/                 # Static public assets
├── src/
│   ├── app/                # App component and router configuration
│   ├── components/         # Reusable UI primitives, feedback, and layout shells
│   ├── features/
│   │   ├── agronomist/     # F12 components, pages, API hooks, and schemas
│   │   ├── auth/           # Authentication state, provider, and login surface
│   │   └── officials/      # F15 components, pages, API hooks, and schemas
│   ├── lib/
│   │   ├── api/            # Base API client and frozen endpoint inventory
│   │   ├── auth/           # Token storage and session manager
│   │   └── utils/          # Formatting, date parsing, and class helpers
│   ├── routes/             # Route guards (ProtectedRoute, RoleRoute)
│   ├── styles/             # Global CSS and design tokens
│   ├── test/               # Vitest integration and unit test suites
│   └── types/              # TypeScript types mapped to API_CONTRACT.md
├── package.json
├── tailwind.config.ts
├── tsconfig.json
└── vite.config.ts
```
