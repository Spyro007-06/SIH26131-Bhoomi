# seed/

Demo and development seed data.

- **Phase 1** — three Nashik farms with real coordinates.
- **Phase 2** — the `registered_use` rows: 20 covering common paddy products,
  sourced from CIB&RC and the Maharashtra package of practices. `docs/DESIGN.md`
  §14 flags this as a hard blocker for F8 with no owner in the work split;
  assign it at hour 0 or it gets discovered missing at hour 20.
- **Phase 5** — the end-to-end demo scenario.

Seed scripts are idempotent: running one twice must not duplicate rows.
