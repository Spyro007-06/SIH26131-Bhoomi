import { useState, useMemo } from 'react';
import { useInfiniteCaseQueue } from '../hooks';
import { QueueHeader } from '../components/QueueHeader';
import { CaseQueueTable } from '../components/CaseQueueTable';
import { QueuePagination } from '../components/QueuePagination';
import { EmptyState } from '@/components/feedback/EmptyState';
import { ErrorState } from '@/components/feedback/ErrorState';
import { Button } from '@/components/ui/Button';
import { CheckCircle2, SearchX } from 'lucide-react';
import { isBhoomiApiError } from '@/lib/api/errors';

export function CaseQueuePage() {
  const [searchQuery, setSearchQuery] = useState('');

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

  const allCases = useMemo(() => {
    return data?.pages.flatMap((page) => page.cases) ?? [];
  }, [data]);

  const filteredCases = useMemo(() => {
    if (!searchQuery.trim()) return allCases;
    const lowerQuery = searchQuery.toLowerCase().trim();

    return allCases.filter((c) => {
      const matchId = c.case_id.toLowerCase().includes(lowerQuery);
      const matchLabel = c.label?.toLowerCase().includes(lowerQuery) ?? false;
      const matchRegion = c.region?.toLowerCase().includes(lowerQuery) ?? false;
      return matchId || matchLabel || matchRegion;
    });
  }, [allCases, searchQuery]);

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
          icon={<CheckCircle2 className="h-8 w-8 text-bhoomi-primary" />}
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

    if (filteredCases.length === 0 && searchQuery.trim()) {
      return (
        <EmptyState
          icon={<SearchX className="h-8 w-8 text-bhoomi-text-muted" />}
          title="No matching cases"
          description={`No active cases match "${searchQuery}". Try searching with a different term.`}
          action={
            <Button variant="secondary" size="sm" onClick={() => setSearchQuery('')}>
              Clear Search
            </Button>
          }
        />
      );
    }

    return (
      <div className="space-y-4">
        <CaseQueueTable cases={filteredCases} />
        {!searchQuery.trim() && (
          <QueuePagination
            hasNextPage={hasNextPage}
            isFetchingNextPage={isFetchingNextPage}
            onLoadMore={() => fetchNextPage()}
          />
        )}
      </div>
    );
  };

  return (
    <div className="space-y-6">
      <QueueHeader
        onRefresh={() => refetch()}
        isRefreshing={isFetching && !isLoading && !isFetchingNextPage}
        totalLoaded={allCases.length}
        searchQuery={searchQuery}
        onSearchChange={setSearchQuery}
      />
      {renderContent()}
    </div>
  );
}
