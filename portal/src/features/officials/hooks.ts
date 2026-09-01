import { useQuery } from '@tanstack/react-query';
import { officialsApi } from './api';
import { HotspotsParams, AccuracyParams } from '@/types/api';

export const officialKeys = {
  all: ['official'] as const,
  hotspots: (params?: HotspotsParams) => [...officialKeys.all, 'hotspots', params] as const,
  accuracy: (params?: AccuracyParams) => [...officialKeys.all, 'accuracy', params] as const,
  queue: () => [...officialKeys.all, 'queue'] as const,
};

export function useOfficialHotspots(params?: HotspotsParams) {
  return useQuery({
    queryKey: officialKeys.hotspots(params),
    queryFn: () => officialsApi.getHotspots(params),
  });
}

export function useOfficialAccuracy(params?: AccuracyParams) {
  return useQuery({
    queryKey: officialKeys.accuracy(params),
    queryFn: () => officialsApi.getAccuracy(params),
  });
}

export function useOfficialQueue(params: { limit?: number; cursor?: string } = {}) {
  // Pass pagination down if the API layer is updated later to support it
  return useQuery({
    queryKey: [...officialKeys.queue(), params],
    queryFn: () => officialsApi.getQueue(),
  });
}
