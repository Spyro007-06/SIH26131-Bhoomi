import { describe, it, expect, beforeEach, vi } from 'vitest';
import { apiClient } from '@/lib/api/client';
import { tokenStorage } from '@/lib/auth/token-storage';
import { BhoomiApiError } from '@/lib/api/errors';
import {
  loginRequestSchema,
  loginResponseSchema,
  userProfileSchema,
} from '@/features/auth/validation';

describe('ApiClient & Auth Validation Tests', () => {
  beforeEach(() => {
    tokenStorage.clearAll();
    vi.restoreAllMocks();
  });

  it('attaches Authorization Bearer header when token exists', async () => {
    tokenStorage.setToken('valid_token_xyz');

    const fetchSpy = vi.spyOn(globalThis, 'fetch').mockResolvedValueOnce(
      new Response(JSON.stringify({ success: true }), {
        status: 200,
        headers: { 'Content-Type': 'application/json' },
      })
    );

    await apiClient.get('/test/secure-resource');

    expect(fetchSpy).toHaveBeenCalledTimes(1);
    const callArgs = fetchSpy.mock.calls[0];
    const headers = (callArgs?.[1]?.headers as Record<string, string>) || {};
    expect(headers['Authorization']).toBe('Bearer valid_token_xyz');
  });

  it('does NOT attach Authorization header when token is missing or skipAuth is true', async () => {
    tokenStorage.clearToken();

    const fetchSpy = vi.spyOn(globalThis, 'fetch').mockResolvedValueOnce(
      new Response(JSON.stringify({ success: true }), {
        status: 200,
        headers: { 'Content-Type': 'application/json' },
      })
    );

    await apiClient.get('/test/public-resource');

    expect(fetchSpy).toHaveBeenCalledTimes(1);
    const callArgs = fetchSpy.mock.calls[0];
    const headers = (callArgs?.[1]?.headers as Record<string, string>) || {};
    expect(headers['Authorization']).toBeUndefined();
  });

  it('correctly parses Bhoomi error envelope with code and details', async () => {
    vi.spyOn(globalThis, 'fetch').mockResolvedValueOnce(
      new Response(
        JSON.stringify({
          error: {
            code: 'VALIDATION_FAILED',
            message: 'Invalid filter parameter supplied',
            details: { field: 'crop', value: 'banana' },
          },
        }),
        {
          status: 422,
          headers: { 'Content-Type': 'application/json' },
        }
      )
    );

    try {
      await apiClient.get('/test/invalid');
      expect.unreachable('Should have thrown BhoomiApiError');
    } catch (err: unknown) {
      expect(err).toBeInstanceOf(BhoomiApiError);
      const apiErr = err as BhoomiApiError;
      expect(apiErr.status).toBe(422);
      expect(apiErr.code).toBe('VALIDATION_FAILED');
      expect(apiErr.message).toBe('Invalid filter parameter supplied');
      expect(apiErr.details).toEqual({ field: 'crop', value: 'banana' });
      expect(apiErr.isValidationError()).toBe(true);
    }
  });

  it('wraps fetch network failures into BhoomiApiError.fromNetworkError', async () => {
    vi.spyOn(globalThis, 'fetch').mockRejectedValueOnce(new TypeError('Failed to fetch'));

    try {
      await apiClient.get('/test/network-fail');
      expect.unreachable('Should have thrown network error');
    } catch (err: unknown) {
      expect(err).toBeInstanceOf(BhoomiApiError);
      const apiErr = err as BhoomiApiError;
      expect(apiErr.isNetworkError()).toBe(true);
      expect(apiErr.code).toBe('NETWORK_ERROR');
    }
  });

  it('validates Zod login request schema accurately', () => {
    expect(() =>
      loginRequestSchema.parse({
        email: 'agronomist@kvk.gov.in',
        password: 'secure_password_123',
      })
    ).not.toThrow();

    expect(() =>
      loginRequestSchema.parse({
        email: 'invalid-email',
        password: 'password',
      })
    ).toThrow();
  });

  it('validates Zod userProfileSchema and loginResponseSchema matching API contract v3.0', () => {
    const validResponse = {
      access_token: 'jwt.sample.token',
      user: {
        id: 'usr_1',
        role: 'official',
        name: 'Maharashtra Official',
        email: 'official@gov.in',
      },
    };

    const parsed = loginResponseSchema.parse(validResponse);
    expect(parsed.access_token).toBe('jwt.sample.token');
    expect(parsed.user.role).toBe('official');

    // Reject unknown role
    expect(() =>
      userProfileSchema.parse({
        id: 'usr_2',
        role: 'super_admin', // Invalid role not in contract
        name: 'Invalid User',
      })
    ).toThrow();
  });

  it('manages token storage persistence and clearing safely', () => {
    tokenStorage.setToken('test_jwt_123');
    expect(tokenStorage.getToken()).toBe('test_jwt_123');

    const sampleUser = { id: 'u_1', role: 'agronomist' as const, name: 'Suresh' };
    tokenStorage.setUser(sampleUser);
    expect(tokenStorage.getUser()).toEqual(sampleUser);

    tokenStorage.clearAll();
    expect(tokenStorage.getToken()).toBeNull();
    expect(tokenStorage.getUser()).toBeNull();
  });
});
