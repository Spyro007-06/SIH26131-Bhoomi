# app/ — Flutter farmer app

**Owner:** Tharun. Santheesh supports (`docs/DESIGN.md` §3).

> **This is the Flutter app, not the Python package.** `backend/app/` is the
> Python package. Both names come from frozen docs, so the prefix disambiguates.

## Stack — pinned, `docs/DESIGN.md` §1

Flutter, targeting **Android**. One codebase, good camera and audio access on
low-end devices.

## Scaffolding

This tree is directories and a README. Nothing is scaffolded — no `pubspec.yaml`,
no `.dart` files, no generated config. Run your own tool over it:

```bash
cd app
flutter create . --project-name bhoomi
```

`flutter create` fills in around the existing directories rather than replacing
them. Commit the scaffold output as its own commit, separate from your first
feature, so the diff stays readable.

## Wire format

`docs/API_CONTRACT.md` is the contract, and it is frozen. Base URL `/api/v1`,
Bearer JWT with a `farmer` role claim, UUID string ids, ISO 8601 UTC timestamps.

Three things about it that shape the app specifically:

- Photos and audio never go through the API. Call `POST /assets/presign`, PUT the
  bytes to the returned URL, then reference the `asset_id` downstream (§3).
- Every consequential response carries `spoken_summary`, a short string the
  client reads aloud locally (§0).
- Requests carry `lang` (`mr-IN`, `hi-IN`, `ta-IN`, `en-IN`) where text is
  returned, and responses echo it (§0).

The UI rules are in `docs/PRD.md`. They are not restated here — two copies drift,
and the one in the PRD is the one that is frozen.

## Feature folders

| Folder | Feature | Endpoints |
|---|---|---|
| `lib/features/onboarding/` | F1 farm persistent memory | `POST /farms`, `PATCH /farms/{id}` |
| `lib/features/diagnose/` | F2 gate, F3 image identification | `POST /farms/{id}/diagnose` |
| `lib/features/doubt_doctor/` | F4 the Doubt Doctor | `POST /problems/{id}/clarify` |
| `lib/features/advisory/` | F7 grounded advisory + IPM ladder | `POST /advisory/query` |
| `lib/features/label_check/` | F8 pesticide label check | `POST /problems/{id}/label-check` |
| `lib/features/alerts/` | F5 risk alerts, F6 spread alerts | `GET /farms/{id}/alerts`, `POST /alerts/{id}/respond` |
| `lib/features/followup/` | F10 closed-loop follow-up | `GET /farms/{id}/followups/pending`, `POST /followups/{id}/respond` |
| `lib/features/timeline/` | F1 case file, F11 farm health | `GET /farms/{id}/timeline`, `/summary`, `/problems` |
| `lib/features/referrals/` | F13 referral and helpline | `GET /farms/{id}/referrals` |

`lib/core/` is app-wide plumbing — the HTTP client, auth token storage, routing.
`lib/models/` holds the Dart types for the wire shapes. `lib/widgets/` holds
shared widgets. Feature folders own their own screens.

Voice (F9) is not a folder — it crosses every screen. `POST /voice/transcribe`
and `POST /voice/synthesize` are Shruthi's, `docs/API_CONTRACT.md` §4.

## Two contract rules the app must not break

`docs/API_CONTRACT.md` §17 lists eleven invariants. Two of them are the client's
to honour, and both are safety rules rather than styling:

- **`is_stub: true` must render a stub banner.** When `VISION_MODEL=stub` the
  server sets it on every prediction. `docs/DESIGN.md` §12: silent stubs are how
  a demo dies. You can check what the server is running with
  `GET /api/v1/health`.
- **Never compose pesticide copy.** `verdict.message` is a fixed server-supplied
  string, rendered verbatim. The app does not reword it, summarise it, or write
  its own. Same for the `clarify` branch: no treatment text is rendered when
  `gate.outcome` is not `advise`.
