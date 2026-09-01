import { z } from 'zod';

export const roleSchema = z.enum(['farmer', 'agronomist', 'official']);

export const loginRequestSchema = z.object({
  email: z.string().email('Invalid email address'),
  password: z.string().min(1, 'Password is required'),
});

export const userProfileSchema = z.object({
  id: z.string().min(1, 'User ID is required'),
  role: roleSchema,
  name: z.string().min(1, 'User name is required'),
  email: z.string().optional(),
  phone: z.string().optional(),
});

export const loginResponseSchema = z.object({
  access_token: z.string().min(1, 'Access token is required'),
  refresh_token: z.string().optional(),
  user: userProfileSchema,
});

export const apiErrorEnvelopeSchema = z.object({
  error: z.object({
    code: z.string(),
    message: z.string(),
    details: z.record(z.unknown()).optional(),
  }),
});
