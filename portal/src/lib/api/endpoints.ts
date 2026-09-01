/**
 * Bhoomi Complete API Contract Endpoint Inventory (v3.0 Frozen)
 * Authoritative source: docs/API_CONTRACT.md §16
 *
 * NOTE: This file represents the frozen API contract inventory.
 * No endpoints may be added, renamed, or modified.
 */

export const ENDPOINTS = {
  // §2 Auth
  AUTH: {
    OTP_REQUEST: '/auth/otp/request',
    OTP_VERIFY: '/auth/otp/verify',
    LOGIN: '/auth/login',
  },

  // §3 Media
  MEDIA: {
    PRESIGN: '/assets/presign',
  },

  // §4 Voice
  VOICE: {
    TRANSCRIBE: '/voice/transcribe',
    SYNTHESIZE: '/voice/synthesize',
  },

  // §5 Farm
  FARM: {
    CREATE: '/farms',
    GET_BY_ID: (id: string) => `/farms/${id}`,
    UPDATE: (id: string) => `/farms/${id}`,
    SUMMARY: (id: string) => `/farms/${id}/summary`,
  },

  // §6 Diagnosis
  DIAGNOSIS: {
    DIAGNOSE: (farmId: string) => `/farms/${farmId}/diagnose`,
  },

  // §7 Doubt Doctor
  DOUBT_DOCTOR: {
    CLARIFY: (problemId: string) => `/problems/${problemId}/clarify`,
  },

  // §8 Advisory
  ADVISORY: {
    QUERY: '/advisory/query',
  },

  // §9 Pesticide Label Check
  PESTICIDE: {
    LABEL_CHECK: (problemId: string) => `/problems/${problemId}/label-check`,
  },

  // §10 Alerts
  ALERTS: {
    LIST_BY_FARM: (farmId: string) => `/farms/${farmId}/alerts`,
    RESPOND: (alertId: string) => `/alerts/${alertId}/respond`,
  },

  // §11 Problems, Timeline, Follow-up
  PROBLEMS: {
    TIMELINE: (farmId: string) => `/farms/${farmId}/timeline`,
    LIST_BY_FARM: (farmId: string) => `/farms/${farmId}/problems`,
    GET_BY_ID: (problemId: string) => `/problems/${problemId}`,
    PENDING_FOLLOWUPS: (farmId: string) => `/farms/${farmId}/followups/pending`,
  },

  // §11 Follow-up
  FOLLOWUP: {
    RESPOND: (followupId: string) => `/followups/${followupId}/respond`,
  },

  // §12 Escalation & Case Bundle
  ESCALATION: {
    ESCALATE: (problemId: string) => `/problems/${problemId}/escalate`,
    GET_CASE_BUNDLE: (caseId: string) => `/cases/${caseId}`,
  },

  // §13 Agronomist
  AGRONOMIST: {
    CASE_QUEUE: '/agronomist/case-queue',
    CONFIRM: (caseId: string) => `/cases/${caseId}/confirm`,
    REQUEST_INFO: (caseId: string) => `/cases/${caseId}/request-info`,
  },

  // §14 Referral
  REFERRAL: {
    BY_FARM: (farmId: string) => `/farms/${farmId}/referrals`,
  },

  // §15 Officials Dashboard
  OFFICIALS: {
    HOTSPOTS: '/officials/hotspots',
    ACCURACY: '/officials/accuracy',
    QUEUE: '/officials/queue',
  },
} as const;
