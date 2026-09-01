import { Link } from 'react-router-dom';
import { Activity, ArrowRight, CheckCircle, AlertCircle, HelpCircle } from 'lucide-react';
import { Card, CardHeader, CardTitle, CardContent } from '@/components/ui/Card';
import { Badge } from '@/components/ui/Badge';
import { Skeleton } from '@/components/ui/Skeleton';
import { ErrorState } from '@/components/feedback/ErrorState';
import { formatTargetLabel } from '@/lib/utils/formatters';
import { useOfficialAccuracy } from '../hooks';

export function AccuracyPreview() {
  const { data, isLoading, isError, error, refetch } = useOfficialAccuracy();

  if (isLoading) {
    return (
      <Card className="rounded-2xl border border-bhoomi-border bg-bhoomi-surface shadow-card overflow-hidden h-full flex flex-col justify-between">
        <CardHeader className="pb-3 border-b border-bhoomi-border/70 bg-bhoomi-canvas/40">
          <Skeleton className="h-5 w-44 rounded-lg" />
          <Skeleton className="h-3.5 w-60 rounded-md mt-1.5" />
        </CardHeader>
        <CardContent className="pt-4 space-y-4 flex-1">
          <div className="grid grid-cols-2 gap-3">
            <Skeleton className="h-16 rounded-xl" />
            <Skeleton className="h-16 rounded-xl" />
          </div>
          <div className="space-y-2 pt-2">
            <Skeleton className="h-4 rounded-md w-3/4" />
            <Skeleton className="h-4 rounded-md w-1/2" />
          </div>
        </CardContent>
      </Card>
    );
  }

  if (isError) {
    return (
      <Card className="rounded-2xl border border-red-200 bg-red-50/30 shadow-card overflow-hidden h-full">
        <CardHeader className="pb-2 border-b border-red-100">
          <CardTitle className="text-base font-semibold text-bhoomi-text-primary flex items-center gap-2">
            <Activity className="h-4 w-4 text-red-600" />
            <span>Model Accuracy</span>
          </CardTitle>
        </CardHeader>
        <CardContent className="pt-4">
          <ErrorState
            error={error}
            title="Failed to Load Model Accuracy"
            onRetry={() => refetch()}
          />
        </CardContent>
      </Card>
    );
  }

  const rows = data?.by_label || [];
  const windowFrom = data?.window?.from;
  const windowTo = data?.window?.to;

  const totalConfirmed = rows.reduce((sum, r) => sum + r.confirmed, 0);
  const totalCorrected = rows.reduce((sum, r) => sum + r.corrected, 0);

  return (
    <Card className="rounded-2xl border border-bhoomi-border bg-bhoomi-surface shadow-card overflow-hidden h-full flex flex-col justify-between hover:border-bhoomi-primary/40 transition-all duration-200">
      <div>
        <CardHeader className="pb-3 border-b border-bhoomi-border/70 bg-bhoomi-canvas/40">
          <div className="flex items-center justify-between gap-2">
            <div className="flex items-center gap-2.5">
              <div className="flex h-8 w-8 items-center justify-center rounded-xl bg-blue-100 text-blue-700 border border-blue-200">
                <Activity className="h-4 w-4" />
              </div>
              <div>
                <CardTitle className="text-base font-bold text-bhoomi-text-primary">
                  Model Diagnostic Accuracy
                </CardTitle>
                <p className="text-xs text-bhoomi-text-muted">
                  Agronomist field confirmations vs. corrections
                </p>
              </div>
            </div>
            {windowFrom && windowTo && (
              <Badge variant="neutral" size="sm" className="text-[11px] font-mono text-bhoomi-text-muted">
                {windowFrom} → {windowTo}
              </Badge>
            )}
          </div>
        </CardHeader>

        <CardContent className="pt-4 space-y-4">
          {rows.length === 0 ? (
            <div className="rounded-xl border border-dashed border-bhoomi-border p-6 text-center text-xs text-bhoomi-text-secondary space-y-2 bg-bhoomi-canvas/40">
              <HelpCircle className="h-6 w-6 text-blue-500 mx-auto" />
              <p className="font-semibold text-bhoomi-text-primary">No Accuracy Records</p>
              <p className="text-[11px] text-bhoomi-text-muted">
                No reviewed cases available in the current surveillance window.
              </p>
            </div>
          ) : (
            <>
              {/* Confirmed vs Corrected Summary */}
              <div className="grid grid-cols-2 gap-3">
                <div className="rounded-xl border border-bhoomi-primary/20 bg-bhoomi-primary-soft p-3.5 shadow-xs">
                  <div className="flex items-center gap-1.5 text-xs text-bhoomi-primary font-bold">
                    <CheckCircle className="h-3.5 w-3.5" />
                    <span>Confirmed</span>
                  </div>
                  <p className="mt-1 text-2xl font-bold font-mono text-bhoomi-primary-dark">
                    {totalConfirmed}
                  </p>
                </div>
                <div className="rounded-xl border border-amber-300 bg-amber-50/60 p-3.5 shadow-xs">
                  <div className="flex items-center gap-1.5 text-xs text-amber-800 font-bold">
                    <AlertCircle className="h-3.5 w-3.5 text-amber-700" />
                    <span>Corrected</span>
                  </div>
                  <p className="mt-1 text-2xl font-bold font-mono text-amber-900">
                    {totalCorrected}
                  </p>
                </div>
              </div>

              {/* Per-Label Accuracy List */}
              <div className="space-y-2">
                <p className="text-xs font-bold text-bhoomi-text-secondary uppercase tracking-wider">
                  Performance by Crop Disease
                </p>
                <div className="space-y-2">
                  {rows.slice(0, 3).map((row) => (
                    <div
                      key={row.label}
                      className="rounded-xl border border-bhoomi-border bg-bhoomi-canvas p-2.5 text-xs space-y-1.5 shadow-xs"
                    >
                      <div className="flex items-center justify-between font-semibold">
                        <span className="text-bhoomi-text-primary">
                          {formatTargetLabel(row.label)}
                        </span>
                        <span className="font-mono font-bold text-bhoomi-primary">
                          {row.accuracy !== null ? `${Math.round(row.accuracy * 100)}%` : 'N/A'}
                        </span>
                      </div>
                      <div className="flex items-center justify-between text-[11px] text-bhoomi-text-muted">
                        <span>{row.confirmed} confirmed · {row.corrected} corrected</span>
                        <div className="h-1.5 w-20 rounded-full bg-bhoomi-border overflow-hidden">
                          <div
                            className="h-full bg-bhoomi-primary rounded-full transition-all duration-300"
                            style={{ width: `${row.accuracy !== null ? Math.round(row.accuracy * 100) : 0}%` }}
                          />
                        </div>
                      </div>
                    </div>
                  ))}
                </div>
              </div>
            </>
          )}
        </CardContent>
      </div>

      <div className="p-4 pt-0">
        <Link
          to="/official/accuracy"
          className="inline-flex w-full items-center justify-center gap-2 rounded-xl border border-bhoomi-border bg-bhoomi-canvas px-3 py-2.5 text-xs font-semibold text-bhoomi-text-primary hover:bg-bhoomi-primary-light hover:text-bhoomi-primary hover:border-bhoomi-primary/30 transition-colors shadow-xs"
        >
          <span>View Full Accuracy Report</span>
          <ArrowRight className="h-3.5 w-3.5" />
        </Link>
      </div>
    </Card>
  );
}
