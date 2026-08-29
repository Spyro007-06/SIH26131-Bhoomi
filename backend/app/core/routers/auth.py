"""Foundation for F1 — identity before a farm can persist.

OWNER: Shreekumar

Serves:
    POST /auth/otp/request
    POST /auth/otp/verify
    POST /auth/login

Specified by: docs/API_CONTRACT.md §2. Bearer JWT and the role claim are §0.

Structure only. No routes are defined yet and nothing is mounted in
app/main.py — an empty router module has nothing to mount.
"""
