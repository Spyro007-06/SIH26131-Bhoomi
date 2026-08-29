"""core/ routers — one module per resource group.

OWNER: Shreekumar. Registered on the /api/v1 router in app/main.py.

Planned, per docs/API_CONTRACT.md §16:
    auth.py      Phase 1  /auth/otp/request, /auth/otp/verify, /auth/login
    assets.py    Phase 1  /assets/presign
    farms.py     Phase 1  /farms, /farms/{id}, /farms/{id}/summary
    problems.py  Phase 2  /farms/{id}/timeline, /problems, /problems/{id}
    alerts.py    Phase 3  /farms/{id}/alerts, /alerts/{id}/respond
    followups.py Phase 3  /farms/{id}/followups/pending, /followups/{id}/respond
    officials.py Phase 4  /officials/hotspots, /officials/accuracy, /officials/queue
"""
