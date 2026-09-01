import { Button } from '@/components/ui/Button';
import { Badge } from '@/components/ui/Badge';
import { Input } from '@/components/ui/Input';
import { RefreshCw, Search, Clock, Zap } from 'lucide-react';

export interface QueueHeaderProps {
  onRefresh: () => void;
  isRefreshing: boolean;
  totalLoaded?: number;
  searchQuery?: string;
  onSearchChange?: (query: string) => void;
}

export function QueueHeader({
  onRefresh,
  isRefreshing,
  totalLoaded = 0,
  searchQuery = '',
  onSearchChange,
}: QueueHeaderProps) {
  return (
    <div className="space-y-4">
      {/* Top Title & Metadata Bar */}
      <div className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between pb-4 border-b border-bhoomi-border">
        <div className="space-y-1">
          <div className="flex flex-wrap items-center gap-2.5">
            <h1 className="text-2xl font-bold tracking-tight text-bhoomi-text-primary">
              Case Queue
            </h1>
            <Badge variant="warning" className="capitalize">
              Assigned
            </Badge>
            {totalLoaded > 0 && (
              <Badge variant="primary" size="sm">
                {totalLoaded} {totalLoaded === 1 ? 'Case' : 'Cases'} Active
              </Badge>
            )}
          </div>
          <p className="text-sm text-bhoomi-text-secondary">
            Review escalated crop health cases requiring expert diagnostic validation.
          </p>
        </div>

        <div className="flex items-center gap-3">
          {/* SLA Performance Tag */}
          <div className="hidden md:flex items-center gap-1.5 rounded-full border border-bhoomi-border bg-bhoomi-canvas px-3 py-1 text-xs text-bhoomi-text-muted">
            <Zap className="h-3.5 w-3.5 text-bhoomi-primary" />
            <span className="font-medium text-bhoomi-text-secondary">&lt; 3 Min SLA Target</span>
          </div>

          <Button
            variant="outline"
            size="sm"
            onClick={onRefresh}
            disabled={isRefreshing}
            className="gap-2"
            aria-label="Refresh case queue"
          >
            <RefreshCw className={`h-3.5 w-3.5 ${isRefreshing ? 'animate-spin' : ''}`} />
            <span>Refresh</span>
          </Button>
        </div>
      </div>

      {/* Quick Search & Filter Utility */}
      {onSearchChange && (
        <div className="flex items-center justify-between gap-4">
          <div className="max-w-md w-full">
            <Input
              type="text"
              placeholder="Filter by Case ID, crop, or region..."
              value={searchQuery}
              onChange={(e) => onSearchChange(e.target.value)}
              icon={<Search className="h-4 w-4 text-bhoomi-text-muted" />}
              className="h-9 text-xs"
            />
          </div>

          <div className="hidden sm:flex items-center gap-2 text-xs text-bhoomi-text-muted">
            <Clock className="h-3.5 w-3.5" />
            <span>Sorted by server queue position</span>
          </div>
        </div>
      )}
    </div>
  );
}
