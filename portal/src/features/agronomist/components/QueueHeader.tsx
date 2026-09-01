import { Button } from '@/components/ui/Button';
import { Badge } from '@/components/ui/Badge';
import { RefreshCw } from 'lucide-react';

export interface QueueHeaderProps {
  onRefresh: () => void;
  isRefreshing: boolean;
  totalLoaded?: number;
}

export function QueueHeader({ onRefresh, isRefreshing }: QueueHeaderProps) {
  return (
    <div className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between pb-4 border-b border-bhoomi-border">
      <div className="space-y-1">
        <div className="flex items-center gap-3">
          <h1 className="text-2xl font-bold tracking-tight text-bhoomi-text">Case Queue</h1>
          <Badge variant="success" className="capitalize">
            Assigned
          </Badge>
        </div>
        <p className="text-sm text-bhoomi-text-secondary">
          Review cases requiring expert validation.
        </p>
      </div>

      <div className="flex items-center gap-3">
        <Button
          variant="outline"
          size="sm"
          onClick={onRefresh}
          disabled={isRefreshing}
          className="gap-2"
          aria-label="Refresh case queue"
        >
          <RefreshCw className={`h-4 w-4 ${isRefreshing ? 'animate-spin' : ''}`} />
          Refresh
        </Button>
      </div>
    </div>
  );
}
