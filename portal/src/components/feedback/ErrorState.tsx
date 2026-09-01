import { cn } from '@/lib/utils/cn';
import { Button } from '@/components/ui/Button';
import { AlertCircle } from 'lucide-react';
import { isBhoomiApiError } from '@/lib/api/errors';

export interface ErrorStateProps {
  error: unknown;
  title?: string;
  onRetry?: () => void;
  className?: string;
}

export function ErrorState({
  error,
  title = 'Something went wrong',
  onRetry,
  className,
}: ErrorStateProps) {
  let errorMessage = 'An unexpected error occurred. Please try again.';
  let errorCode: string | undefined;

  if (isBhoomiApiError(error)) {
    errorMessage = error.message;
    errorCode = error.code;
  } else if (error instanceof Error) {
    errorMessage = error.message;
  }

  return (
    <div
      className={cn(
        'flex flex-col items-center justify-center p-8 text-center rounded-card border border-red-200 bg-red-50/50 min-h-[220px]',
        className
      )}
    >
      <div className="flex h-12 w-12 items-center justify-center rounded-full bg-red-100 text-bhoomi-danger mb-3">
        <AlertCircle className="h-6 w-6" />
      </div>
      <h3 className="text-base font-semibold text-bhoomi-text">{title}</h3>
      <p className="mt-1 text-sm text-bhoomi-text-secondary max-w-sm">{errorMessage}</p>
      {errorCode && (
        <span className="mt-2 inline-block rounded bg-red-100 px-2 py-0.5 font-mono text-xs text-bhoomi-danger font-medium">
          {errorCode}
        </span>
      )}
      {onRetry && (
        <div className="mt-4">
          <Button variant="secondary" size="sm" onClick={onRetry}>
            Retry Request
          </Button>
        </div>
      )}
    </div>
  );
}
