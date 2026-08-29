"""core/ services — business logic behind the routers.

OWNER: Shreekumar.

Planned, per docs/DESIGN.md §10 and §11:
    risk.py          Phase 3  Open-Meteo pull, favourability scoring, issue_alerts()
    spread.py        Phase 4  PostGIS radius fan-out, propagate(confirmation)
    confirmation.py  Phase 4  hotspot counters, the capped prior, accuracy aggregates
    lookup.py        Phase 2  registered_use lookup for F8
"""
