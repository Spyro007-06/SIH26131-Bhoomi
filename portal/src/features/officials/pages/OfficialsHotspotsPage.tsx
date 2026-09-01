import { useQueryClient } from '@tanstack/react-query';
import { RefreshCw, MapPin, ShieldCheck, Activity } from 'lucide-react';
import { Button } from '@/components/ui/Button';
import { Badge } from '@/components/ui/Badge';
import { Card } from '@/components/ui/Card';
import { OfficialHotspotMap } from '../components/OfficialHotspotMap';
import { officialKeys, useOfficialHotspots } from '../hooks';

export function OfficialsHotspotsPage() {
  const queryClient = useQueryClient();
  const { data, isFetching } = useOfficialHotspots();

  const handleRefresh = () => {
    queryClient.invalidateQueries({ queryKey: officialKeys.hotspots() });
  };

  const points = data?.points || [];
  const totalConfirmed = points.reduce((acc, p) => acc + p.confirmed_count, 0);

  return (
    <div className="space-y-6 max-w-7xl mx-auto pb-20">
      {/* Page Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 border-b border-bhoomi-border pb-5">
        <div>
          <div className="flex items-center gap-2.5">
            <h1 className="text-2xl font-bold tracking-tight text-bhoomi-text-primary">
              Confirmed Hotspots
            </h1>
            <Badge variant="primary" size="sm" className="hidden sm:inline-flex gap-1">
              <ShieldCheck className="h-3.5 w-3.5" />
              <span>Confirmed Only</span>
            </Badge>
          </div>
          <p className="text-xs text-bhoomi-text-secondary mt-1">
            Geographic view of confirmed agricultural outbreak intelligence across Maharashtra.
          </p>
        </div>

        <div className="flex items-center gap-3">
          <div className="flex items-center gap-1.5 text-xs text-bhoomi-primary bg-bhoomi-primary-light px-3 py-1.5 rounded-full border border-bhoomi-primary/20">
            <Activity className="h-3.5 w-3.5 text-bhoomi-primary animate-pulse" />
            <span className="font-semibold">Live Geospatial Feed</span>
          </div>

          <Button 
            type="button"
            variant="outline" 
            size="sm" 
            onClick={handleRefresh}
            disabled={isFetching}
            className="gap-2 text-xs"
            aria-label="Refresh hotspot data"
          >
            <RefreshCw className={`h-3.5 w-3.5 ${isFetching ? 'animate-spin text-bhoomi-primary' : ''}`} />
            <span>{isFetching ? 'Refreshing...' : 'Refresh'}</span>
          </Button>
        </div>
      </div>

      {/* Summary KPI Cards */}
      {points.length > 0 && (
        <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
          <Card className="p-4 rounded-2xl border border-bhoomi-border bg-bhoomi-surface shadow-card">
            <div className="flex items-center gap-2 text-bhoomi-text-muted mb-1">
              <MapPin className="h-4 w-4 text-bhoomi-primary" />
              <span className="text-xs font-bold uppercase tracking-wider">
                Active Clusters
              </span>
            </div>
            <span className="text-2xl font-bold font-mono text-bhoomi-text-primary">
              {points.length}
            </span>
          </Card>

          <Card className="p-4 rounded-2xl border border-red-200 bg-red-50/50 shadow-card">
            <div className="flex items-center gap-2 text-red-800 mb-1">
              <ShieldCheck className="h-4 w-4 text-red-600" />
              <span className="text-xs font-bold uppercase tracking-wider">
                Confirmed Cases
              </span>
            </div>
            <span className="text-2xl font-bold font-mono text-red-900">
              {totalConfirmed}
            </span>
          </Card>
        </div>
      )}

      {/* Main Map Container */}
      <OfficialHotspotMap />
    </div>
  );
}
