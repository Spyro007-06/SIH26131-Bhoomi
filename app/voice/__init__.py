"""voice/ — ASR, TTS and translate-before-embed.

OWNER: Shruthi. Spec: docs/DESIGN.md §3, §8, docs/API_CONTRACT.md §4.

Exposes `transcribe()`, `synthesize()` and `to_embedding_text()`.
"""

from app.voice.asr import transcribe
from app.voice.embedding_text import to_embedding_text
from app.voice.tts import synthesize

__all__ = ["synthesize", "to_embedding_text", "transcribe"]
