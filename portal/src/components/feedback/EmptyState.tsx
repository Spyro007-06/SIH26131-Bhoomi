import { ReactNode } from 'react';
import { cn } from '@/lib/utils/cn';
import { Inbox } from 'lucide-react';

export interface EmptyStateProps {
  icon?: ReactNode;
  title: string;
  description?: string;
  action?: ReactNode;
  className?: string;
}

export function EmptyState({
  icon,
  title,
  description,
  action,
  className,
}: EmptyStateProps) {
  return (
    <div
      className={cn(
        'flex flex-col items-center justify-center p-8 text-center rounded-card border border-dashed border-bhoomi-border bg-bhoomi-surface-soft/30 min-h-[220px]',
        className
      )}
    >
      <div className="flex h-12 w-12 items-center justify-center rounded-full bg-bhoomi-green-100 text-bhoomi-green-800 mb-3">
        {icon || <Inbox className="h-6 w-6" />}
      </div>
      <h3 className="text-base font-semibold text-bhoomi-text">{title}</h3>
      {description && (
        <p className="mt-1 text-sm text-bhoomi-text-secondary max-w-sm">{description}</p>
      )}
      {action && <div className="mt-4">{action}</div>}
    </div>
  );
}
