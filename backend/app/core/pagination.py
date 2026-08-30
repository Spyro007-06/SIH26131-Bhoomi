"""Opaque cursor pagination. docs/API_CONTRACT.md §0.

OWNER: Shreekumar.

    ?limit=20&cursor=<opaque>  ->  { ..., "next_cursor": "<opaque>" | null }

The cursor is base64 of "<iso8601>|<uuid>" — a keyset, not an offset. Offset
pagination re-reads rows that shifted while the client was paging, so a farmer
scrolling their timeline while an alert fires would see an entry twice or miss
one. The tiebreaker id makes the sort total, since two rows can share a
timestamp.

It is base64 so it reads as opaque and clients do not start constructing them by
hand — not as a security measure. Nothing secret is in it.
"""

from __future__ import annotations

import base64
import binascii
import uuid
from datetime import datetime

from app.errors import ValidationFailed

DEFAULT_LIMIT = 20
MAX_LIMIT = 100


def encode_cursor(at: datetime, row_id: uuid.UUID) -> str:
    raw = f"{at.isoformat()}|{row_id}"
    return base64.urlsafe_b64encode(raw.encode("utf-8")).decode("ascii")


def decode_cursor(cursor: str | None) -> tuple[datetime, uuid.UUID] | None:
    """Return the keyset, or None when there is no cursor.

    A malformed cursor is VALIDATION_FAILED, not a silent restart from page one.
    Silently ignoring it would make a client's paging bug look like duplicated
    data rather than an error it can fix.
    """
    if not cursor:
        return None
    try:
        raw = base64.urlsafe_b64decode(cursor.encode("ascii")).decode("utf-8")
        at_part, id_part = raw.split("|", 1)
        return datetime.fromisoformat(at_part), uuid.UUID(id_part)
    except (ValueError, binascii.Error, UnicodeDecodeError) as exc:
        raise ValidationFailed(
            "That page cursor is not valid. Start from the first page.",
            details={"cursor": cursor},
        ) from exc


def clamp_limit(limit: int | None) -> int:
    if limit is None:
        return DEFAULT_LIMIT
    if limit < 1:
        raise ValidationFailed("limit must be at least 1.", details={"limit": limit})
    return min(limit, MAX_LIMIT)
