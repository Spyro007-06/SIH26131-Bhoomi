import { useQuery, useInfiniteQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { agronomistApi, CaseQueueParams } from './api';
import { CaseConfirmRequest, CaseRequestInfoRequest } from '@/types/api';

export const agronomistKeys = {
  all: ['agronomist'] as const,
  queue: (params?: CaseQueueParams) =>
    [
      ...agronomistKeys.all,
      'case-queue',
      {
        status: params?.status ?? 'assigned',
        limit: params?.limit,
        cursor: params?.cursor,
      },
    ] as const,
  infiniteQueue: (params?: Omit<CaseQueueParams, 'cursor'>) =>
    [
      ...agronomistKeys.all,
      'infinite-case-queue',
      {
        status: params?.status ?? 'assigned',
        limit: params?.limit,
      },
    ] as const,
  detail: (caseId: string) => [...agronomistKeys.all, 'case', caseId] as const,
};

export function useCaseQueue(params?: CaseQueueParams) {
  return useQuery({
    queryKey: agronomistKeys.queue(params),
    queryFn: () => agronomistApi.getCaseQueue(params),
    retry: false,
  });
}

export function useInfiniteCaseQueue(params?: Omit<CaseQueueParams, 'cursor'>) {
  return useInfiniteQuery({
    queryKey: agronomistKeys.infiniteQueue(params),
    queryFn: ({ pageParam }) =>
      agronomistApi.getCaseQueue({
        ...params,
        status: params?.status ?? 'assigned',
        cursor: pageParam as string | undefined,
      }),
    initialPageParam: undefined as string | undefined,
    getNextPageParam: (lastPage) => lastPage.next_cursor ?? undefined,
    retry: false,
  });
}

export function useCase(caseId: string) {
  return useQuery({
    queryKey: agronomistKeys.detail(caseId),
    queryFn: () => agronomistApi.getCase(caseId),
    retry: false,
    enabled: Boolean(caseId),
  });
}

export function useConfirmCase(caseId: string) {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (payload: CaseConfirmRequest) => agronomistApi.confirmCase(caseId, payload),
    onSuccess: () => {
      // Invalidate case queues so resolved cases disappear from active lists
      queryClient.invalidateQueries({ queryKey: agronomistKeys.all });
    },
  });
}

export function useRequestInfo(caseId: string) {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (payload?: CaseRequestInfoRequest) => agronomistApi.requestInfo(caseId, payload),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: agronomistKeys.detail(caseId) });
    },
  });
}
