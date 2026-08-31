"""to_embedding_text(): the Devanagari trap fix. docs/DESIGN.md §8, §13.

These tests exercise the S0 pipeline (stub translator + glossary pinning).
The full pgvector cross-language retrieval invariant — "a Marathi query and
its English equivalent retrieve overlapping documents" — belongs with
intelligence/rag.py once real embedding is wired; the assertion here is a
necessary-condition proxy: it confirms the two inputs share a token that a
downstream embedder would key its match on, not the retrieval itself.
"""

from __future__ import annotations

import pytest

from app.voice.embedding_text import to_embedding_text

MARATHI_TEXT = "माझ्या भातावर करपा रोग आहे"
ENGLISH_EQUIVALENT = "my paddy has blast disease"


def test_marathi_and_english_equivalent_overlap_on_the_glossary_term() -> None:
    marathi_result = to_embedding_text(MARATHI_TEXT, "mr-IN")
    english_result = to_embedding_text(ENGLISH_EQUIVALENT, "en-IN")
    assert "blast" in marathi_result.split()
    assert "blast" in english_result.split()


def test_non_glossary_devanagari_token_is_never_mangled() -> None:
    result = to_embedding_text(MARATHI_TEXT, "mr-IN")
    assert "रोग" in result.split()


def test_english_input_is_normalised() -> None:
    result = to_embedding_text("Blast Disease", "en-IN")
    assert result == "blast disease"


@pytest.mark.parametrize("degenerate_input", ["", "   ", "\n\t"])
def test_degenerate_input_raises_rather_than_returning_empty(degenerate_input: str) -> None:
    with pytest.raises(ValueError, match="degenerate"):
        to_embedding_text(degenerate_input, "en-IN")
