import { cn } from '@/lib/utils/cn';
import { Loader2 } from 'lucide-react';

export interface LoadingStateProps {
  message?: string;
  className?: string;
}

export function LoadingState({ message = 'Loading...', className }: LoadingStateProps) {
  return (
    <div
      className={cn(
        'flex flex-col items-center justify-center p-8 text-center min-h-[200px]',
        className
      )}
    >
      <Loader2 className="h-8 w-8 animate-spin text-bhoomi-primary" />
      {message && (
        <p className="mt-3 text-sm font-medium text-bhoomi-text-secondary">{message}</p>
      )}
    </div>
  );
}
