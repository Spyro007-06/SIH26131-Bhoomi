# portal/ — agronomist portal + officials dashboard

**Owner:** Santheesh (`docs/DESIGN.md` §3).

Desktop users. Kept separate from the Flutter workstream so two people build in
parallel without merge contention.

## Stack — pinned, `docs/DESIGN.md` §1

**React + Vite + Tailwind**, with **Leaflet** for maps.

## Scaffolding

This tree is directories and a README. Nothing is scaffolded — no
`package.json`, no `vite.config.ts`, no `tailwind.config.js`, no `.tsx` files.
Run your own tool over it:

```bash
npm create vite@latest portal -- --template react-ts
```

Then add Tailwind and Leaflet. Commit the scaffold output as its own commit,
separate from your first page, so the diff stays readable.

## Wire format

`docs/API_CONTRACT.md` is the contract, and it is frozen. Base URL `/api/v1`,
Bearer JWT, UUID string ids, ISO 8601 UTC timestamps. Pagination is
`?limit=20&cursor=<opaque>` with `next_cursor` in the response, null when
exhausted (§0).

Errors always arrive in one envelope (§0), so write one handler:

```json
{ "error": { "code": "FORBIDDEN", "message": "...", "details": { } } }
```

## Two surfaces, two roles

### F12 — agronomist portal · role `agronomist`

The expert loop. `docs/API_CONTRACT.md` §12 and §13.

| Page | Endpoint |
|---|---|
| Case queue, oldest first | `GET /agronomist/case-queue?status=assigned` |
| Case bundle — the screen the agronomist works in | `GET /cases/{id}` |
| Confirm or correct | `POST /cases/{id}/confirm` |
| Ask the farmer for more | `POST /cases/{id}/request-info` |

The bundle is the important screen. It carries the farm, the problem, ranked
model hypotheses, the gate decision, the Doubt Doctor answer, every image,
treatments tried, label checks and the follow-up trend — so the agronomist
decides in minutes, not by interrogating the farmer.

`POST /cases/{id}/confirm` returns `spread_alerts_issued`, the F6 fan-out count.
Show it. It is the moment one confirmation becomes a village-wide warning, and it
is the most demonstrable thing in the product.

### F15 — officials dashboard · role `official`

Surveillance. `docs/API_CONTRACT.md` §15.

| Page | Endpoint |
|---|---|
| Hotspot map (Leaflet) | `GET /officials/hotspots?region=&crop=&from=&to=` |
| Model accuracy, confirmed vs corrected | `GET /officials/accuracy?from=&to=` |
| Queue health | `GET /officials/queue` |

## Contract rules this portal must not break

From `docs/API_CONTRACT.md` §15 and §17:

- **Only confirmed cases render on an official's map.** Model output alone never
  appears. The endpoint already filters; do not add a client-side view that
  reintroduces unconfirmed points.
- **Case bundles contain no placeholder strings on live cases.** If a field comes
  back empty on a real case, that is a backend bug worth reporting, not something
  to paper over with "Unregistered Farmer" or an em-dash. `docs/DESIGN.md` §13
  notes this has regressed before.
- Role guards are enforced server-side; the portal reflects them rather than
  relying on hiding a route.
