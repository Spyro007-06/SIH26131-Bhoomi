/**
 * Bhoomi API Contract v3.0 Types
 * Authoritative source: docs/API_CONTRACT.md
 * NOTE: All wire property names preserve exact snake_case as defined in the API contract.
 */

import {
  Role,
  Crop,
  ProblemType,
  ProblemSeverity,
  ProblemStatus,
  TargetLabel,
  GateOutcome,
  GateReasonCode,
  CueAnswer,
  CaseStatus,
  ConfirmationVerdict,
  ErrorCode,
} from './enums';

export type {
  Role,
  Crop,
  ProblemType,
  ProblemSeverity,
  ProblemStatus,
  TargetLabel,
  GateOutcome,
  GateReasonCode,
  CueAnswer,
  CaseStatus,
  ConfirmationVerdict,
  ErrorCode,
};

// ---------------------------------------------------------------------------
// Error Envelope (§0)
// ---------------------------------------------------------------------------

export interface ApiErrorDetails {
  [key: string]: unknown;
}

export interface ApiErrorBody {
  code: ErrorCode | string;
  message: string;
  details?: ApiErrorDetails;
}

export interface ApiErrorEnvelope {
  error: ApiErrorBody;
}

// ---------------------------------------------------------------------------
// Pagination (§0)
// ---------------------------------------------------------------------------

export interface PaginationParams {
  limit?: number;
  cursor?: string;
}

// ---------------------------------------------------------------------------
// Auth (§2)
// ---------------------------------------------------------------------------

export interface UserProfile {
  id: string;
  role: Role;
  name: string;
  email?: string;
  phone?: string;
}

export interface LoginRequest {
  email: string;
  password: string;
}

export interface LoginResponse {
  access_token: string;
  refresh_token?: string;
  user: UserProfile;
}

export interface OtpRequest {
  phone: string;
}

export interface OtpRequestResponse {
  request_id: string;
  expires_in: number;
}

export interface OtpVerifyRequest {
  request_id: string;
  otp: string;
}

export interface OtpVerifyResponse {
  access_token: string;
  refresh_token?: string;
  user: UserProfile;
}

// ---------------------------------------------------------------------------
// Shared Domain Structures
// ---------------------------------------------------------------------------

export interface GeoLocation {
  lat: number;
  lng: number;
}

export interface FarmSummary {
  id: string;
  crop: Crop;
  variety?: string | null;
  growth_stage: string;
  region: string;
  location?: GeoLocation;
}

export interface Prediction {
  label: string;
  confidence: number;
}

export interface GateInfo {
  outcome: GateOutcome;
  confidence?: number;
  threshold_applied?: number;
  reason_code: GateReasonCode | string;
  alternatives?: Prediction[];
  is_stub?: boolean;
}

export interface FieldObservation {
  question: string;
  answer: CueAnswer;
  at: string;
}

export interface CaseImage {
  asset_id: string;
  url: string;
  at: string;
}

export interface CaseLabelCheck {
  ingredient: string;
  verdict: string;
  at: string;
}

export interface CaseProblem {
  id: string;
  type: ProblemType;
  label: string;
  severity: ProblemSeverity;
  opened_at: string;
}

// ---------------------------------------------------------------------------
// F12 — Agronomist Portal Types (§12, §13)
// ---------------------------------------------------------------------------

export interface CaseBundle {
  case_id: string;
  status: CaseStatus;
  farm: FarmSummary;
  problem: CaseProblem;
  model_hypotheses: Prediction[];
  gate: GateInfo;
  field_observations: FieldObservation[];
  images: CaseImage[];
  treatments_tried: string[];
  label_checks: CaseLabelCheck[];
  followup_trend?: string | null;
  spoken_summary?: string | null;
}

export interface CaseQueueItem {
  case_id: string;
  problem_id?: string;
  farm_id?: string;
  region: string;
  label?: TargetLabel | string | null;
  status: CaseStatus;
  queue_position?: number | null;
  eta_minutes?: number | null;
  created_at: string;
}

export interface CaseQueueResponse {
  cases: CaseQueueItem[];
  next_cursor?: string | null;
}

export interface CaseConfirmRequest {
  verdict: ConfirmationVerdict;
  corrected_label?: string;
  treatment?: string;
  notes?: string;
}

export interface CaseConfirmResponse {
  case_id: string;
  status: CaseStatus;
  problem_status: ProblemStatus;
  confirmation_id: string;
  spread_alerts_issued: number;
}

export interface CaseRequestInfoRequest {
  question: string;
  question_localized?: string;
}

export interface CaseRequestInfoResponse {
  case_id: string;
  status: CaseStatus;
  info_requested_at: string;
}

// ---------------------------------------------------------------------------
// F15 — Officials Dashboard Types (§15)
// ---------------------------------------------------------------------------

export interface HotspotPoint {
  lat: number;
  lng: number;
  label: string;
  confirmed_count: number;
  first_seen: string;
  last_seen: string;
}

export interface HotspotsResponse {
  points: HotspotPoint[];
  totals_by_label: Record<string, number>;
}

export interface HotspotsParams {
  region?: string;
  crop?: Crop | string;
  from?: string;
  to?: string;
}

export interface LabelAccuracy {
  label: string;
  confirmed: number;
  corrected: number;
  accuracy: number | null;
}

export interface AccuracyWindow {
  from?: string | null;
  to?: string | null;
}

export interface AccuracyResponse {
  by_label: LabelAccuracy[];
  window: AccuracyWindow;
}

export interface AccuracyParams {
  from?: string;
  to?: string;
}

export interface OfficialQueueItem {
  case_id: string;
  predicted_label: string;
  confidence: number;
  created_at: string;
  region: string;
  severity: string;
}

export interface OfficialsQueueResponse {
  queue: OfficialQueueItem[];
  next_cursor?: string | null;
}
