import { useNavigate } from 'react-router-dom';
import { CaseQueueItem } from '@/types/api';
import { Badge } from '@/components/ui/Badge';
import { Button } from '@/components/ui/Button';
import { TableRow, TableCell } from '@/components/ui/Table';
import { formatTargetLabel, formatRelativeTime, formatShortId } from '@/lib/utils/formatters';
import { ArrowRight, Clock } from 'lucide-react';

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
      className="cursor-pointer hover:bg-bhoomi-surface-soft/60 focus:bg-bhoomi-surface-soft/80 focus:outline-none transition-colors"
      onClick={handleOpenCase}
      aria-label={`Open case ${item.case_id}`}
    >
      {/* 1. Server-authoritative Queue Position */}
      <TableCell className="font-semibold text-bhoomi-green-900 w-20">
        {item.queue_position !== null && item.queue_position !== undefined ? (
          <span className="inline-flex items-center justify-center px-2 py-0.5 rounded bg-bhoomi-surface-soft text-bhoomi-green-800 text-xs font-bold border border-bhoomi-green-200">
            #{item.queue_position}
          </span>
        ) : (
          <span className="text-bhoomi-text-secondary text-xs">—</span>
        )}
      </TableCell>

      {/* 2. Case Identity */}
      <TableCell className="font-mono text-xs text-bhoomi-text font-medium">
        <span title={item.case_id}>{formatShortId(item.case_id)}</span>
      </TableCell>

      {/* 3. Target Problem */}
      <TableCell>
        <span className="text-sm font-medium text-bhoomi-text">
          {formatTargetLabel(item.label)}
        </span>
      </TableCell>

      {/* 4. Region */}
      <TableCell className="text-sm text-bhoomi-text-secondary">
        {item.region || 'Maharashtra'}
      </TableCell>

      {/* 5. Status */}
      <TableCell>
        <Badge variant={item.status === 'assigned' ? 'success' : 'secondary'} className="capitalize">
          {item.status}
        </Badge>
      </TableCell>

      {/* 6. Arrival & Time Context */}
      <TableCell className="text-xs text-bhoomi-text-secondary whitespace-nowrap">
        <span className="inline-flex items-center gap-1">
          <Clock className="h-3.5 w-3.5 text-bhoomi-text-secondary/70" />
          {formatRelativeTime(item.created_at)}
        </span>
      </TableCell>

      {/* 7. Action */}
      <TableCell className="text-right">
        <Button
          size="sm"
          variant="ghost"
          onClick={(e) => {
            e.stopPropagation();
            handleOpenCase();
          }}
          className="gap-1 text-bhoomi-green-800 hover:text-bhoomi-green-900 hover:bg-bhoomi-green-100"
          aria-label={`Review case ${item.case_id}`}
        >
          <span>Review</span>
          <ArrowRight className="h-3.5 w-3.5" />
        </Button>
      </TableCell>
    </TableRow>
  );
}
