import { useQueryClient } from '@tanstack/react-query';
import { RefreshCw } from 'lucide-react';
import { Button } from '@/components/ui/Button';
import { DashboardHeader } from '../components/DashboardHeader';
import { OfficialHotspotMap } from '../components/OfficialHotspotMap';
import { officialKeys, useOfficialHotspots } from '../hooks';

export function OfficialsHotspotsPage() {
  const queryClient = useQueryClient();
  const { data } = useOfficialHotspots();

  const handleRefresh = () => {
    queryClient.invalidateQueries({ queryKey: officialKeys.hotspots() });
  };

  // Derive total active regions and total confirmed cases for the summary
  const points = data?.points || [];
  const totalConfirmed = points.reduce((acc, p) => acc + p.confirmed_count, 0);

  return (
    <div className="flex-1 flex flex-col h-full overflow-hidden bg-bhoomi-surface">
      <div className="flex items-start justify-between p-4 md:p-6 lg:p-8 pb-0">
        <DashboardHeader 
          title="Confirmed Hotspots" 
          subtitle="Geographic view of confirmed agricultural outbreak intelligence."
        />
        
        <Button 
          variant="outline" 
          size="sm" 
          onClick={handleRefresh}
          className="gap-2 bg-white text-bhoomi-text-secondary shadow-sm hidden sm:flex"
          aria-label="Refresh hotspot data"
        >
          <RefreshCw className="h-4 w-4" />
          Refresh
        </Button>
      </div>

      <main className="flex-1 p-4 md:p-6 lg:p-8 pt-6 max-w-7xl w-full mx-auto overflow-y-auto space-y-6 pb-24">
        {points.length > 0 && (
          <div className="grid grid-cols-2 md:grid-cols-4 gap-4 mb-4">
            <div className="bg-white p-4 rounded-xl border border-bhoomi-border shadow-sm">
              <span className="block text-xs font-medium text-bhoomi-text-tertiary uppercase tracking-wider mb-1">
                Active Clusters
              </span>
              <span className="text-2xl font-semibold text-bhoomi-text">
                {points.length}
              </span>
            </div>
            <div className="bg-white p-4 rounded-xl border border-bhoomi-border shadow-sm">
              <span className="block text-xs font-medium text-bhoomi-text-tertiary uppercase tracking-wider mb-1">
                Confirmed Cases
              </span>
              <span className="text-2xl font-semibold text-bhoomi-text">
                {totalConfirmed}
              </span>
            </div>
          </div>
        )}

        <OfficialHotspotMap />
      </main>
    </div>
  );
}
