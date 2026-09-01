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
          <h1 className="text-2xl font-bold tracking-tight text-bhoomi-text-primary">
            {title || 'Agriculture Officials Dashboard'}
          </h1>
          <Badge variant="primary" size="sm" className="hidden sm:inline-flex gap-1">
            <ShieldCheck className="h-3.5 w-3.5" />
            <span>Confirmed Operations</span>
          </Badge>
        </div>
        <p className="text-xs text-bhoomi-text-secondary mt-1">
          {subtitle || 'Real-time statewide outbreak surveillance, model diagnostic accuracy, and queue monitoring.'}
        </p>
      </div>

      <div className="flex items-center gap-3">
        <div className="flex items-center gap-1.5 text-xs text-bhoomi-primary bg-bhoomi-primary-light px-3 py-1.5 rounded-full border border-bhoomi-primary/20">
          <Activity className="h-3.5 w-3.5 text-bhoomi-primary animate-pulse" />
          <span className="font-semibold">Surveillance Active</span>
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
          <RefreshCw className={`h-3.5 w-3.5 ${isBusy ? 'animate-spin text-bhoomi-primary' : ''}`} />
          <span>{isBusy ? 'Refreshing...' : 'Refresh'}</span>
        </Button>
      </div>
    </div>
  );
}
