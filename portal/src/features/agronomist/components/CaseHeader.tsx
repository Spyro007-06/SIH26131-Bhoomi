import { Link } from 'react-router-dom';
import { ArrowLeft, Clock, Zap } from 'lucide-react';
import { Badge } from '@/components/ui/Badge';
import { formatDateTime } from '@/lib/utils/formatters';
import { CaseStatus } from '@/types/api';

interface CaseHeaderProps {
  caseId: string;
  status: CaseStatus;
  openedAt?: string;
  isResolved?: boolean;
}

export function CaseHeader({ caseId, status, openedAt, isResolved }: CaseHeaderProps) {
  const currentStatus = isResolved ? 'resolved' : status;

  return (
    <div className="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between border-b border-bhoomi-border pb-4">
      <div className="flex flex-col gap-1.5">
        <Link
          to="/agronomist/cases"
          className="inline-flex items-center gap-1.5 text-xs font-medium text-bhoomi-primary hover:text-bhoomi-primary-dark transition-colors w-fit focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-bhoomi-primary rounded px-1 -ml-1"
        >
          <ArrowLeft className="h-3.5 w-3.5" />
          <span>Back to Case Queue</span>
        </Link>

        <div className="flex flex-wrap items-center gap-3 mt-0.5">
          <h1 className="text-2xl font-bold tracking-tight text-bhoomi-text-primary flex items-center gap-2.5">
            <span>Case Workspace</span>
            <span className="font-mono text-sm font-semibold text-bhoomi-text-secondary bg-bhoomi-surface px-2.5 py-1 rounded-lg border border-bhoomi-border shadow-xs">
              {caseId}
            </span>
          </h1>

          <Badge
            variant={currentStatus === 'resolved' ? 'success' : 'warning'}
            size="sm"
            className="capitalize font-bold"
          >
            {currentStatus}
          </Badge>
        </div>
      </div>

      <div className="flex items-center gap-4 text-xs text-bhoomi-text-muted">
        <div className="hidden md:flex items-center gap-1.5 rounded-full border border-bhoomi-border bg-bhoomi-canvas px-3 py-1 text-xs">
          <Zap className="h-3.5 w-3.5 text-bhoomi-primary" />
          <span className="font-medium text-bhoomi-text-secondary">&lt; 3 Min Target</span>
        </div>

        {openedAt && (
          <div className="flex items-center gap-1.5">
            <Clock className="h-3.5 w-3.5 text-bhoomi-text-muted" />
            <span>Opened: {formatDateTime(openedAt)}</span>
          </div>
        )}
      </div>
    </div>
  );
}
