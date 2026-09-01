import { useQueryClient } from '@tanstack/react-query';
import { RefreshCw, AlertCircle, HelpCircle } from 'lucide-react';
import { Button } from '@/components/ui/Button';
import { Skeleton } from '@/components/ui/Skeleton';
import { Card } from '@/components/ui/Card';
import { DashboardHeader } from '../components/DashboardHeader';
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
    <div className="flex-1 flex flex-col h-full overflow-hidden bg-bhoomi-surface">
      {/* Header Bar */}
      <div className="flex items-start justify-between p-4 md:p-6 lg:p-8 pb-0">
        <DashboardHeader
          title="Model Validation"
          subtitle="Official view of model outcomes after agronomist review."
        />

        <Button
          variant="outline"
          size="sm"
          onClick={handleRefresh}
          disabled={isFetching}
          className="gap-2 bg-white text-bhoomi-text-secondary shadow-xs hover:bg-bhoomi-surface-soft hover:text-bhoomi-green-900 border-bhoomi-border hidden sm:flex"
          aria-label="Refresh accuracy data"
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
              <Skeleton className="h-6 w-56 mb-4" />
              <Skeleton className="h-[300px] w-full" />
            </Card>
            <Card className="p-6">
              <Skeleton className="h-6 w-48 mb-4" />
              <div className="space-y-3">
                {[1, 2, 3].map((i) => (
                  <Skeleton key={i} className="h-10 w-full" />
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
                Unable to load validation analytics.
              </h3>
              <p className="text-xs text-bhoomi-text-secondary max-w-md mx-auto">
                Validation analytics are temporarily unavailable.
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
        {!isLoading && !isError && rows.length === 0 && (
          <Card className="border-dashed border-bhoomi-border bg-white p-12 text-center space-y-4">
            <div className="mx-auto flex h-14 w-14 items-center justify-center rounded-full bg-blue-50 text-blue-600">
              <HelpCircle className="h-7 w-7" />
            </div>
            <div className="space-y-1">
              <h3 className="text-base font-bold text-bhoomi-text">
                No validation data available yet.
              </h3>
              <p className="text-xs text-bhoomi-text-secondary max-w-md mx-auto">
                No agronomist review outcomes have been recorded in the current surveillance window. Records will appear here as field cases are verified.
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

        {/* Data Presentation */}
        {!isLoading && !isError && rows.length > 0 && (
          <>
            {/* 1. Summary Cards */}
            <AccuracySummary rows={rows} window={data?.window} />

            {/* 2. Visual Comparison Chart */}
            <ConfirmedCorrectedChart rows={rows} />

            {/* 3. Detailed Breakdown Table */}
            <AccuracyByLabelTable rows={rows} />

            {/* 4. Official Context & Explanations */}
            <AccuracyExplanation />
          </>
        )}
      </main>
    </div>
  );
}
