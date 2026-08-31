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
    """Four crops as of v3. docs/API_CONTRACT.md §1."""

    PADDY = "paddy"
    COTTON = "cotton"
    SOYBEAN = "soybean"
    JOWAR = "jowar"


class ProblemType(StrEnum):
    DISEASE = "disease"
    PEST = "pest"


class TargetTier(StrEnum):
    """Whether a target can be identified from a photograph.

    diagnosable  in the vision label set: photo in, prediction out, gated,
                 advisory composed on the advise branch.
    inspection   never image-classified. It gets weather and phenology risk
                 alerts with inspection tasks, and a corpus entry so an advisory
                 exists if a human confirms it.

    The distinction is a property of the target, not of the model's current
    accuracy. An `inspection` target is one a photograph cannot settle — a stem
    borer larva is inside the stem, a shoot fly's damage looks like drought — so
    routing it through the gate would produce a confident answer about something
    the image never contained.
    """

    DIAGNOSABLE = "diagnosable"
    INSPECTION = "inspection"


class TargetLabel(StrEnum):
    """The bounded label set. Anything outside it is out_of_scope, not a guess.

    NAMESPACED BY CROP, and that prefix is load-bearing. Bacterial blight exists
    in both cotton and soybean; anthracnose in both soybean and jowar. Unprefixed
    values would make a wrong-crop match something the system has to *filter*
    out. Prefixed, it is not expressible: there is no value a cotton farm and a
    soybean farm can both hold.

    Thaariha's corpus already uses this convention, so retrieval and the label
    set agree without a translation step.
    """

    # --- paddy -------------------------------------------------------------
    PADDY_BLAST = "paddy_blast"
    PADDY_BROWN_SPOT = "paddy_brown_spot"
    PADDY_BACTERIAL_LEAF_BLIGHT = "paddy_bacterial_leaf_blight"
    PADDY_YELLOW_STEM_BORER = "paddy_yellow_stem_borer"
    PADDY_BROWN_PLANTHOPPER = "paddy_brown_planthopper"

    # --- cotton ------------------------------------------------------------
    COTTON_AMERICAN_BOLLWORM = "cotton_american_bollworm"
    COTTON_PINK_BOLLWORM = "cotton_pink_bollworm"
    COTTON_WHITEFLY = "cotton_whitefly"
    COTTON_THRIPS = "cotton_thrips"
    COTTON_BACTERIAL_BLIGHT = "cotton_bacterial_blight"
    COTTON_LEAF_CURL_VIRUS = "cotton_leaf_curl_virus"
    COTTON_FUSARIUM_WILT = "cotton_fusarium_wilt"

    # --- soybean -----------------------------------------------------------
    SOYBEAN_STEM_FLY = "soybean_stem_fly"
    SOYBEAN_GIRDLE_BEETLE = "soybean_girdle_beetle"
    SOYBEAN_DEFOLIATING_CATERPILLARS = "soybean_defoliating_caterpillars"
    SOYBEAN_YELLOW_MOSAIC_VIRUS = "soybean_yellow_mosaic_virus"
    SOYBEAN_ANTHRACNOSE = "soybean_anthracnose"
    SOYBEAN_ALTERNARIA_LEAF_SPOT = "soybean_alternaria_leaf_spot"
    SOYBEAN_BACTERIAL_BLIGHT = "soybean_bacterial_blight"

    # --- jowar -------------------------------------------------------------
    JOWAR_SHOOT_FLY = "jowar_shoot_fly"
    JOWAR_STEM_BORER = "jowar_stem_borer"
    JOWAR_SHOOT_BUG = "jowar_shoot_bug"
    JOWAR_ANTHRACNOSE = "jowar_anthracnose"
    JOWAR_GRAIN_MOLD = "jowar_grain_mold"
    JOWAR_SMUT = "jowar_smut"
    JOWAR_DOWNY_MILDEW = "jowar_downy_mildew"

    @property
    def crop(self) -> "Crop":
        """The crop this target belongs to, read off the namespace prefix.

        Derived rather than stored: the prefix IS the crop, and a second source
        of that fact could disagree with the first.
        """
        return Crop(self.value.split("_", 1)[0])


# Growth stages are NO LONGER an enum. docs/DESIGN.md §5 (v3).
#
# The v2 enum was paddy-specific — nursery, tillering, booting — and cotton has
# squaring and boll formation, jowar and soybean have their own. The phenology
# branch could not express "pink bollworm at boll formation" because that stage
# did not exist as a value.
#
# They are now rows in `growth_stage`, keyed (crop, stage_key), so the set is
# per-crop and extensible without a migration. `Farm.growth_stage` holds a
# stage_key and is constrained by a COMPOSITE foreign key on (crop,
# growth_stage) — a farm cannot hold a stage belonging to another crop, and that
# is enforced by the database rather than by a validator.
GrowthStageKey = str


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



# ---------------------------------------------------------------------------
# The tier split. Approved by Shreekumar, Phase V1.
#
# The rule that produced it: can a photograph of the plant settle what this is?
#
#   diagnosable  the symptom is ON the surface the camera sees - lesions,
#                mosaics, spots, wilts, mould on a panicle.
#   inspection   the organism or its damage is not photographable in a way a
#                classifier can separate. A stem borer larva is inside the stem;
#                shoot fly damage looks like drought; whitefly is a 1 mm insect
#                on the leaf underside. Routing these through the gate would
#                produce a confident answer about something the image never
#                contained.
#
# This is a starting split, not a measurement. When Suchit has per-class recall,
# a `diagnosable` target the classifier cannot actually separate should move to
# `inspection` — that direction is always safe. Moving one the other way is not.
# ---------------------------------------------------------------------------

TARGET_TIERS: dict[TargetLabel, TargetTier] = {
    # paddy
    TargetLabel.PADDY_BLAST: TargetTier.DIAGNOSABLE,
    TargetLabel.PADDY_BROWN_SPOT: TargetTier.DIAGNOSABLE,
    TargetLabel.PADDY_BACTERIAL_LEAF_BLIGHT: TargetTier.DIAGNOSABLE,
    TargetLabel.PADDY_YELLOW_STEM_BORER: TargetTier.INSPECTION,
    TargetLabel.PADDY_BROWN_PLANTHOPPER: TargetTier.INSPECTION,
    # cotton
    TargetLabel.COTTON_AMERICAN_BOLLWORM: TargetTier.INSPECTION,
    TargetLabel.COTTON_PINK_BOLLWORM: TargetTier.INSPECTION,
    TargetLabel.COTTON_WHITEFLY: TargetTier.INSPECTION,
    TargetLabel.COTTON_THRIPS: TargetTier.INSPECTION,
    TargetLabel.COTTON_BACTERIAL_BLIGHT: TargetTier.DIAGNOSABLE,
    TargetLabel.COTTON_LEAF_CURL_VIRUS: TargetTier.DIAGNOSABLE,
    TargetLabel.COTTON_FUSARIUM_WILT: TargetTier.DIAGNOSABLE,
    # soybean
    TargetLabel.SOYBEAN_STEM_FLY: TargetTier.INSPECTION,
    TargetLabel.SOYBEAN_GIRDLE_BEETLE: TargetTier.INSPECTION,
    TargetLabel.SOYBEAN_DEFOLIATING_CATERPILLARS: TargetTier.INSPECTION,
    TargetLabel.SOYBEAN_YELLOW_MOSAIC_VIRUS: TargetTier.DIAGNOSABLE,
    TargetLabel.SOYBEAN_ANTHRACNOSE: TargetTier.DIAGNOSABLE,
    TargetLabel.SOYBEAN_ALTERNARIA_LEAF_SPOT: TargetTier.DIAGNOSABLE,
    TargetLabel.SOYBEAN_BACTERIAL_BLIGHT: TargetTier.DIAGNOSABLE,
    # jowar
    TargetLabel.JOWAR_SHOOT_FLY: TargetTier.INSPECTION,
    TargetLabel.JOWAR_STEM_BORER: TargetTier.INSPECTION,
    TargetLabel.JOWAR_SHOOT_BUG: TargetTier.INSPECTION,
    TargetLabel.JOWAR_ANTHRACNOSE: TargetTier.DIAGNOSABLE,
    TargetLabel.JOWAR_GRAIN_MOLD: TargetTier.DIAGNOSABLE,
    TargetLabel.JOWAR_SMUT: TargetTier.DIAGNOSABLE,
    TargetLabel.JOWAR_DOWNY_MILDEW: TargetTier.DIAGNOSABLE,
}

DIAGNOSABLE_TARGETS: tuple[TargetLabel, ...] = tuple(
    t for t, tier in TARGET_TIERS.items() if tier is TargetTier.DIAGNOSABLE
)
"""The vision label set. Suchit trains against exactly this."""

INSPECTION_TARGETS: tuple[TargetLabel, ...] = tuple(
    t for t, tier in TARGET_TIERS.items() if tier is TargetTier.INSPECTION
)
"""Alert-and-inspect only. Never reaches the gate."""


# Ordering used when rendering / validating an advisory ladder. Index position
# is meaningful: chemical must sort last. docs/API_CONTRACT.md §8.
LADDER_TIER_ORDER: tuple[LadderTier, ...] = (
    LadderTier.CULTURAL,
    LadderTier.BIOLOGICAL,
    LadderTier.CHEMICAL,
)
