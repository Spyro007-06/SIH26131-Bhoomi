import { ReactNode } from 'react';
import { cn } from '@/lib/utils/cn';

export interface PageContainerProps {
  title: string;
  subtitle?: string;
  actions?: ReactNode;
  children: ReactNode;
  className?: string;
}

export function PageContainer({
  title,
  subtitle,
  actions,
  children,
  className,
}: PageContainerProps) {
  return (
    <div className={cn('flex-1 p-8 max-w-7xl mx-auto w-full space-y-6', className)}>
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4 border-b border-bhoomi-border/60 pb-5">
        <div>
          <h1 className="text-2xl font-bold tracking-tight text-bhoomi-text">{title}</h1>
          {subtitle && <p className="mt-1 text-sm text-bhoomi-text-secondary">{subtitle}</p>}
        </div>
        {actions && <div className="flex items-center gap-3">{actions}</div>}
      </div>
      <main>{children}</main>
    </div>
  );
}
