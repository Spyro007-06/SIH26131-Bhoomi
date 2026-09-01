import { useInfiniteCaseQueue } from '../hooks';
import { QueueHeader } from '../components/QueueHeader';
import { CaseQueueTable } from '../components/CaseQueueTable';
import { QueuePagination } from '../components/QueuePagination';
import { EmptyState } from '@/components/feedback/EmptyState';
import { ErrorState } from '@/components/feedback/ErrorState';
import { Button } from '@/components/ui/Button';
import { CheckCircle2 } from 'lucide-react';
import { isBhoomiApiError } from '@/lib/api/errors';

export function CaseQueuePage() {
  const {
    data,
    isLoading,
    isError,
    error,
    refetch,
    isFetching,
    hasNextPage,
    isFetchingNextPage,
    fetchNextPage,
  } = useInfiniteCaseQueue({ status: 'assigned' });

  const allCases = data?.pages.flatMap((page) => page.cases) ?? [];

  const renderContent = () => {
    if (isError) {
      const isForbidden = isBhoomiApiError(error) && error.isForbidden();

      return (
        <ErrorState
          error={error}
          title={isForbidden ? 'Access Restricted' : 'Error Loading Queue'}
          onRetry={() => refetch()}
        />
      );
    }

    if (isLoading) {
      return <CaseQueueTable cases={[]} isLoading={true} />;
    }

    if (allCases.length === 0) {
      return (
        <EmptyState
          icon={<CheckCircle2 className="h-8 w-8 text-bhoomi-green-700" />}
          title="All caught up"
          description="No assigned cases require review right now."
          action={
            <Button variant="outline" size="sm" onClick={() => refetch()}>
              Check Again
            </Button>
          }
        />
      );
    }

    return (
      <div className="space-y-4">
        <CaseQueueTable cases={allCases} />
        <QueuePagination
          hasNextPage={hasNextPage}
          isFetchingNextPage={isFetchingNextPage}
          onLoadMore={() => fetchNextPage()}
        />
      </div>
    );
  };

  return (
    <div className="space-y-6">
      <QueueHeader
        onRefresh={() => refetch()}
        isRefreshing={isFetching && !isLoading && !isFetchingNextPage}
        totalLoaded={allCases.length}
      />
      {renderContent()}
    </div>
  );
}
