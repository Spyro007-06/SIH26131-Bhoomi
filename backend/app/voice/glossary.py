"""Domain glossary — glossary-pin domain terms to the target_label vocabulary.

OWNER: Shruthi. Spec: docs/DESIGN.md §8.

Scoped to paddy's five `TargetLabel` values (contracts/enums.py; 26 exist
total as of v3, crop-namespaced — this glossary only covers paddy's).
Kept small and reviewable on purpose — docs/DESIGN.md §8's own example is
one entry: करपा -> blast.

S0 caveat, load-bearing: `StubTranslator` (providers.py) is an identity
passthrough — it performs no real translation yet. Until S3 wires live
Mayura, THIS glossary is the only thing that ever turns a Devanagari domain
term into its English target_label — that is why "करपा" is a glossary key
and not something left for the translator to handle. Broader Marathi/Hindi
disease-name coverage is a follow-up for domain-expert review, not something
guessed at here.
"""

from __future__ import annotations

import re

from app.contracts.enums import TargetLabel

GLOSSARY: dict[str, TargetLabel] = {
    "करपा": TargetLabel.PADDY_BLAST,
    "blast": TargetLabel.PADDY_BLAST,
    "brown spot": TargetLabel.PADDY_BROWN_SPOT,
    "brown_spot": TargetLabel.PADDY_BROWN_SPOT,
    "bacterial leaf blight": TargetLabel.PADDY_BACTERIAL_LEAF_BLIGHT,
    "bacterial_leaf_blight": TargetLabel.PADDY_BACTERIAL_LEAF_BLIGHT,
    "yellow stem borer": TargetLabel.PADDY_YELLOW_STEM_BORER,
    "yellow_stem_borer": TargetLabel.PADDY_YELLOW_STEM_BORER,
    "brown planthopper": TargetLabel.PADDY_BROWN_PLANTHOPPER,
    "brown_planthopper": TargetLabel.PADDY_BROWN_PLANTHOPPER,
}

# Longest term first so a phrase (e.g. "brown spot") is matched whole rather
# than colliding with a shorter overlapping entry.
#
# Boundaries are whitespace-adjacency, i.e. (?<!\S)/(?!\S), not \b. Python's
# \w does not include Devanagari combining vowel signs (matras) — category Mc,
# e.g. U+093E in "करपा" — so \bकरपा\b silently fails to match on almost any
# real Marathi word, one of which has a matra. Whitespace-adjacency is
# script-agnostic and does not depend on Unicode word-char categorisation.
_PATTERNS: tuple[tuple[re.Pattern[str], str], ...] = tuple(
    (re.compile(rf"(?<!\S){re.escape(term)}(?!\S)", re.IGNORECASE), label.value)
    for term, label in sorted(GLOSSARY.items(), key=lambda item: -len(item[0]))
)


def pin(text: str) -> str:
    """Replace known domain terms in `text` with their canonical target_label."""
    for pattern, label_value in _PATTERNS:
        text = pattern.sub(label_value, text)
    return text
