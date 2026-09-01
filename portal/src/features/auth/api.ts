import { apiClient } from '@/lib/api/client';
import { ENDPOINTS } from '@/lib/api/endpoints';
import { LoginRequest, LoginResponse } from '@/types/api';
import { loginResponseSchema, loginRequestSchema } from './validation';

export const authApi = {
  async login(credentials: LoginRequest): Promise<LoginResponse> {
    // Validate request shape
    const validatedReq = loginRequestSchema.parse(credentials);

    const rawResponse = await apiClient.post<unknown>(ENDPOINTS.AUTH.LOGIN, validatedReq, {
      skipAuth: true,
    });

    // Validate response shape according to API contract
    return loginResponseSchema.parse(rawResponse);
  },
};
