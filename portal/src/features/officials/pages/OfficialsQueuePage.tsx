import { useQueryClient } from '@tanstack/react-query';
import { RefreshCw, AlertCircle, Inbox } from 'lucide-react';
import { Button } from '@/components/ui/Button';
import { Skeleton } from '@/components/ui/Skeleton';
import { Card } from '@/components/ui/Card';
import { DashboardHeader } from '../components/DashboardHeader';
import { OfficialQueueSummary } from '../components/OfficialQueueSummary';
import { OfficialQueueTable } from '../components/OfficialQueueTable';
import { officialKeys, useOfficialQueue } from '../hooks';

export function OfficialsQueuePage() {
  const queryClient = useQueryClient();
  const { data, isLoading, isError, error, refetch, isFetching } = useOfficialQueue();

  const handleRefresh = () => {
    queryClient.invalidateQueries({ queryKey: officialKeys.queue() });
  };

  const items = data?.queue || [];

  return (
    <div className="flex-1 flex flex-col h-full overflow-hidden bg-bhoomi-surface">
      {/* Header Bar */}
      <div className="flex items-start justify-between p-4 md:p-6 lg:p-8 pb-0">
        <DashboardHeader
          title="Official Queue"
          subtitle="Review records requiring official attention."
        />

        <Button
          variant="outline"
          size="sm"
          onClick={handleRefresh}
          disabled={isFetching}
          className="gap-2 bg-white text-bhoomi-text-secondary shadow-xs hover:bg-bhoomi-surface-soft hover:text-bhoomi-green-900 border-bhoomi-border hidden sm:flex"
          aria-label="Refresh queue data"
        >
          <RefreshCw className={`h-4 w-4 ${isFetching ? 'animate-spin text-bhoomi-green-600' : ''}`} />
          <span>Refresh</span>
        </Button>
      </div>

      {/* Main Content Area */}
      <main className="flex-1 p-4 md:p-6 lg:p-8 pt-6 max-w-7xl w-full mx-auto overflow-y-auto space-y-6 pb-24">
        {/* Loading State */}
        {isLoading && (
          <div className="space-y-6">
            <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
              {[1, 2, 3, 4].map((i) => (
                <Card key={i} className="p-5">
                  <Skeleton className="h-4 w-28 mb-3" />
                  <Skeleton className="h-8 w-20 mb-2" />
                  <Skeleton className="h-3 w-36" />
                </Card>
              ))}
            </div>
            <Card className="p-6">
              <Skeleton className="h-6 w-48 mb-4" />
              <div className="space-y-3">
                {[1, 2, 3, 4, 5].map((i) => (
                  <Skeleton key={i} className="h-12 w-full" />
                ))}
              </div>
            </Card>
          </div>
        )}

        {/* Error State */}
        {!isLoading && isError && (
          <Card className="border-red-200 bg-red-50/40 p-8 text-center space-y-4">
            <div className="mx-auto flex h-12 w-12 items-center justify-center rounded-full bg-red-100 text-red-700">
              <AlertCircle className="h-6 w-6" />
            </div>
            <div className="space-y-1">
              <h3 className="text-base font-bold text-bhoomi-text">
                Unable to load the official queue.
              </h3>
              <p className="text-xs text-bhoomi-text-secondary max-w-md mx-auto">
                Official queue records are temporarily unavailable.
                {error instanceof Error && (
                  <span className="block mt-1 text-red-600 font-mono text-[11px]">{error.message}</span>
                )}
              </p>
            </div>
            <Button
              onClick={() => refetch()}
              variant="outline"
              size="sm"
              className="gap-2 bg-white text-bhoomi-text border-red-200 hover:bg-red-50"
            >
              <RefreshCw className="h-4 w-4" />
              <span>Retry</span>
            </Button>
          </Card>
        )}

        {/* Empty State */}
        {!isLoading && !isError && items.length === 0 && (
          <Card className="border-dashed border-bhoomi-border bg-white p-12 text-center space-y-4">
            <div className="mx-auto flex h-14 w-14 items-center justify-center rounded-full bg-amber-50 text-amber-600">
              <Inbox className="h-7 w-7" />
            </div>
            <div className="space-y-1">
              <h3 className="text-base font-bold text-bhoomi-text">
                No records currently require attention.
              </h3>
              <p className="text-xs text-bhoomi-text-secondary max-w-md mx-auto">
                The official confirmation queue is currently up to date. New cases will appear here as field escalations are logged.
              </p>
            </div>
            <Button
              onClick={() => refetch()}
              variant="outline"
              size="sm"
              className="gap-2 bg-white text-bhoomi-text-secondary"
            >
              <RefreshCw className="h-3.5 w-3.5" />
              <span>Check for Updates</span>
            </Button>
          </Card>
        )}

        {/* Queue Presentation */}
        {!isLoading && !isError && items.length > 0 && (
          <>
            {/* Summary Cards */}
            <OfficialQueueSummary items={items} />

            {/* Queue Table */}
            <OfficialQueueTable items={items} />
          </>
        )}
      </main>
    </div>
  );
}
