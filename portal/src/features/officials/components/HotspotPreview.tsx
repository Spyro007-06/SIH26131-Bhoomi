import { Link } from 'react-router-dom';
import { MapPin, ArrowRight, ShieldCheck, AlertTriangle } from 'lucide-react';
import { Card, CardHeader, CardTitle, CardContent } from '@/components/ui/Card';
import { Badge } from '@/components/ui/Badge';
import { ErrorState } from '@/components/feedback/ErrorState';
import { formatTargetLabel } from '@/lib/utils/formatters';
import { useOfficialHotspots } from '../hooks';

export function HotspotPreview() {
  const { data, isLoading, isError, error, refetch } = useOfficialHotspots();

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
            <MapPin className="h-4 w-4 text-bhoomi-danger" />
            Outbreak Hotspots
          </CardTitle>
        </CardHeader>
        <CardContent>
          <ErrorState
            error={error}
            title="Failed to Load Hotspots"
            onRetry={() => refetch()}
          />
        </CardContent>
      </Card>
    );
  }

  const points = data?.points || [];
  const totalsByLabel = data?.totals_by_label || {};
  const totalOutbreaks = Object.values(totalsByLabel).reduce((sum, count) => sum + count, 0);

  return (
    <Card className="h-full flex flex-col justify-between shadow-sm hover:border-bhoomi-green-600/40 transition-colors">
      <div>
        <CardHeader className="pb-3 border-b border-bhoomi-border/60">
          <div className="flex items-center justify-between gap-2">
            <div className="flex items-center gap-2">
              <div className="flex h-8 w-8 items-center justify-center rounded-lg bg-red-100 text-red-700">
                <MapPin className="h-4 w-4" />
              </div>
              <div>
                <CardTitle className="text-base font-bold text-bhoomi-text">
                  Confirmed Outbreak Hotspots
                </CardTitle>
                <p className="text-xs text-bhoomi-text-secondary">
                  Live geospatial disease surveillance across Maharashtra
                </p>
              </div>
            </div>
            <Badge variant="primary" size="sm" className="gap-1 bg-bhoomi-green-100 text-bhoomi-green-900 border-bhoomi-green-500/30 text-[11px]">
              <ShieldCheck className="h-3 w-3 text-bhoomi-green-700" />
              Confirmed Only
            </Badge>
          </div>
        </CardHeader>

        <CardContent className="pt-4 space-y-4">
          {points.length === 0 ? (
            <div className="rounded-xl border border-dashed border-bhoomi-border p-6 text-center text-xs text-bhoomi-text-secondary space-y-2">
              <AlertTriangle className="h-6 w-6 text-amber-500 mx-auto" />
              <p className="font-medium text-bhoomi-text">No Confirmed Outbreak Hotspots</p>
              <p className="text-[11px]">
                No active confirmed outbreaks match the surveillance window.
              </p>
            </div>
          ) : (
            <>
              {/* Aggregate Key Stats */}
              <div className="grid grid-cols-2 gap-3">
                <div className="rounded-xl border border-bhoomi-border bg-bhoomi-surface-soft/60 p-3">
                  <p className="text-[11px] font-medium text-bhoomi-text-secondary uppercase tracking-wider">
                    Outbreak Clusters
                  </p>
                  <p className="mt-1 text-2xl font-bold font-mono text-bhoomi-text">
                    {points.length}
                  </p>
                </div>
                <div className="rounded-xl border border-red-200/80 bg-red-50/50 p-3">
                  <p className="text-[11px] font-medium text-red-800 uppercase tracking-wider">
                    Confirmed Cases
                  </p>
                  <p className="mt-1 text-2xl font-bold font-mono text-red-900">
                    {totalOutbreaks}
                  </p>
                </div>
              </div>

              {/* Disease Breakdown */}
              <div className="space-y-2">
                <p className="text-xs font-semibold text-bhoomi-text">
                  Active Disease Outbreaks
                </p>
                <div className="flex flex-wrap gap-1.5">
                  {Object.entries(totalsByLabel).map(([label, count]) => (
                    <span
                      key={label}
                      className="inline-flex items-center gap-1.5 rounded-md border border-bhoomi-border bg-bhoomi-surface-soft px-2.5 py-1 text-xs text-bhoomi-text font-medium"
                    >
                      <span>{formatTargetLabel(label)}:</span>
                      <span className="font-bold font-mono text-bhoomi-green-900 bg-bhoomi-green-100 px-1.5 py-0.2 rounded text-[11px]">
                        {count}
                      </span>
                    </span>
                  ))}
                </div>
              </div>
            </>
          )}
        </CardContent>
      </div>

      <div className="p-4 pt-0">
        <Link
          to="/official/hotspots"
          className="inline-flex w-full items-center justify-center gap-2 rounded-lg border border-bhoomi-border bg-bhoomi-surface-soft/80 px-3 py-2 text-xs font-semibold text-bhoomi-text hover:bg-bhoomi-surface-soft hover:text-bhoomi-green-900 transition-colors shadow-xs"
        >
          <span>View Hotspots Map</span>
          <ArrowRight className="h-3.5 w-3.5" />
        </Link>
      </div>
    </Card>
  );
}
