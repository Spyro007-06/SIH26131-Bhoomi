import { Link } from 'react-router-dom';
import { MapPin, ArrowRight, ShieldCheck, AlertTriangle } from 'lucide-react';
import { Card, CardHeader, CardTitle, CardContent } from '@/components/ui/Card';
import { Badge } from '@/components/ui/Badge';
import { Skeleton } from '@/components/ui/Skeleton';
import { ErrorState } from '@/components/feedback/ErrorState';
import { formatTargetLabel } from '@/lib/utils/formatters';
import { useOfficialHotspots } from '../hooks';

export function HotspotPreview() {
  const { data, isLoading, isError, error, refetch } = useOfficialHotspots();

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
            <MapPin className="h-4 w-4 text-red-600" />
            <span>Outbreak Hotspots</span>
          </CardTitle>
        </CardHeader>
        <CardContent className="pt-4">
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
    <Card className="rounded-2xl border border-bhoomi-border bg-bhoomi-surface shadow-card overflow-hidden h-full flex flex-col justify-between hover:border-bhoomi-primary/40 transition-all duration-200">
      <div>
        <CardHeader className="pb-3 border-b border-bhoomi-border/70 bg-bhoomi-canvas/40">
          <div className="flex items-center justify-between gap-2">
            <div className="flex items-center gap-2.5">
              <div className="flex h-8 w-8 items-center justify-center rounded-xl bg-red-100 text-red-700 border border-red-200">
                <MapPin className="h-4 w-4" />
              </div>
              <div>
                <CardTitle className="text-base font-bold text-bhoomi-text-primary">
                  Confirmed Outbreak Hotspots
                </CardTitle>
                <p className="text-xs text-bhoomi-text-muted">
                  Live geospatial disease surveillance across Maharashtra
                </p>
              </div>
            </div>
            <Badge variant="primary" size="sm" className="gap-1 text-[11px]">
              <ShieldCheck className="h-3 w-3" />
              <span>Confirmed Only</span>
            </Badge>
          </div>
        </CardHeader>

        <CardContent className="pt-4 space-y-4">
          {points.length === 0 ? (
            <div className="rounded-xl border border-dashed border-bhoomi-border p-6 text-center text-xs text-bhoomi-text-secondary space-y-2 bg-bhoomi-canvas/40">
              <AlertTriangle className="h-6 w-6 text-amber-500 mx-auto" />
              <p className="font-semibold text-bhoomi-text-primary">No Confirmed Outbreak Hotspots</p>
              <p className="text-[11px] text-bhoomi-text-muted">
                No active confirmed outbreaks match the surveillance window.
              </p>
            </div>
          ) : (
            <>
              {/* Aggregate Key Stats */}
              <div className="grid grid-cols-2 gap-3">
                <div className="rounded-xl border border-bhoomi-border bg-bhoomi-canvas p-3.5 shadow-xs">
                  <p className="text-[11px] font-bold text-bhoomi-text-muted uppercase tracking-wider">
                    Outbreak Clusters
                  </p>
                  <p className="mt-1 text-2xl font-bold font-mono text-bhoomi-text-primary">
                    {points.length}
                  </p>
                </div>
                <div className="rounded-xl border border-red-200 bg-red-50/60 p-3.5 shadow-xs">
                  <p className="text-[11px] font-bold text-red-800 uppercase tracking-wider">
                    Confirmed Cases
                  </p>
                  <p className="mt-1 text-2xl font-bold font-mono text-red-900">
                    {totalOutbreaks}
                  </p>
                </div>
              </div>

              {/* Disease Breakdown */}
              <div className="space-y-2">
                <p className="text-xs font-bold text-bhoomi-text-secondary uppercase tracking-wider">
                  Active Disease Outbreaks
                </p>
                <div className="flex flex-wrap gap-1.5">
                  {Object.entries(totalsByLabel).map(([label, count]) => (
                    <span
                      key={label}
                      className="inline-flex items-center gap-1.5 rounded-lg border border-bhoomi-border bg-bhoomi-canvas px-2.5 py-1 text-xs text-bhoomi-text-primary font-medium shadow-xs"
                    >
                      <span>{formatTargetLabel(label)}:</span>
                      <span className="font-bold font-mono text-bhoomi-primary bg-bhoomi-primary-light px-1.5 py-0.5 rounded text-[11px] border border-bhoomi-primary/20">
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
          className="inline-flex w-full items-center justify-center gap-2 rounded-xl border border-bhoomi-border bg-bhoomi-canvas px-3 py-2.5 text-xs font-semibold text-bhoomi-text-primary hover:bg-bhoomi-primary-light hover:text-bhoomi-primary hover:border-bhoomi-primary/30 transition-colors shadow-xs"
        >
          <span>View Hotspots Map</span>
          <ArrowRight className="h-3.5 w-3.5" />
        </Link>
      </div>
    </Card>
  );
}
