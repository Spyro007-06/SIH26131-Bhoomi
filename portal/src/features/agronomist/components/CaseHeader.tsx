import { Link } from 'react-router-dom';
import { ArrowLeft, Clock } from 'lucide-react';
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
      <div className="flex flex-col gap-1">
        <Link
          to="/agronomist/cases"
          className="inline-flex items-center gap-1.5 text-xs font-medium text-bhoomi-green-800 hover:text-bhoomi-green-900 transition-colors w-fit focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-bhoomi-green-600 rounded px-1 -ml-1"
        >
          <ArrowLeft className="h-3.5 w-3.5" />
          Back to Case Queue
        </Link>

        <div className="flex items-center gap-3 mt-1">
          <h1 className="text-2xl font-bold tracking-tight text-bhoomi-text flex items-center gap-2">
            <span>Case Workspace</span>
            <span className="font-mono text-lg font-semibold text-bhoomi-text-secondary bg-bhoomi-surface-soft px-2.5 py-0.5 rounded-md border border-bhoomi-border">
              {caseId}
            </span>
          </h1>

          <Badge
            variant={currentStatus === 'resolved' ? 'success' : 'warning'}
            className="capitalize text-xs font-semibold px-2.5 py-0.5"
          >
            {currentStatus}
          </Badge>
        </div>
      </div>

      {openedAt && (
        <div className="flex items-center gap-1.5 text-xs text-bhoomi-text-secondary">
          <Clock className="h-3.5 w-3.5 text-bhoomi-text-secondary/70" />
          <span>Opened: {formatDateTime(openedAt)}</span>
        </div>
      )}
    </div>
  );
}
