import { apiClient } from '@/lib/api/client';
import { ENDPOINTS } from '@/lib/api/endpoints';
import {
  HotspotsResponse,
  HotspotsParams,
  AccuracyResponse,
  AccuracyParams,
  OfficialsQueueResponse,
} from '@/types/api';
import {
  hotspotsResponseSchema,
  accuracyResponseSchema,
  officialsQueueResponseSchema,
} from './validation';

export const officialsApi = {
  async getHotspots(params?: HotspotsParams): Promise<HotspotsResponse> {
    const rawData = await apiClient.get<unknown>(ENDPOINTS.OFFICIALS.HOTSPOTS, {
      params: {
        region: params?.region,
        crop: params?.crop,
        from: params?.from,
        to: params?.to,
      },
    });
    return hotspotsResponseSchema.parse(rawData);
  },

  async getAccuracy(params?: AccuracyParams): Promise<AccuracyResponse> {
    const rawData = await apiClient.get<unknown>(ENDPOINTS.OFFICIALS.ACCURACY, {
      params: {
        from: params?.from,
        to: params?.to,
      },
    });
    return accuracyResponseSchema.parse(rawData) as AccuracyResponse;
  },

  async getQueue(): Promise<OfficialsQueueResponse> {
    const rawData = await apiClient.get<unknown>(ENDPOINTS.OFFICIALS.QUEUE);
    return officialsQueueResponseSchema.parse(rawData) as OfficialsQueueResponse;
  },
};
