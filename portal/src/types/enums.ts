/**
 * Bhoomi API Contract v3.0 Enums
 * Authoritative source: docs/API_CONTRACT.md §1
 */

export type Role = 'farmer' | 'agronomist' | 'official';

export type Crop = 'paddy' | 'cotton' | 'soybean' | 'jowar';

export type ProblemType = 'disease' | 'pest';

export type TargetTier = 'diagnosable' | 'inspection';

export const PADDY_TARGETS = [
  'paddy_blast',
  'paddy_brown_spot',
  'paddy_bacterial_leaf_blight',
  'paddy_yellow_stem_borer',
  'paddy_brown_planthopper',
] as const;

export const COTTON_TARGETS = [
  'cotton_american_bollworm',
  'cotton_pink_bollworm',
  'cotton_whitefly',
  'cotton_thrips',
  'cotton_bacterial_blight',
  'cotton_leaf_curl_virus',
  'cotton_fusarium_wilt',
] as const;

export const SOYBEAN_TARGETS = [
  'soybean_stem_fly',
  'soybean_girdle_beetle',
  'soybean_defoliating_caterpillars',
  'soybean_yellow_mosaic_virus',
  'soybean_anthracnose',
  'soybean_alternaria_leaf_spot',
  'soybean_bacterial_blight',
] as const;

export const JOWAR_TARGETS = [
  'jowar_shoot_fly',
  'jowar_stem_borer',
  'jowar_shoot_bug',
  'jowar_anthracnose',
  'jowar_grain_mold',
  'jowar_smut',
  'jowar_downy_mildew',
] as const;

export const ALL_TARGET_LABELS = [
  ...PADDY_TARGETS,
  ...COTTON_TARGETS,
  ...SOYBEAN_TARGETS,
  ...JOWAR_TARGETS,
] as const;

export type TargetLabel = (typeof ALL_TARGET_LABELS)[number];

// Growth stage in v3 is a per-crop string key from the growth_stage table
export type GrowthStageKey = string;

export type ProblemSeverity = 'early' | 'moderate' | 'severe';

export type ProblemStatus = 'open' | 'resolved';

export type GateOutcome = 'advise' | 'clarify' | 'escalate';

export type GateReasonCode =
  | 'ABOVE_GATE'
  | 'AMBIGUOUS'
  | 'BELOW_FLOOR'
  | 'OUT_OF_SCOPE'
  | 'NO_RELEVANT_SOURCE';

export type CueAnswer = 'yes' | 'no' | 'unknown';

export type LadderTier = 'cultural' | 'biological' | 'chemical';

export type VerdictCode =
  | 'NO_OBJECTION_FOUND'
  | 'NOT_REGISTERED_FOR_TARGET'
  | 'WRONG_CROP'
  | 'WRONG_CLASS'
  | 'PHI_CONFLICT'
  | 'NOT_IN_RECORDS';

export type AlertTrigger = 'weather' | 'seasonal' | 'spread' | 'combined';

export type AlertOutcome = 'nothing_found' | 'found' | 'snoozed';

export type FollowupResponse = 'improved' | 'no_change' | 'got_worse';

export type CaseStatus = 'open' | 'assigned' | 'resolved';

export type ConfirmationVerdict = 'confirmed' | 'corrected';

export type AssetKind = 'image' | 'audio';

export type ErrorCode =
  | 'UNAUTHENTICATED'
  | 'FORBIDDEN'
  | 'NOT_FOUND'
  | 'VALIDATION_FAILED'
  | 'BELOW_CONFIDENCE_GATE'
  | 'AMBIGUOUS_REQUIRES_CLARIFICATION'
  | 'OUT_OF_SCOPE_TARGET'
  | 'NO_RELEVANT_SOURCE'
  | 'OCR_UNREADABLE'
  | 'PRODUCT_NOT_IN_RECORDS'
  | 'AGRONOMIST_UNAVAILABLE'
  | 'FIXTURES_DISABLED';
