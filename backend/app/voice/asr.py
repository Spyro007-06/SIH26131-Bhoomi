"""Speech to text, Marathi and Hindi. Regional language is a PS clause.

OWNER: Shruthi. Spec: docs/API_CONTRACT.md §4, docs/DESIGN.md §12.

Below `config.ASR_FLOOR`, `parsed_intent` is omitted and the client re-prompts.
`needs_confirmation` is true for anything consequential. Guessing an intent from
a low-confidence transcript is the voice-shaped version of fabrication.

Flag: ASR_PROVIDER = live | stub. This flag governs the whole voice pipeline
(ASR, TTS, translate-before-embed), not ASR alone: stub means no Sarvam call on
any of the three, live means all three hit Sarvam.

Live provider: Sarvam Saaras (config.SARVAM_STT_MODEL), transcribe mode — audio
in, native-script text out. The native transcript is the single source: it is
read back for confirmation AND fed to to_embedding_text() (docs/DESIGN.md §8).
The stub returns a fixed low-confidence transcript so the ASR_FLOOR re-prompt
path is exercised without a key or network.
"""

from __future__ import annotations

from typing import Any


def transcribe(asset_id: str, lang: str, context: str) -> Any:
    """Transcribe an uploaded audio asset.

    Args:
        asset_id: the object the client PUT via /assets/presign.
        lang: BCP-47 tag, e.g. "mr-IN".
        context: "onboarding" | "doubt_doctor" | "query".

    Return shape is docs/API_CONTRACT.md §4: text, confidence, lang,
    parsed_intent, needs_confirmation.

    Raises:
        NotImplementedError: owner Shruthi, docs/DESIGN.md §3.
    """
    raise NotImplementedError(
        "ASR not implemented — owner: Shruthi, docs/API_CONTRACT.md §4."
    )
