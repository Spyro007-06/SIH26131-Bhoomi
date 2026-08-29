"""F14 — the capped confirmation prior.

OWNER: Shreekumar

prior[region][crop][stage][label] as a count-based nudge, applied as a small
additive bias to the vision output before the gate.

The cap is the point. PRIOR_MAX_BIAS is asserted at import time in app/config.py
to be below MARGIN and below (GATE - FLOOR), so the prior can never move a
prediction across a gate band on its own. This is 'learns from field
confirmations' — not fine-tuning, not reinforcement learning.

Specified by: docs/DESIGN.md §11.

Structure only. No implementation yet.
"""
