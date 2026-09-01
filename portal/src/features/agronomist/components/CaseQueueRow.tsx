import { useNavigate } from 'react-router-dom';
import { CaseQueueItem } from '@/types/api';
import { Badge } from '@/components/ui/Badge';
import { Button } from '@/components/ui/Button';
import { TableRow, TableCell } from '@/components/ui/Table';
import { formatTargetLabel, formatRelativeTime, formatShortId } from '@/lib/utils/formatters';
import { ArrowRight, Clock, MapPin, Sprout } from 'lucide-react';

export interface CaseQueueRowProps {
  item: CaseQueueItem;
}

export function CaseQueueRow({ item }: CaseQueueRowProps) {
  const navigate = useNavigate();

  const handleOpenCase = () => {
    navigate(`/agronomist/cases/${item.case_id}`);
  };

  const handleKeyDown = (e: React.KeyboardEvent<HTMLTableRowElement>) => {
    if (e.key === 'Enter' || e.key === ' ') {
      e.preventDefault();
      handleOpenCase();
    }
  };

  return (
    <TableRow
      tabIndex={0}
      onKeyDown={handleKeyDown}
      className="group cursor-pointer transition-all duration-150 hover:bg-bhoomi-canvas/90 hover:border-l-4 hover:border-bhoomi-primary focus:bg-bhoomi-primary-soft focus:outline-none select-none"
      onClick={handleOpenCase}
      aria-label={`Open case ${item.case_id}`}
    >
      {/* 1. Server-authoritative Queue Position */}
      <TableCell className="w-20 font-semibold text-bhoomi-text-primary">
        {item.queue_position !== null && item.queue_position !== undefined ? (
          <span className="inline-flex items-center justify-center px-2 py-0.5 rounded-lg bg-bhoomi-primary-light text-bhoomi-primary text-xs font-bold border border-bhoomi-primary/20 shadow-xs">
            #{item.queue_position}
          </span>
        ) : (
          <span className="text-bhoomi-text-muted text-xs">—</span>
        )}
      </TableCell>

      {/* 2. Case Identity */}
      <TableCell className="w-32">
        <span
          className="font-mono text-xs font-semibold text-bhoomi-text-primary group-hover:text-bhoomi-primary transition-colors"
          title={item.case_id}
        >
          {formatShortId(item.case_id)}
        </span>
      </TableCell>

      {/* 3. Target Problem & Crop */}
      <TableCell>
        <div className="flex items-center gap-2">
          <div className="flex h-7 w-7 shrink-0 items-center justify-center rounded-lg bg-bhoomi-primary-soft text-bhoomi-primary border border-bhoomi-border">
            <Sprout className="h-4 w-4" />
          </div>
          <div>
            <p className="text-sm font-semibold text-bhoomi-text-primary leading-tight">
              {formatTargetLabel(item.label)}
            </p>
            {item.eta_minutes !== null && item.eta_minutes !== undefined && (
              <p className="text-[11px] text-bhoomi-text-muted mt-0.5">
                Est. review: ~{item.eta_minutes}m
              </p>
            )}
          </div>
        </div>
      </TableCell>

      {/* 4. Region */}
      <TableCell className="w-36 text-sm text-bhoomi-text-secondary">
        <div className="flex items-center gap-1.5">
          <MapPin className="h-3.5 w-3.5 text-bhoomi-text-muted shrink-0" />
          <span className="truncate">{item.region || 'Maharashtra'}</span>
        </div>
      </TableCell>

      {/* 5. Status */}
      <TableCell className="w-28">
        <Badge
          variant={item.status === 'assigned' ? 'warning' : 'neutral'}
          size="sm"
          className="capitalize"
        >
          {item.status}
        </Badge>
      </TableCell>

      {/* 6. Arrival & Time Context */}
      <TableCell className="w-32 text-xs text-bhoomi-text-muted whitespace-nowrap">
        <span className="inline-flex items-center gap-1.5">
          <Clock className="h-3.5 w-3.5 text-bhoomi-text-muted" />
          <span>{formatRelativeTime(item.created_at)}</span>
        </span>
      </TableCell>

      {/* 7. Action Button */}
      <TableCell className="w-28 text-right">
        <Button
          size="sm"
          variant="ghost"
          onClick={(e) => {
            e.stopPropagation();
            handleOpenCase();
          }}
          className="gap-1.5 text-bhoomi-primary hover:text-bhoomi-primary-dark hover:bg-bhoomi-primary-light font-semibold text-xs"
          aria-label={`Review case ${item.case_id}`}
        >
          <span>Review</span>
          <ArrowRight className="h-3.5 w-3.5 transition-transform group-hover:translate-x-0.5" />
        </Button>
      </TableCell>
    </TableRow>
  );
}
