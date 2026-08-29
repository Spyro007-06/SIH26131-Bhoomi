"""core/ routers — one module per resource group.

OWNER: Shreekumar owns this package; individual modules carry their own owner in
their docstring. Routers are registered on the /api/v1 router in app/main.py.

Nothing is mounted yet. Each module is structure only until its owner builds it.

    auth.py        Shreekumar                    docs/API_CONTRACT.md §2
    assets.py      Shreekumar                    §3
    farms.py       Shreekumar                    §5
    diagnose.py    Thaariha + Suchit             §6
    clarify.py     Thaariha                      §7
    advisory.py    Thaariha                      §8
    labelcheck.py  Suchit + Shreekumar + Thaariha §9
    alerts.py      Shreekumar                    §10
    problems.py    Shreekumar                    §11
    followups.py   Shreekumar                    §11
    cases.py       Thaariha                      §12, §13
    referrals.py   Tharun                        §14
    officials.py   Santheesh + Shreekumar        §15
"""
