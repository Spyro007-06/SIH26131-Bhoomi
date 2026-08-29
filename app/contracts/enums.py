"""Wire enums — transcribed verbatim from docs/API_CONTRACT.md §1.

FROZEN at hour 2. The string values are the wire format; four workstreams and
two clients depend on them. Changing a value is a team decision, not a commit.

Every member is a `str, Enum` so it serialises to the bare string in JSON.
"""

from __future__ import annotations

from enum import Enum


class StrEnum(str, Enum):
    """String enum that renders as its value everywhere, including f-strings."""

    def __str__(self) -> str:  # pragma: no cover - trivial
        return self.value


class Role(StrEnum):
    FARMER = "farmer"
    AGRONOMIST = "agronomist"
    OFFICIAL = "official"


class Crop(StrEnum):
    """Bounded to paddy in v2. docs/API_CONTRACT.md §1."""

    PADDY = "paddy"


class ProblemType(StrEnum):
    DISEASE = "disease"
    PEST = "pest"


class TargetLabel(StrEnum):
    """The bounded label set. Anything outside it is out_of_scope, not a guess."""

    BLAST = "blast"
    BROWN_SPOT = "brown_spot"
    BACTERIAL_LEAF_BLIGHT = "bacterial_leaf_blight"
    YELLOW_STEM_BORER = "yellow_stem_borer"
    BROWN_PLANTHOPPER = "brown_planthopper"


class GrowthStage(StrEnum):
    NURSERY = "nursery"
    TILLERING = "tillering"
    VEGETATIVE = "vegetative"
    BOOTING = "booting"
    FLOWERING = "flowering"
    MATURITY = "maturity"


class ProblemSeverity(StrEnum):
    EARLY = "early"
    MODERATE = "moderate"
    SEVERE = "severe"


class ProblemStatus(StrEnum):
    OPEN = "open"
    RESOLVED = "resolved"


class GateOutcome(StrEnum):
    ADVISE = "advise"
    CLARIFY = "clarify"
    ESCALATE = "escalate"


class GateReasonCode(StrEnum):
    ABOVE_GATE = "ABOVE_GATE"
    AMBIGUOUS = "AMBIGUOUS"
    BELOW_FLOOR = "BELOW_FLOOR"
    OUT_OF_SCOPE = "OUT_OF_SCOPE"
    NO_RELEVANT_SOURCE = "NO_RELEVANT_SOURCE"


class CueAnswer(StrEnum):
    YES = "yes"
    NO = "no"
    UNKNOWN = "unknown"


class LadderTier(StrEnum):
    """Ordered. `chemical` is always last in an advisory ladder."""

    CULTURAL = "cultural"
    BIOLOGICAL = "biological"
    CHEMICAL = "chemical"


class VerdictCode(StrEnum):
    NO_OBJECTION_FOUND = "NO_OBJECTION_FOUND"
    NOT_REGISTERED_FOR_TARGET = "NOT_REGISTERED_FOR_TARGET"
    WRONG_CROP = "WRONG_CROP"
    WRONG_CLASS = "WRONG_CLASS"
    PHI_CONFLICT = "PHI_CONFLICT"
    NOT_IN_RECORDS = "NOT_IN_RECORDS"


class AlertTrigger(StrEnum):
    WEATHER = "weather"
    SEASONAL = "seasonal"
    SPREAD = "spread"
    COMBINED = "combined"


class AlertOutcome(StrEnum):
    NOTHING_FOUND = "nothing_found"
    FOUND = "found"
    SNOOZED = "snoozed"


class FollowupResponse(StrEnum):
    IMPROVED = "improved"
    NO_CHANGE = "no_change"
    GOT_WORSE = "got_worse"


class CaseStatus(StrEnum):
    OPEN = "open"
    ASSIGNED = "assigned"
    RESOLVED = "resolved"


class ConfirmationVerdict(StrEnum):
    CONFIRMED = "confirmed"
    CORRECTED = "corrected"


class AssetKind(StrEnum):
    IMAGE = "image"
    AUDIO = "audio"


class Lang(StrEnum):
    """BCP-47 tags carried on requests where text is returned. §0."""

    MARATHI = "mr-IN"
    HINDI = "hi-IN"
    TAMIL = "ta-IN"
    ENGLISH = "en-IN"


# Ordering used when rendering / validating an advisory ladder. Index position
# is meaningful: chemical must sort last. docs/API_CONTRACT.md §8.
LADDER_TIER_ORDER: tuple[LadderTier, ...] = (
    LadderTier.CULTURAL,
    LadderTier.BIOLOGICAL,
    LadderTier.CHEMICAL,
)
