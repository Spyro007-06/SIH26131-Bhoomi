import { useQueryClient } from '@tanstack/react-query';
import { RefreshCw, AlertCircle, Inbox, ShieldCheck, Activity } from 'lucide-react';
import { Button } from '@/components/ui/Button';
import { Skeleton } from '@/components/ui/Skeleton';
import { Card } from '@/components/ui/Card';
import { Badge } from '@/components/ui/Badge';
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
    <div className="space-y-6 max-w-7xl mx-auto pb-20">
      {/* Header Bar */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 border-b border-bhoomi-border pb-5">
        <div>
          <div className="flex items-center gap-2.5">
            <DashboardHeader
              title="Official Queue"
              subtitle="Review records requiring official attention."
            />
            <Badge variant="primary" size="sm" className="hidden sm:inline-flex gap-1">
              <ShieldCheck className="h-3.5 w-3.5" />
              <span>Official Review</span>
            </Badge>
          </div>
        </div>

        <div className="flex items-center gap-3">
          <div className="flex items-center gap-1.5 text-xs text-bhoomi-primary bg-bhoomi-primary-light px-3 py-1.5 rounded-full border border-bhoomi-primary/20">
            <Activity className="h-3.5 w-3.5 text-bhoomi-primary animate-pulse" />
            <span className="font-semibold">Confirmation Stream Active</span>
          </div>

          <Button
            type="button"
            variant="outline"
            size="sm"
            onClick={handleRefresh}
            disabled={isFetching}
            className="gap-2 text-xs"
            aria-label="Refresh queue data"
          >
            <RefreshCw className={`h-3.5 w-3.5 ${isFetching ? 'animate-spin text-bhoomi-primary' : ''}`} />
            <span>{isFetching ? 'Refreshing...' : 'Refresh'}</span>
          </Button>
        </div>
      </div>

      {/* Main Content Area */}
      <main className="space-y-6">
        {/* Loading State */}
        {isLoading && (
          <div className="space-y-6">
            <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
              {[1, 2, 3, 4].map((i) => (
                <Card key={i} className="p-5 rounded-2xl border border-bhoomi-border bg-bhoomi-surface shadow-card">
                  <Skeleton className="h-4 w-28 mb-3 rounded-md" />
                  <Skeleton className="h-8 w-20 mb-2 rounded-lg" />
                  <Skeleton className="h-3 w-36 rounded-md" />
                </Card>
              ))}
            </div>
            <Card className="p-6 rounded-2xl border border-bhoomi-border bg-bhoomi-surface shadow-card">
              <Skeleton className="h-6 w-48 mb-4 rounded-lg" />
              <div className="space-y-3">
                {[1, 2, 3, 4, 5].map((i) => (
                  <Skeleton key={i} className="h-12 w-full rounded-xl" />
                ))}
              </div>
            </Card>
          </div>
        )}

        {/* Error State */}
        {!isLoading && isError && (
          <Card className="rounded-2xl border border-red-200 bg-red-50/40 p-8 text-center space-y-4 shadow-card">
            <div className="mx-auto flex h-12 w-12 items-center justify-center rounded-2xl bg-red-100 border border-red-200 text-red-700">
              <AlertCircle className="h-6 w-6 text-red-600" />
            </div>
            <div className="space-y-1">
              <h3 className="text-base font-bold text-bhoomi-text-primary">
                Unable to load the official queue.
              </h3>
              <p className="text-xs text-bhoomi-text-muted max-w-md mx-auto">
                Official queue records are temporarily unavailable.
                {error instanceof Error && (
                  <span className="block mt-1 text-red-700 font-mono text-[11px]">{error.message}</span>
                )}
              </p>
            </div>
            <Button
              onClick={() => refetch()}
              variant="outline"
              size="sm"
              className="gap-2 text-xs"
            >
              <RefreshCw className="h-3.5 w-3.5 mr-1" />
              <span>Retry</span>
            </Button>
          </Card>
        )}

        {/* Empty State */}
        {!isLoading && !isError && items.length === 0 && (
          <Card className="rounded-2xl border border-dashed border-bhoomi-border bg-bhoomi-surface p-12 text-center space-y-4 shadow-card">
            <div className="mx-auto flex h-14 w-14 items-center justify-center rounded-2xl bg-amber-50 border border-amber-200 text-amber-600">
              <Inbox className="h-7 w-7" />
            </div>
            <div className="space-y-1">
              <h3 className="text-base font-bold text-bhoomi-text-primary">
                No records currently require attention.
              </h3>
              <p className="text-xs text-bhoomi-text-muted max-w-md mx-auto">
                The official confirmation queue is currently up to date. New cases will appear here as field escalations are logged.
              </p>
            </div>
            <Button
              onClick={() => refetch()}
              variant="outline"
              size="sm"
              className="gap-2 text-xs"
            >
              <RefreshCw className="h-3.5 w-3.5 mr-1" />
              <span>Check for Updates</span>
            </Button>
          </Card>
        )}

        {/* Queue Presentation */}
        {!isLoading && !isError && items.length > 0 && (
          <div className="space-y-6">
            {/* Summary Cards */}
            <OfficialQueueSummary items={items} />

            {/* Queue Table */}
            <OfficialQueueTable items={items} />
          </div>
        )}
      </main>
    </div>
  );
}
