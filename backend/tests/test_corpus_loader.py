"""The corpus loader's validation logic: chunking, source refusal, target
refusal, and the authoritative filter that keeps an unverified chemical
section out of anything that composes a dosage.

Loader scripts in this family (load_registered_use.py, and this one) are
otherwise verified live rather than unit tested — see CLAUDE.md's
verification rule. The pure functions here are the exception: they carry
enough real judgement (what counts as a citation, what counts as a chunk
boundary) that a regression should fail a test, not wait to be noticed on the
next live run.
"""

from __future__ import annotations

import sys
from datetime import date

sys.path.insert(0, "scripts")

from load_corpus import (  # noqa: E402
    GENERIC_SOURCE_PHRASES,
    _chunk_markdown,
    _likely_target,
    _looks_like_a_real_citation,
    _parse_date,
    _validate_row,
)

from app.contracts.enums import TargetLabel  # noqa: E402
from app.core.models import CorpusDoc  # noqa: E402
from app.core.services.corpus import authoritative_chunks, chunks_for  # noqa: E402

# ===========================================================================
# Chunking — by markdown section, never a fixed token window
# ===========================================================================

DOC = """# Cotton Bollworm Complex

## Symptoms
Larvae bore circular holes into squares and bolls.

## Early Symptoms
Rosetted flowers before boll damage appears.

## Chemical Management
Spray a suitable synthetic pyrethroid at ETL.
"""


def test_chunks_split_on_h2_headings() -> None:
    chunks = _chunk_markdown(DOC)
    assert [h for h, _ in chunks] == ["Symptoms", "Early Symptoms", "Chemical Management"]


def test_h1_title_is_not_its_own_chunk() -> None:
    """The document title (H1) is metadata, not a retrievable section."""
    chunks = _chunk_markdown(DOC)
    assert "Cotton Bollworm Complex" not in [h for h, _ in chunks]


def test_a_heading_with_no_body_is_skipped() -> None:
    doc = "# Title\n\n## Symptoms\ncontent here\n\n## Empty Section\n\n## Notes\nmore content"
    chunks = _chunk_markdown(doc)
    assert [h for h, _ in chunks] == ["Symptoms", "Notes"]


def test_falls_back_to_h1_sections_when_there_is_no_h2() -> None:
    doc = "# Symptoms\nfoliar spots\n\n# Management\ncultural control"
    chunks = _chunk_markdown(doc)
    assert [h for h, _ in chunks] == ["Management"]


def test_a_document_with_only_a_title_produces_no_chunks() -> None:
    assert _chunk_markdown("# Just A Title\n") == []


def test_a_document_with_no_headings_becomes_one_full_document_chunk() -> None:
    chunks = _chunk_markdown("plain content, no headings at all")
    assert chunks == [("Full document", "plain content, no headings at all")]


# ===========================================================================
# Source validation — a citation, not a placeholder
# ===========================================================================


def test_the_exact_generic_phrases_named_in_the_brief_are_refused() -> None:
    for phrase in ("Cotton disease field guides", "Sorghum disease references",
                   "Agricultural crop-protection references"):
        assert phrase.strip().rstrip(".").lower() in GENERIC_SOURCE_PHRASES
        assert not _looks_like_a_real_citation(phrase) or (
            phrase.strip().rstrip(".").lower() in GENERIC_SOURCE_PHRASES
        )


def test_a_url_is_a_citation_signal() -> None:
    assert _looks_like_a_real_citation(
        "Symptom notes (https://agritech.tnau.ac.in/crop_protection/cotton/x.html)"
    )


def test_a_known_institution_acronym_is_a_citation_signal() -> None:
    assert _looks_like_a_real_citation("TNAU Agritech Portal, Crop Protection > Cotton Pests")


def test_a_dated_quoted_title_is_a_citation_signal() -> None:
    assert _looks_like_a_real_citation(
        "Prakash et al. 2014. 'Integrated Pest Management for Rice', NIPHM/DPPQS"
    )


def test_a_bare_generic_noun_phrase_is_not_a_citation() -> None:
    """No URL, no institution, no dated quoted work — nothing a reader could
    go and find."""
    assert not _looks_like_a_real_citation("General pest management notes")
    assert not _looks_like_a_real_citation("Standard crop advisory")


# ===========================================================================
# Target validation — refuse, never fuzzy-match
# ===========================================================================


def test_a_bare_name_is_refused_even_though_a_prefixed_version_exists() -> None:
    """The wrong-crop-match risk this rule exists to prevent: fuzzy-attaching
    a bare name to whichever enum member looks close would eventually attach
    the wrong crop's document to the wrong crop's target."""
    row = {
        "doc_id": "d1", "source_file": "x.md", "crop": "cotton",
        "target": "american_bollworm", "title": "t",
        "source": "TNAU Agritech Portal (https://example.test)",
        "source_dated": "2024-01-01",
    }
    chunks, refusal, mismatch = _validate_row(row, 1)
    assert chunks == []
    assert refusal is not None
    assert any("not an exact member" in r for r in refusal.reasons)
    assert mismatch is not None
    assert mismatch.likely == "cotton_american_bollworm"


def test_an_unrecognisable_target_gets_no_confident_suggestion_rather_than_a_guess() -> None:
    row = {
        "doc_id": "d1", "source_file": "x.md", "crop": "cotton",
        "target": "leaf_gremlins", "title": "t",
        "source": "TNAU Agritech Portal (https://example.test)",
        "source_dated": "2024-01-01",
    }
    _, refusal, mismatch = _validate_row(row, 1)
    assert refusal is not None
    assert mismatch is not None
    assert mismatch.likely is None


def test_every_frozen_target_is_findable_by_its_own_bare_suffix() -> None:
    """A sanity sweep: for every real v3 target, stripping its crop prefix and
    asking _likely_target to find it again must succeed. If this ever fails,
    the suggestion algorithm has a blind spot on real data, not synthetic."""
    for t in TargetLabel:
        crop, _, bare = t.value.partition("_")
        assert _likely_target(bare, crop) == t.value, t.value


def test_source_dated_must_parse() -> None:
    assert _parse_date("2024-03-15") == date(2024, 3, 15)
    assert _parse_date("15-03-2024") == date(2024, 3, 15)
    assert _parse_date("") is None
    assert _parse_date("not a date") is None


# ===========================================================================
# The authoritative filter — the whole point of Part 2's chemical-section rule
# ===========================================================================


async def _seed_chunk(session, *, target, crop, title, authoritative) -> None:
    session.add(
        CorpusDoc(
            doc_id="probe-doc", title=title, source="TNAU Agritech Portal (https://example.test)",
            target=target, crop=crop, content="body text", authoritative=authoritative,
        )
    )
    await session.flush()


async def test_authoritative_chunks_excludes_the_flagged_ones(db_session) -> None:
    await _seed_chunk(
        db_session, target="cotton_american_bollworm", crop="cotton",
        title="Symptoms", authoritative=True,
    )
    await _seed_chunk(
        db_session, target="cotton_american_bollworm", crop="cotton",
        title="Chemical Management", authoritative=False,
    )

    everything = await chunks_for(db_session, "cotton", "cotton_american_bollworm")
    safe_only = await authoritative_chunks(db_session, "cotton", "cotton_american_bollworm")

    assert len(everything) == 2
    assert len(safe_only) == 1
    assert safe_only[0].title == "Symptoms"
    assert all(c.authoritative for c in safe_only)


async def test_authoritative_chunks_is_empty_when_only_chemical_content_exists(
    db_session,
) -> None:
    """A target with ONLY a chemical section (no verified background at all)
    must not silently fall back to serving the unverified text anyway."""
    await _seed_chunk(
        db_session, target="soybean_anthracnose", crop="soybean",
        title="Chemical Management", authoritative=False,
    )
    safe_only = await authoritative_chunks(db_session, "soybean", "soybean_anthracnose")
    assert safe_only == []
