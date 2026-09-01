import { useState } from 'react';
import { useQueryClient, useIsFetching } from '@tanstack/react-query';
import { RefreshCw, ShieldCheck, Activity } from 'lucide-react';
import { Button } from '@/components/ui/Button';
import { Badge } from '@/components/ui/Badge';
import { officialKeys } from '../hooks';

export interface DashboardHeaderProps {
  title?: string;
  subtitle?: string;
}

export function DashboardHeader({ title, subtitle }: DashboardHeaderProps) {
  const queryClient = useQueryClient();
  const isFetching = useIsFetching({ queryKey: officialKeys.all }) > 0;
  const [isManualRefreshing, setIsManualRefreshing] = useState(false);

  const handleRefresh = async () => {
    setIsManualRefreshing(true);
    try {
      await queryClient.invalidateQueries({ queryKey: officialKeys.all });
    } finally {
      setIsManualRefreshing(false);
    }
  };

  const isBusy = isFetching || isManualRefreshing;

  return (
    <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 border-b border-bhoomi-border pb-5">
      <div>
        <div className="flex items-center gap-2.5">
          <h1 className="text-2xl font-bold tracking-tight text-bhoomi-text">
            {title || 'Official Surveillance Dashboard'}
          </h1>
          <Badge variant="primary" size="sm" className="hidden sm:inline-flex gap-1 bg-bhoomi-green-100 text-bhoomi-green-900 border-bhoomi-green-500/30">
            <ShieldCheck className="h-3.5 w-3.5 text-bhoomi-green-700" />
            Confirmed Operations
          </Badge>
        </div>
        <p className="text-xs text-bhoomi-text-secondary mt-1">
          {subtitle || 'Real-time statewide outbreak surveillance, model diagnostic accuracy, and queue monitoring.'}
        </p>
      </div>

      <div className="flex items-center gap-3">
        <div className="flex items-center gap-1.5 text-xs text-bhoomi-text-secondary bg-bhoomi-surface-soft px-2.5 py-1.5 rounded-lg border border-bhoomi-border">
          <Activity className="h-3.5 w-3.5 text-bhoomi-green-600 animate-pulse" />
          <span className="font-medium text-bhoomi-text">Surveillance Active</span>
        </div>

        <Button
          type="button"
          variant="outline"
          size="sm"
          onClick={handleRefresh}
          disabled={isBusy}
          className="gap-1.5 text-xs"
          aria-label="Refresh dashboard data"
        >
          <RefreshCw className={`h-3.5 w-3.5 ${isBusy ? 'animate-spin text-bhoomi-green-700' : ''}`} />
          <span>{isBusy ? 'Refreshing...' : 'Refresh'}</span>
        </Button>
      </div>
    </div>
  );
}
