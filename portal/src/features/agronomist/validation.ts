import { z } from 'zod';

export const cropSchema = z.enum(['paddy', 'cotton', 'soybean', 'jowar']);
export const caseStatusSchema = z.enum(['open', 'assigned', 'resolved']);
export const confirmationVerdictSchema = z.enum(['confirmed', 'corrected']);
export const problemSeveritySchema = z.enum(['early', 'moderate', 'severe']);
export const problemTypeSchema = z.enum(['disease', 'pest']);
export const gateOutcomeSchema = z.enum(['advise', 'clarify', 'escalate']);

export const caseQueueItemSchema = z.object({
  case_id: z.string().min(1, 'Case ID is required'),
  problem_id: z.string().optional(),
  farm_id: z.string().optional(),
  region: z.string().optional().default('Maharashtra'),
  label: z.string().nullable().optional(),
  status: caseStatusSchema.default('assigned'),
  queue_position: z.number().int().nullable().optional(),
  eta_minutes: z.number().int().nullable().optional(),
  created_at: z.string().min(1, 'Created timestamp is required'),
});

export const caseQueueResponseSchema = z.object({
  cases: z.array(caseQueueItemSchema),
  next_cursor: z.string().nullable().optional(),
});

export const farmSummarySchema = z.object({
  id: z.string(),
  crop: cropSchema,
  variety: z.string().nullable().optional(),
  growth_stage: z.string(),
  region: z.string(),
  location: z
    .object({
      lat: z.number(),
      lng: z.number(),
    })
    .optional(),
});

export const caseProblemSchema = z.object({
  id: z.string(),
  type: problemTypeSchema,
  label: z.string(),
  severity: problemSeveritySchema,
  opened_at: z.string(),
});

export const modelHypothesisSchema = z.object({
  label: z.string(),
  confidence: z.number().min(0).max(1),
});

export const gateInfoSchema = z.object({
  outcome: gateOutcomeSchema,
  confidence: z.number().optional(),
  threshold_applied: z.number().optional(),
  reason_code: z.string(),
  alternatives: z.array(modelHypothesisSchema).optional(),
  is_stub: z.boolean().optional(),
});

export const cueAnswerSchema = z.enum(['yes', 'no', 'unknown']);

export const fieldObservationSchema = z.object({
  question: z.string(),
  answer: cueAnswerSchema,
  at: z.string(),
});

export const caseImageSchema = z.object({
  asset_id: z.string(),
  url: z.string(),
  at: z.string(),
});

export const caseLabelCheckSchema = z.object({
  ingredient: z.string(),
  verdict: z.string(),
  at: z.string(),
});

export const caseBundleSchema = z.object({
  case_id: z.string(),
  status: caseStatusSchema,
  farm: farmSummarySchema,
  problem: caseProblemSchema,
  model_hypotheses: z.array(modelHypothesisSchema),
  gate: gateInfoSchema,
  field_observations: z.array(fieldObservationSchema).default([]),
  images: z.array(caseImageSchema).default([]),
  treatments_tried: z.array(z.string()).default([]),
  label_checks: z.array(caseLabelCheckSchema).default([]),
  followup_trend: z.string().nullable().optional(),
  spoken_summary: z.string().nullable().optional(),
});

export const confirmCaseRequestSchema = z
  .object({
    verdict: confirmationVerdictSchema,
    corrected_label: z.string().optional(),
    treatment: z.string().optional(),
    notes: z.string().optional(),
  })
  .refine(
    (data) => {
      if (data.verdict === 'corrected') {
        return !!data.corrected_label && data.corrected_label.trim().length > 0;
      }
      return true;
    },
    {
      message: 'A corrected diagnosis label is required when verdict is "corrected"',
      path: ['corrected_label'],
    }
  );

export const confirmCaseResponseSchema = z.object({
  case_id: z.string(),
  status: caseStatusSchema,
  problem_status: z.enum(['open', 'resolved']),
  confirmation_id: z.string(),
  spread_alerts_issued: z.number().int().nonnegative(),
});

export const requestInfoRequestSchema = z.object({
  question: z.string().optional(),
  question_localized: z.string().optional(),
  notes: z.string().optional(),
});

export const requestInfoResponseSchema = z.object({
  case_id: z.string(),
  status: caseStatusSchema.optional().default('assigned'),
  info_requested_at: z.string().default(() => new Date().toISOString()),
});
