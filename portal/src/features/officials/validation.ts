import { z } from 'zod';

export const hotspotPointSchema = z.object({
  lat: z.number(),
  lng: z.number(),
  label: z.string(),
  confirmed_count: z.number().int().nonnegative(),
  first_seen: z.string(),
  last_seen: z.string(),
});

export const hotspotsResponseSchema = z.object({
  points: z.array(hotspotPointSchema),
  totals_by_label: z.record(z.string(), z.number().int().nonnegative()).default({}),
});

export const accuracyRowSchema = z.object({
  label: z.string(),
  confirmed: z.number().int().nonnegative(),
  corrected: z.number().int().nonnegative(),
  accuracy: z.number().min(0).max(1).nullable().optional(),
});

export const accuracyWindowSchema = z.object({
  from: z.string().nullable().optional(),
  to: z.string().nullable().optional(),
});

export const accuracyResponseSchema = z.object({
  by_label: z.array(accuracyRowSchema),
  window: accuracyWindowSchema,
});

export const officialQueueItemSchema = z.object({
  case_id: z.string(),
  predicted_label: z.string(),
  confidence: z.number().min(0).max(1),
  created_at: z.string(),
  region: z.string(),
  severity: z.string(),
});

export const officialsQueueResponseSchema = z.object({
  queue: z.array(officialQueueItemSchema),
  next_cursor: z.string().nullable().optional(),
});
