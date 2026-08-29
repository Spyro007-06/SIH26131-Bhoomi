"""core/ — schema, CRUD, risk engine, alerts, spread, follow-up, confirmation.

OWNER: Shreekumar. Spec: docs/DESIGN.md §3, §5, §10, §11.

Exposes the ORM models, `issue_alerts()` and `propagate(confirmation)`.

core/ is the only package that touches the database. It reads rows and hands
typed objects to `intelligence/`, which never queries directly (docs/DESIGN.md §3).
"""
