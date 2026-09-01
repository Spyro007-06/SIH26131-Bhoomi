import { useQueryClient } from '@tanstack/react-query';
import { RefreshCw, AlertCircle, HelpCircle, Activity, ShieldCheck } from 'lucide-react';
import { Button } from '@/components/ui/Button';
import { Skeleton } from '@/components/ui/Skeleton';
import { Card } from '@/components/ui/Card';
import { Badge } from '@/components/ui/Badge';
import { AccuracySummary } from '../components/AccuracySummary';
import { ConfirmedCorrectedChart } from '../components/ConfirmedCorrectedChart';
import { AccuracyByLabelTable } from '../components/AccuracyByLabelTable';
import { AccuracyExplanation } from '../components/AccuracyExplanation';
import { officialKeys, useOfficialAccuracy } from '../hooks';

export function OfficialsAccuracyPage() {
  const queryClient = useQueryClient();
  const { data, isLoading, isError, error, refetch, isFetching } = useOfficialAccuracy();

  const handleRefresh = () => {
    queryClient.invalidateQueries({ queryKey: officialKeys.accuracy() });
  };

  const rows = data?.by_label || [];

  return (
    <div className="space-y-6 max-w-7xl mx-auto pb-20">
      {/* Header Bar */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 border-b border-bhoomi-border pb-5">
        <div>
          <div className="flex items-center gap-2.5">
            <h1 className="text-2xl font-bold tracking-tight text-bhoomi-text-primary">
              Model Validation
            </h1>
            <Badge variant="primary" size="sm" className="hidden sm:inline-flex gap-1">
              <ShieldCheck className="h-3.5 w-3.5" />
              <span>Official Diagnostics</span>
            </Badge>
          </div>
          <p className="text-xs text-bhoomi-text-secondary mt-1">
            Official view of model outcomes after agronomist review and field validation.
          </p>
        </div>

        <div className="flex items-center gap-3">
          <div className="flex items-center gap-1.5 text-xs text-bhoomi-primary bg-bhoomi-primary-light px-3 py-1.5 rounded-full border border-bhoomi-primary/20">
            <Activity className="h-3.5 w-3.5 text-bhoomi-primary animate-pulse" />
            <span className="font-semibold">Validation Feed Active</span>
          </div>

          <Button
            type="button"
            variant="outline"
            size="sm"
            onClick={handleRefresh}
            disabled={isFetching}
            className="gap-2 text-xs"
            aria-label="Refresh accuracy data"
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
              <Skeleton className="h-6 w-56 mb-4 rounded-lg" />
              <Skeleton className="h-[320px] w-full rounded-xl" />
            </Card>
            <Card className="p-6 rounded-2xl border border-bhoomi-border bg-bhoomi-surface shadow-card">
              <Skeleton className="h-6 w-48 mb-4 rounded-lg" />
              <div className="space-y-3">
                {[1, 2, 3].map((i) => (
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
                Unable to load validation analytics.
              </h3>
              <p className="text-xs text-bhoomi-text-muted max-w-md mx-auto">
                Validation analytics are temporarily unavailable.
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
        {!isLoading && !isError && rows.length === 0 && (
          <Card className="rounded-2xl border border-dashed border-bhoomi-border bg-bhoomi-surface p-12 text-center space-y-4 shadow-card">
            <div className="mx-auto flex h-14 w-14 items-center justify-center rounded-2xl bg-blue-50 border border-blue-200 text-blue-600">
              <HelpCircle className="h-7 w-7" />
            </div>
            <div className="space-y-1">
              <h3 className="text-base font-bold text-bhoomi-text-primary">
                No validation data available yet.
              </h3>
              <p className="text-xs text-bhoomi-text-muted max-w-md mx-auto">
                No agronomist review outcomes have been recorded in the current surveillance window. Records will appear here as field cases are verified.
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

        {/* Data Presentation */}
        {!isLoading && !isError && rows.length > 0 && (
          <div className="space-y-6">
            {/* 1. Summary Cards */}
            <AccuracySummary rows={rows} window={data?.window} />

            {/* 2. Visual Comparison Chart */}
            <ConfirmedCorrectedChart rows={rows} />

            {/* 3. Detailed Breakdown Table */}
            <AccuracyByLabelTable rows={rows} />

            {/* 4. Official Context & Explanations */}
            <AccuracyExplanation />
          </div>
        )}
      </main>
    </div>
  );
}
