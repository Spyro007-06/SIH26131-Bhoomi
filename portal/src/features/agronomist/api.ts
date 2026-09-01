import { apiClient } from '@/lib/api/client';
import { ENDPOINTS } from '@/lib/api/endpoints';
import {
  CaseBundle,
  CaseConfirmRequest,
  CaseConfirmResponse,
  CaseQueueResponse,
  CaseRequestInfoRequest,
  CaseRequestInfoResponse,
  PaginationParams,
} from '@/types/api';
import {
  caseBundleSchema,
  caseQueueResponseSchema,
  confirmCaseRequestSchema,
  confirmCaseResponseSchema,
  requestInfoResponseSchema,
} from './validation';

export interface CaseQueueParams extends PaginationParams {
  status?: 'assigned';
}

export const agronomistApi = {
  async getCaseQueue(params?: CaseQueueParams): Promise<CaseQueueResponse> {
    const rawData = await apiClient.get<unknown>(ENDPOINTS.AGRONOMIST.CASE_QUEUE, {
      params: {
        status: params?.status ?? 'assigned',
        limit: params?.limit,
        cursor: params?.cursor,
      },
    });

    return caseQueueResponseSchema.parse(rawData);
  },

  async getCase(caseId: string): Promise<CaseBundle> {
    const rawData = await apiClient.get<unknown>(ENDPOINTS.ESCALATION.GET_CASE_BUNDLE(caseId));
    return caseBundleSchema.parse(rawData);
  },

  async confirmCase(caseId: string, payload: CaseConfirmRequest): Promise<CaseConfirmResponse> {
    const validatedPayload = confirmCaseRequestSchema.parse(payload);
    const rawData = await apiClient.post<unknown>(
      ENDPOINTS.AGRONOMIST.CONFIRM(caseId),
      validatedPayload
    );
    return confirmCaseResponseSchema.parse(rawData);
  },

  async requestInfo(
    caseId: string,
    payload?: CaseRequestInfoRequest
  ): Promise<CaseRequestInfoResponse> {
    const rawData = await apiClient.post<unknown>(
      ENDPOINTS.AGRONOMIST.REQUEST_INFO(caseId),
      payload ?? {}
    );
    return requestInfoResponseSchema.parse(rawData);
  },
};
