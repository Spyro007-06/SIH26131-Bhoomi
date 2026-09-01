import { Link } from 'react-router-dom';
import { Activity, ArrowRight, CheckCircle, AlertCircle, HelpCircle } from 'lucide-react';
import { Card, CardHeader, CardTitle, CardContent } from '@/components/ui/Card';
import { Badge } from '@/components/ui/Badge';
import { ErrorState } from '@/components/feedback/ErrorState';
import { formatTargetLabel } from '@/lib/utils/formatters';
import { useOfficialAccuracy } from '../hooks';

export function AccuracyPreview() {
  const { data, isLoading, isError, error, refetch } = useOfficialAccuracy();

  if (isLoading) {
    return (
      <Card className="h-full flex flex-col justify-between animate-pulse">
        <CardHeader className="pb-3 border-b border-bhoomi-border/60">
          <div className="h-5 w-44 bg-bhoomi-surface-soft rounded" />
          <div className="h-3.5 w-60 bg-bhoomi-surface-soft rounded mt-1.5" />
        </CardHeader>
        <CardContent className="pt-4 space-y-4 flex-1">
          <div className="grid grid-cols-2 gap-3">
            <div className="h-16 bg-bhoomi-surface-soft rounded-lg" />
            <div className="h-16 bg-bhoomi-surface-soft rounded-lg" />
          </div>
          <div className="space-y-2 pt-2">
            <div className="h-4 bg-bhoomi-surface-soft rounded w-3/4" />
            <div className="h-4 bg-bhoomi-surface-soft rounded w-1/2" />
          </div>
        </CardContent>
      </Card>
    );
  }

  if (isError) {
    return (
      <Card className="h-full border-red-200 bg-red-50/30">
        <CardHeader className="pb-2">
          <CardTitle className="text-base font-semibold text-bhoomi-text flex items-center gap-2">
            <Activity className="h-4 w-4 text-bhoomi-danger" />
            Model Accuracy
          </CardTitle>
        </CardHeader>
        <CardContent>
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
    <Card className="h-full flex flex-col justify-between shadow-sm hover:border-bhoomi-green-600/40 transition-colors">
      <div>
        <CardHeader className="pb-3 border-b border-bhoomi-border/60">
          <div className="flex items-center justify-between gap-2">
            <div className="flex items-center gap-2">
              <div className="flex h-8 w-8 items-center justify-center rounded-lg bg-blue-100 text-blue-700">
                <Activity className="h-4 w-4" />
              </div>
              <div>
                <CardTitle className="text-base font-bold text-bhoomi-text">
                  Model Diagnostic Accuracy
                </CardTitle>
                <p className="text-xs text-bhoomi-text-secondary">
                  Agronomist field confirmations vs. model corrections
                </p>
              </div>
            </div>
            {windowFrom && windowTo && (
              <Badge variant="outline" size="sm" className="text-[11px] font-mono text-bhoomi-text-secondary">
                {windowFrom} → {windowTo}
              </Badge>
            )}
          </div>
        </CardHeader>

        <CardContent className="pt-4 space-y-4">
          {rows.length === 0 ? (
            <div className="rounded-xl border border-dashed border-bhoomi-border p-6 text-center text-xs text-bhoomi-text-secondary space-y-2">
              <HelpCircle className="h-6 w-6 text-blue-500 mx-auto" />
              <p className="font-medium text-bhoomi-text">No Accuracy Records</p>
              <p className="text-[11px]">
                No reviewed cases available in the current surveillance window.
              </p>
            </div>
          ) : (
            <>
              {/* Confirmed vs Corrected Summary */}
              <div className="grid grid-cols-2 gap-3">
                <div className="rounded-xl border border-bhoomi-green-600/30 bg-bhoomi-green-50/50 p-3">
                  <div className="flex items-center gap-1.5 text-xs text-bhoomi-green-800 font-medium">
                    <CheckCircle className="h-3.5 w-3.5" />
                    <span>Confirmed</span>
                  </div>
                  <p className="mt-1 text-2xl font-bold font-mono text-bhoomi-green-900">
                    {totalConfirmed}
                  </p>
                </div>
                <div className="rounded-xl border border-amber-500/30 bg-amber-50/50 p-3">
                  <div className="flex items-center gap-1.5 text-xs text-amber-800 font-medium">
                    <AlertCircle className="h-3.5 w-3.5" />
                    <span>Corrected</span>
                  </div>
                  <p className="mt-1 text-2xl font-bold font-mono text-amber-900">
                    {totalCorrected}
                  </p>
                </div>
              </div>

              {/* Per-Label Accuracy List */}
              <div className="space-y-2">
                <p className="text-xs font-semibold text-bhoomi-text">
                  Performance by Crop Disease
                </p>
                <div className="space-y-1.5">
                  {rows.slice(0, 3).map((row) => (
                    <div
                      key={row.label}
                      className="rounded-lg border border-bhoomi-border bg-bhoomi-surface-soft/60 p-2.5 text-xs space-y-1.5"
                    >
                      <div className="flex items-center justify-between font-medium">
                        <span className="text-bhoomi-text">
                          {formatTargetLabel(row.label)}
                        </span>
                        <span className="font-mono font-bold text-bhoomi-green-900">
                          {row.accuracy !== null ? `${Math.round(row.accuracy * 100)}%` : 'N/A'}
                        </span>
                      </div>
                      <div className="flex items-center justify-between text-[11px] text-bhoomi-text-secondary">
                        <span>{row.confirmed} confirmed · {row.corrected} corrected</span>
                        <div className="h-1.5 w-20 rounded-full bg-bhoomi-border overflow-hidden">
                          <div
                            className="h-full bg-bhoomi-green-600 rounded-full"
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
          className="inline-flex w-full items-center justify-center gap-2 rounded-lg border border-bhoomi-border bg-bhoomi-surface-soft/80 px-3 py-2 text-xs font-semibold text-bhoomi-text hover:bg-bhoomi-surface-soft hover:text-bhoomi-green-900 transition-colors shadow-xs"
        >
          <span>View Full Accuracy Report</span>
          <ArrowRight className="h-3.5 w-3.5" />
        </Link>
      </div>
    </Card>
  );
}
