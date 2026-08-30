"""ORM models — docs/DESIGN.md §5 plus docs/DATA_MODEL_ADDENDUM.md.

OWNER: Shreekumar.

Eighteen tables:

  Thirteen from docs/DESIGN.md §5, transcribed with the exact column names in
  that section: farm, problem, diagnosis, observation, advisory, label_check,
  registered_use, follow_up, alert, case, confirmation, corpus_doc,
  distinguishing_cue.

  Four from the addendum's Part A, required by docs/API_CONTRACT.md and absent
  from the frozen §5: app_user, otp_request, asset, label_prior.

  One from Part B4: label_reference — the per-label signature and reference
  image that docs/API_CONTRACT.md §7 returns for Doubt Doctor candidates.

Three added columns, Part B1-B3, accepted by Shreekumar: alert.reason,
registered_use.pesticide_class, confirmation.treatment.

Two table names deviate from the §5 entity names because the literal names are
reserved words in Postgres:

  User -> app_user.  Unquoted `user` in psql resolves to the CURRENT_USER
                     function rather than the table, which produces errors that
                     look like nothing to do with the query you wrote.
  Case -> "case".    Kept, since SQLAlchemy quotes it automatically, but any
                     hand-written SQL must quote it too.

The constraints that carry product guarantees are declared here and emitted by
the migration as Postgres CHECKs. docs/DESIGN.md §5 is explicit that enforcing
them in application code means someone bypasses them at hour 25.
"""

from __future__ import annotations

import uuid
from datetime import date, datetime

from geoalchemy2 import Geography
from pgvector.sqlalchemy import Vector
from sqlalchemy import (
    ARRAY,
    BigInteger,
    Boolean,
    CheckConstraint,
    Date,
    DateTime,
    Enum,
    ForeignKey,
    Index,
    Integer,
    Numeric,
    String,
    Text,
    UniqueConstraint,
    func,
    text,
)
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.contracts.enums import (
    AlertOutcome,
    AlertTrigger,
    AssetKind,
    CaseStatus,
    ConfirmationVerdict,
    Crop,
    CueAnswer,
    FollowupResponse,
    GateOutcome,
    GateReasonCode,
    GrowthStage,
    ProblemSeverity,
    ProblemStatus,
    ProblemType,
    Role,
    TargetLabel,
    VerdictCode,
)
from app.contracts.farm import SRID
from app.db import Base

# ---------------------------------------------------------------------------
# Enum plumbing.
#
# SQLAlchemy's Enum stores the *names* of a Python enum by default, not the
# values. Every enum in app/contracts/enums.py carries the exact wire string in
# its value, and the wire string is what four workstreams serialise — so every
# column below passes values_callable. Getting this wrong would store "FARMER"
# where the contract says "farmer", silently, and only on write.
# ---------------------------------------------------------------------------


def pg_enum(python_enum, name: str) -> Enum:
    """A native Postgres enum whose labels are the contract's wire strings."""
    return Enum(
        python_enum,
        name=name,
        values_callable=lambda e: [member.value for member in e],
        native_enum=True,
        create_type=True,
    )


# `pesticide_class` is not in docs/API_CONTRACT.md §1 — it is addendum B2, added
# because docs/DESIGN.md §9's WRONG_CLASS verdict is underivable without it. It
# is deliberately NOT added to the frozen app/contracts/enums.py; it is not a
# wire enum, it is a column domain.
PESTICIDE_CLASSES = ("fungicide", "insecticide", "herbicide", "acaricide", "nematicide", "other")

TIMESTAMPTZ = DateTime(timezone=True)


def _uuid_pk() -> Mapped[uuid.UUID]:
    return mapped_column(
        primary_key=True,
        server_default=text("gen_random_uuid()"),
    )


# ===========================================================================
# Part A — identity, credentials, storage, prior
# ===========================================================================


class User(Base):
    """Addendum A1. Forced by docs/API_CONTRACT.md §2 and §0's role claim, and
    by §5's own Farm.farmer_id, Case.assigned_to and Confirmation.agronomist_id,
    none of which have a table to point at in the frozen model."""

    __tablename__ = "app_user"

    id: Mapped[uuid.UUID] = _uuid_pk()
    role: Mapped[Role] = mapped_column(pg_enum(Role, "role"), nullable=False)
    phone: Mapped[str | None] = mapped_column(String(20), unique=True)
    email: Mapped[str | None] = mapped_column(String(255), unique=True)
    password_hash: Mapped[str | None] = mapped_column(Text)
    name: Mapped[str] = mapped_column(Text, nullable=False)
    created_at: Mapped[datetime] = mapped_column(
        TIMESTAMPTZ, nullable=False, server_default=func.now()
    )

    farms: Mapped[list[Farm]] = relationship(back_populates="farmer")

    __table_args__ = (
        # A farmer row carrying a password hash is a farmer who can bypass OTP.
        # An agronomist row without one is an account that cannot authenticate.
        # Both fail silently, so the shape is a CHECK, not a validator.
        CheckConstraint(
            "(role = 'farmer' AND phone IS NOT NULL AND password_hash IS NULL)"
            " OR "
            "(role IN ('agronomist','official')"
            " AND email IS NOT NULL AND password_hash IS NOT NULL)",
            name="ck_app_user_role_credentials",
        ),
    )


class OtpRequest(Base):
    """Addendum A2. `/auth/otp/request` returns a request_id that must be
    storable, and an expires_in that forces expires_at.

    code_hash rather than code: an OTP table readable in plaintext is a
    credential store. attempts and consumed_at exist so a code can be capped and
    burned — without them the verify endpoint is a brute-force oracle."""

    __tablename__ = "otp_request"

    id: Mapped[uuid.UUID] = _uuid_pk()
    phone: Mapped[str] = mapped_column(String(20), nullable=False, index=True)
    code_hash: Mapped[str] = mapped_column(Text, nullable=False)
    expires_at: Mapped[datetime] = mapped_column(TIMESTAMPTZ, nullable=False)
    consumed_at: Mapped[datetime | None] = mapped_column(TIMESTAMPTZ)
    attempts: Mapped[int] = mapped_column(Integer, nullable=False, server_default=text("0"))
    created_at: Mapped[datetime] = mapped_column(
        TIMESTAMPTZ, nullable=False, server_default=func.now()
    )

    __table_args__ = (
        CheckConstraint("attempts >= 0", name="ck_otp_request_attempts_non_negative"),
    )


class Asset(Base):
    """Addendum A3. docs/API_CONTRACT.md §3 mints these; §5's three
    *_asset_id columns all reference a table the frozen model never defines.

    object_key is the S3/MinIO key, kept separate from id so the storage layout
    can change without rewriting foreign keys. The API never receives bytes —
    the row exists before the client PUTs to the presigned URL."""

    __tablename__ = "asset"

    id: Mapped[uuid.UUID] = _uuid_pk()
    kind: Mapped[AssetKind] = mapped_column(pg_enum(AssetKind, "asset_kind"), nullable=False)
    content_type: Mapped[str] = mapped_column(String(127), nullable=False)
    object_key: Mapped[str] = mapped_column(Text, nullable=False, unique=True)
    farm_id: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("farm.id", ondelete="SET NULL"), index=True
    )
    byte_size: Mapped[int | None] = mapped_column(BigInteger)
    uploaded_at: Mapped[datetime | None] = mapped_column(TIMESTAMPTZ)
    created_at: Mapped[datetime] = mapped_column(
        TIMESTAMPTZ, nullable=False, server_default=func.now()
    )

    __table_args__ = (
        CheckConstraint("byte_size IS NULL OR byte_size >= 0", name="ck_asset_byte_size"),
    )


class LabelPrior(Base):
    """Addendum A4. docs/DESIGN.md §11 step 3 describes
    prior[region][crop][stage][label] and never gives it a table. Those four
    dimensions are the composite primary key.

    This table stores counts only. The clamp that stops the prior moving a
    prediction across a gate band is PRIOR_MAX_BIAS in app/config.py, asserted
    at import time, and applied in core/services/prior.py. It is not a property
    of this schema."""

    __tablename__ = "label_prior"

    region: Mapped[str] = mapped_column(Text, primary_key=True)
    crop: Mapped[Crop] = mapped_column(pg_enum(Crop, "crop"), primary_key=True)
    growth_stage: Mapped[GrowthStage] = mapped_column(
        pg_enum(GrowthStage, "growth_stage"), primary_key=True
    )
    label: Mapped[TargetLabel] = mapped_column(
        pg_enum(TargetLabel, "target_label"), primary_key=True
    )
    confirmed_count: Mapped[int] = mapped_column(
        Integer, nullable=False, server_default=text("0")
    )
    corrected_count: Mapped[int] = mapped_column(
        Integer, nullable=False, server_default=text("0")
    )
    updated_at: Mapped[datetime] = mapped_column(
        TIMESTAMPTZ, nullable=False, server_default=func.now(), onupdate=func.now()
    )

    __table_args__ = (
        CheckConstraint(
            "confirmed_count >= 0 AND corrected_count >= 0",
            name="ck_label_prior_counts_non_negative",
        ),
    )


class LabelReference(Base):
    """Addendum B4. docs/API_CONTRACT.md §7 returns, per Doubt Doctor candidate,
    a `signature` and an `image_url`. DistinguishingCue holds the cue that
    separates a pair, not a per-label description, and no other table held these.

    One row per target label. Content is authored alongside the corpus, not
    generated — same rule as the cues themselves, docs/DESIGN.md §7."""

    __tablename__ = "label_reference"

    label: Mapped[TargetLabel] = mapped_column(
        pg_enum(TargetLabel, "target_label"), primary_key=True
    )
    signature: Mapped[str] = mapped_column(Text, nullable=False)
    image_asset_id: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("asset.id", ondelete="SET NULL")
    )
    created_at: Mapped[datetime] = mapped_column(
        TIMESTAMPTZ, nullable=False, server_default=func.now()
    )


# ===========================================================================
# docs/DESIGN.md §5
# ===========================================================================


class Farm(Base):
    """Contract C2. docs/DESIGN.md §4 and §5.

    location is NOT NULL and geography(Point, 4326). §4: "F6 and F15 are
    inoperable without it, and retrofitting geometry after seed data exists is
    painful." The GiST index is what makes F6's ST_DWithin fan-out a query
    rather than a table scan."""

    __tablename__ = "farm"

    id: Mapped[uuid.UUID] = _uuid_pk()
    farmer_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("app_user.id", ondelete="RESTRICT"), nullable=False, index=True
    )
    crop: Mapped[Crop] = mapped_column(pg_enum(Crop, "crop"), nullable=False)
    variety: Mapped[str | None] = mapped_column(Text)
    growth_stage: Mapped[GrowthStage] = mapped_column(
        pg_enum(GrowthStage, "growth_stage"), nullable=False
    )
    region: Mapped[str] = mapped_column(Text, nullable=False, index=True)
    sowing_date: Mapped[date | None] = mapped_column(Date)
    """Addendum Part C. Nullable: existing seed rows predate the column and a
    sowing date is not something to invent.

    days_after_sowing is deliberately NOT stored. It is derived on read — a
    stored integer is wrong the next morning and nothing in this system would
    refresh it. The F5 phenology branch (Phase 3) computes it from here."""
    location: Mapped[object] = mapped_column(
        # spatial_index=False on purpose. geoalchemy2 otherwise attaches a
        # create-index listener to any table holding this column, which fires
        # inside op.create_table and collides with the migration's own
        # op.create_index on the same name. The index is declared explicitly in
        # __table_args__ below so it is visible where every other index is.
        Geography(geometry_type="POINT", srid=SRID, spatial_index=False),
        nullable=False,
    )
    created_at: Mapped[datetime] = mapped_column(
        TIMESTAMPTZ, nullable=False, server_default=func.now()
    )

    farmer: Mapped[User] = relationship(back_populates="farms")
    problems: Mapped[list[Problem]] = relationship(back_populates="farm")

    __table_args__ = (
        # F6's ST_DWithin fan-out is a query rather than a table scan because of
        # this index. docs/DESIGN.md §10.
        Index("idx_farm_location", "location", postgresql_using="gist"),
    )


class Problem(Base):
    """docs/DESIGN.md §5."""

    __tablename__ = "problem"

    id: Mapped[uuid.UUID] = _uuid_pk()
    farm_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("farm.id", ondelete="CASCADE"), nullable=False, index=True
    )
    problem_type: Mapped[ProblemType] = mapped_column(
        pg_enum(ProblemType, "problem_type"), nullable=False
    )
    label: Mapped[TargetLabel | None] = mapped_column(pg_enum(TargetLabel, "target_label"))
    severity: Mapped[ProblemSeverity | None] = mapped_column(
        pg_enum(ProblemSeverity, "problem_severity")
    )
    status: Mapped[ProblemStatus] = mapped_column(
        pg_enum(ProblemStatus, "problem_status"),
        nullable=False,
        server_default=text("'open'"),
    )
    opened_at: Mapped[datetime] = mapped_column(
        TIMESTAMPTZ, nullable=False, server_default=func.now()
    )
    resolved_at: Mapped[datetime | None] = mapped_column(TIMESTAMPTZ)

    farm: Mapped[Farm] = relationship(back_populates="problems")

    __table_args__ = (
        CheckConstraint(
            "(status = 'resolved') = (resolved_at IS NOT NULL)",
            name="ck_problem_resolved_at_matches_status",
        ),
        Index("ix_problem_farm_status", "farm_id", "status"),
    )


class Diagnosis(Base):
    """docs/DESIGN.md §5. One row per gated diagnose call.

    is_stub travels from the classifier through here to the client, which must
    render a banner. docs/DESIGN.md §12."""

    __tablename__ = "diagnosis"

    id: Mapped[uuid.UUID] = _uuid_pk()
    problem_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("problem.id", ondelete="CASCADE"), nullable=False, index=True
    )
    image_asset_id: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("asset.id", ondelete="SET NULL")
    )
    topk: Mapped[dict] = mapped_column(JSONB, nullable=False)
    gate_outcome: Mapped[GateOutcome] = mapped_column(
        pg_enum(GateOutcome, "gate_outcome"), nullable=False
    )
    gate_confidence: Mapped[float] = mapped_column(Numeric(4, 3), nullable=False)
    reason_code: Mapped[GateReasonCode] = mapped_column(
        pg_enum(GateReasonCode, "gate_reason_code"), nullable=False
    )
    model_version: Mapped[str] = mapped_column(Text, nullable=False)
    is_stub: Mapped[bool] = mapped_column(Boolean, nullable=False)
    created_at: Mapped[datetime] = mapped_column(
        TIMESTAMPTZ, nullable=False, server_default=func.now()
    )

    __table_args__ = (
        CheckConstraint(
            "gate_confidence >= 0 AND gate_confidence <= 1",
            name="ck_diagnosis_confidence_is_a_probability",
        ),
    )


class Observation(Base):
    """docs/DESIGN.md §5. The Doubt Doctor answer lives here and travels into
    the case bundle — docs/DESIGN.md §7 calls this the reason F4 is not
    decoration."""

    __tablename__ = "observation"

    id: Mapped[uuid.UUID] = _uuid_pk()
    problem_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("problem.id", ondelete="CASCADE"), nullable=False, index=True
    )
    kind: Mapped[str] = mapped_column(
        Enum("doubt_doctor", "field_note", name="observation_kind"), nullable=False
    )
    question: Mapped[str | None] = mapped_column(Text)
    answer: Mapped[CueAnswer | None] = mapped_column(pg_enum(CueAnswer, "cue_answer"))
    cue_id: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("distinguishing_cue.id", ondelete="SET NULL")
    )
    created_at: Mapped[datetime] = mapped_column(
        TIMESTAMPTZ, nullable=False, server_default=func.now()
    )


class Advisory(Base):
    """docs/DESIGN.md §5, docs/API_CONTRACT.md §8.

    The ladder CHECK is one of the two constraints docs/DESIGN.md §5 insists
    live in the schema: "The PRD's structural claim about pesticide ordering is
    only true if the database refuses to store it otherwise." """

    __tablename__ = "advisory"

    id: Mapped[uuid.UUID] = _uuid_pk()
    problem_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("problem.id", ondelete="CASCADE"), nullable=False, index=True
    )
    possible_issue: Mapped[str] = mapped_column(Text, nullable=False)
    what_to_check: Mapped[str] = mapped_column(Text, nullable=False)
    what_to_avoid: Mapped[str] = mapped_column(Text, nullable=False)
    ladder: Mapped[list] = mapped_column(JSONB, nullable=False)
    expert_trigger: Mapped[str | None] = mapped_column(Text)
    citations: Mapped[list] = mapped_column(JSONB, nullable=False, server_default=text("'[]'"))
    created_at: Mapped[datetime] = mapped_column(
        TIMESTAMPTZ, nullable=False, server_default=func.now()
    )

    __table_args__ = (
        # Chemical last if a chemical rung is present.
        CheckConstraint(
            "NOT (ladder @> '[{\"tier\":\"chemical\"}]'::jsonb)"
            " OR (ladder -> -1 ->> 'tier' = 'chemical')",
            name="ck_advisory_ladder_chemical_last",
        ),
        CheckConstraint(
            "jsonb_typeof(ladder) = 'array'", name="ck_advisory_ladder_is_array"
        ),
    )


class LabelCheck(Base):
    """docs/DESIGN.md §5 and §9, docs/API_CONTRACT.md §9.

    verdict_code is nullable: an unreadable label returns OCR_UNREADABLE with no
    verdict at all rather than a guess."""

    __tablename__ = "label_check"

    id: Mapped[uuid.UUID] = _uuid_pk()
    problem_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("problem.id", ondelete="CASCADE"), nullable=False, index=True
    )
    image_asset_id: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("asset.id", ondelete="SET NULL")
    )
    extracted: Mapped[dict] = mapped_column(JSONB, nullable=False, server_default=text("'{}'"))
    ocr_confidence: Mapped[float | None] = mapped_column(Numeric(4, 3))
    verdict_code: Mapped[VerdictCode | None] = mapped_column(pg_enum(VerdictCode, "verdict_code"))
    matched_row_id: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("registered_use.id", ondelete="SET NULL")
    )
    created_at: Mapped[datetime] = mapped_column(
        TIMESTAMPTZ, nullable=False, server_default=func.now()
    )

    __table_args__ = (
        CheckConstraint(
            "ocr_confidence IS NULL OR (ocr_confidence >= 0 AND ocr_confidence <= 1)",
            name="ck_label_check_ocr_confidence_is_a_probability",
        ),
    )


class RegisteredUse(Base):
    """docs/DESIGN.md §5 and §9. F8's lookup table — CIB&RC and state PoP.

    pesticide_class is addendum B2: docs/DESIGN.md §9 defines a WRONG_CLASS
    verdict ("This is a fungicide. Your problem is an insect pest.") which is
    underivable without it. The seed CSV already carried the column."""

    __tablename__ = "registered_use"

    id: Mapped[uuid.UUID] = _uuid_pk()
    active_ingredient: Mapped[str] = mapped_column(Text, nullable=False, index=True)
    crop: Mapped[Crop] = mapped_column(pg_enum(Crop, "crop"), nullable=False)
    target: Mapped[TargetLabel] = mapped_column(
        pg_enum(TargetLabel, "target_label"), nullable=False
    )
    pesticide_class: Mapped[str] = mapped_column(Text, nullable=False)
    dosage_text: Mapped[str] = mapped_column(Text, nullable=False)
    phi_days: Mapped[int] = mapped_column(Integer, nullable=False)
    reentry_hours: Mapped[int] = mapped_column(Integer, nullable=False)
    source: Mapped[str] = mapped_column(Text, nullable=False)
    last_verified: Mapped[datetime | None] = mapped_column(Date)

    __table_args__ = (
        CheckConstraint(
            "pesticide_class IN "
            "('fungicide','insecticide','herbicide','acaricide','nematicide','other')",
            name="ck_registered_use_pesticide_class",
        ),
        CheckConstraint("phi_days >= 0", name="ck_registered_use_phi_days_non_negative"),
        CheckConstraint(
            "reentry_hours >= 0", name="ck_registered_use_reentry_hours_non_negative"
        ),
        UniqueConstraint(
            "active_ingredient", "crop", "target", name="uq_registered_use_ingredient_crop_target"
        ),
        Index("ix_registered_use_lookup", "active_ingredient", "crop"),
    )


class FollowUp(Base):
    """docs/DESIGN.md §5, docs/API_CONTRACT.md §11. Due FOLLOWUP_DUE_DAYS after
    an advisory — the constant lives in app/config.py."""

    __tablename__ = "follow_up"

    id: Mapped[uuid.UUID] = _uuid_pk()
    problem_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("problem.id", ondelete="CASCADE"), nullable=False, index=True
    )
    due_at: Mapped[datetime] = mapped_column(TIMESTAMPTZ, nullable=False, index=True)
    response: Mapped[FollowupResponse | None] = mapped_column(
        pg_enum(FollowupResponse, "followup_response")
    )
    image_asset_id: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("asset.id", ondelete="SET NULL")
    )
    responded_at: Mapped[datetime | None] = mapped_column(TIMESTAMPTZ)
    created_at: Mapped[datetime] = mapped_column(
        TIMESTAMPTZ, nullable=False, server_default=func.now()
    )

    __table_args__ = (
        CheckConstraint(
            "(response IS NULL) = (responded_at IS NULL)",
            name="ck_follow_up_response_and_timestamp_agree",
        ),
    )


class Alert(Base):
    """docs/DESIGN.md §5 and §10, docs/API_CONTRACT.md §10.

    inspection_tasks non-empty is the other constraint §5 insists lives in the
    schema: "An alert without a task is noise, and enforcing it in Python means
    someone will bypass it at hour 25."

    reason is addendum B1 — docs/API_CONTRACT.md §10 returns the sentence that
    tells the farmer why they are being asked to walk their field."""

    __tablename__ = "alert"

    id: Mapped[uuid.UUID] = _uuid_pk()
    farm_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("farm.id", ondelete="CASCADE"), nullable=False, index=True
    )
    trigger_type: Mapped[AlertTrigger] = mapped_column(
        pg_enum(AlertTrigger, "alert_trigger"), nullable=False
    )
    target: Mapped[TargetLabel] = mapped_column(
        pg_enum(TargetLabel, "target_label"), nullable=False
    )
    risk_level: Mapped[str] = mapped_column(
        Enum("low", "moderate", "high", name="risk_level"), nullable=False
    )
    reason: Mapped[str] = mapped_column(Text, nullable=False)
    inspection_tasks: Mapped[list] = mapped_column(JSONB, nullable=False)
    issued_at: Mapped[datetime] = mapped_column(
        TIMESTAMPTZ, nullable=False, server_default=func.now()
    )
    outcome: Mapped[AlertOutcome | None] = mapped_column(pg_enum(AlertOutcome, "alert_outcome"))

    __table_args__ = (
        CheckConstraint(
            "jsonb_array_length(inspection_tasks) > 0",
            name="ck_alert_inspection_tasks_non_empty",
        ),
        Index("ix_alert_farm_outcome", "farm_id", "outcome"),
    )


class Case(Base):
    """docs/DESIGN.md §5, docs/API_CONTRACT.md §12 and §13.

    assigned_to is a foreign key to app_user rather than the display string the
    API returns ("agronomist:kvk_nashik"); that string is rendered at the API
    layer from this row."""

    __tablename__ = "case"

    id: Mapped[uuid.UUID] = _uuid_pk()
    problem_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("problem.id", ondelete="CASCADE"), nullable=False, index=True
    )
    assigned_to: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("app_user.id", ondelete="SET NULL"), index=True
    )
    status: Mapped[CaseStatus] = mapped_column(
        pg_enum(CaseStatus, "case_status"), nullable=False, server_default=text("'open'")
    )
    queue_position: Mapped[int | None] = mapped_column(Integer)
    eta_minutes: Mapped[int | None] = mapped_column(Integer)
    bundle: Mapped[dict | None] = mapped_column(JSONB)
    created_at: Mapped[datetime] = mapped_column(
        TIMESTAMPTZ, nullable=False, server_default=func.now()
    )


class Confirmation(Base):
    """docs/DESIGN.md §5 and §11, docs/API_CONTRACT.md §13. F14 reads from here.

    treatment is addendum B3 — §13 accepts it distinctly from notes, and merging
    the two loses the instruction the farmer is meant to act on.

    Only rows here drive spread alerts and hotspot points. docs/DESIGN.md §10:
    an unconfirmed model output must not trigger village-wide alarm."""

    __tablename__ = "confirmation"

    id: Mapped[uuid.UUID] = _uuid_pk()
    case_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("case.id", ondelete="CASCADE"), nullable=False, index=True
    )
    problem_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("problem.id", ondelete="CASCADE"), nullable=False, index=True
    )
    agronomist_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("app_user.id", ondelete="RESTRICT"), nullable=False
    )
    verdict: Mapped[ConfirmationVerdict] = mapped_column(
        pg_enum(ConfirmationVerdict, "confirmation_verdict"), nullable=False
    )
    corrected_label: Mapped[TargetLabel | None] = mapped_column(
        pg_enum(TargetLabel, "target_label")
    )
    treatment: Mapped[str | None] = mapped_column(Text)
    notes: Mapped[str | None] = mapped_column(Text)
    created_at: Mapped[datetime] = mapped_column(
        TIMESTAMPTZ, nullable=False, server_default=func.now()
    )

    __table_args__ = (
        # A "corrected" verdict without the corrected label is not a correction.
        CheckConstraint(
            "(verdict = 'corrected') = (corrected_label IS NOT NULL)",
            name="ck_confirmation_corrected_requires_label",
        ),
    )


class CorpusDoc(Base):
    """docs/DESIGN.md §5 and §8. Retrieval filters by crop and target, so a
    chunk missing either is invisible to the pipeline.

    The HNSW index for cosine distance is created by hand in the migration; the
    vector operator class is not expressible in plain Index() metadata."""

    __tablename__ = "corpus_doc"

    id: Mapped[uuid.UUID] = _uuid_pk()
    title: Mapped[str] = mapped_column(Text, nullable=False)
    source: Mapped[str] = mapped_column(Text, nullable=False)
    reviewed_on: Mapped[datetime | None] = mapped_column(Date)
    target: Mapped[TargetLabel | None] = mapped_column(pg_enum(TargetLabel, "target_label"))
    crop: Mapped[Crop | None] = mapped_column(pg_enum(Crop, "crop"))
    content: Mapped[str] = mapped_column(Text, nullable=False)
    embedding: Mapped[list[float] | None] = mapped_column(Vector(1024))
    created_at: Mapped[datetime] = mapped_column(
        TIMESTAMPTZ, nullable=False, server_default=func.now()
    )

    __table_args__ = (Index("ix_corpus_doc_crop_target", "crop", "target"),)


class DistinguishingCue(Base):
    """docs/DESIGN.md §5 and §7. F4 reads from here. Structured, not free text.

    Cues are retrieved, not generated: question_text is authored alongside the
    corpus. An LLM composing a differential diagnostic question at runtime is
    exactly the fabrication risk the product exists to avoid."""

    __tablename__ = "distinguishing_cue"

    id: Mapped[uuid.UUID] = _uuid_pk()
    cue_text: Mapped[str] = mapped_column(Text, nullable=False)
    question_text: Mapped[str] = mapped_column(Text, nullable=False)
    discriminates: Mapped[list[str]] = mapped_column(ARRAY(Text), nullable=False)
    answer_yes_implies: Mapped[TargetLabel] = mapped_column(
        pg_enum(TargetLabel, "target_label"), nullable=False
    )
    doc_id: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("corpus_doc.id", ondelete="SET NULL")
    )
    created_at: Mapped[datetime] = mapped_column(
        TIMESTAMPTZ, nullable=False, server_default=func.now()
    )

    __table_args__ = (
        # A cue discriminates between exactly two labels. One or three is a
        # different feature, and the gate only ever hands over top-1 and top-2.
        CheckConstraint(
            "array_length(discriminates, 1) = 2", name="ck_distinguishing_cue_pair"
        ),
    )
