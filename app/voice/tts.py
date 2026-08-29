"""Text to speech for `spoken_summary` playback.

OWNER: Shruthi. Spec: docs/API_CONTRACT.md §4.
"""

from __future__ import annotations

from typing import Any


def synthesize(text: str, lang: str) -> Any:
    """Render text to an audio object and return a presigned URL.

    Return shape is docs/API_CONTRACT.md §4: audio_url, expires_in.

    Raises:
        NotImplementedError: owner Shruthi, docs/DESIGN.md §3.
    """
    raise NotImplementedError(
        "TTS not implemented — owner: Shruthi, docs/API_CONTRACT.md §4."
    )
