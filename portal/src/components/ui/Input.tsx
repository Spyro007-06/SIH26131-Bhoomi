import { InputHTMLAttributes, ReactNode, forwardRef, useId } from 'react';
import { cn } from '@/lib/utils/cn';

export interface InputProps extends InputHTMLAttributes<HTMLInputElement> {
  label?: string;
  error?: string;
  helperText?: string;
  icon?: ReactNode;
}

export const Input = forwardRef<HTMLInputElement, InputProps>(
  ({ className, type = 'text', label, error, helperText, icon, id, disabled, ...props }, ref) => {
    const generatedId = useId();
    const inputId = id || generatedId;
    const errorId = `${inputId}-error`;
    const helperId = `${inputId}-helper`;

    return (
      <div className="w-full space-y-1.5">
        {label && (
          <label
            htmlFor={inputId}
            className="block text-xs font-semibold uppercase tracking-wider text-bhoomi-text-secondary"
          >
            {label}
          </label>
        )}
        <div className="relative flex items-center">
          {icon && (
            <div className="pointer-events-none absolute left-3.5 flex items-center text-bhoomi-text-muted">
              {icon}
            </div>
          )}
          <input
            type={type}
            id={inputId}
            ref={ref}
            disabled={disabled}
            aria-invalid={!!error}
            aria-describedby={error ? errorId : helperText ? helperId : undefined}
            className={cn(
              'flex h-10 w-full rounded-xl border bg-bhoomi-surface px-3.5 py-2 text-sm text-bhoomi-text-primary placeholder:text-bhoomi-text-disabled focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-bhoomi-primary/20 focus-visible:border-bhoomi-primary disabled:cursor-not-allowed disabled:opacity-50 transition-colors shadow-xs',
              icon && 'pl-10',
              error
                ? 'border-bhoomi-danger focus-visible:ring-bhoomi-danger/20 focus-visible:border-bhoomi-danger'
                : 'border-bhoomi-border-strong hover:border-bhoomi-text-muted',
              className
            )}
            {...props}
          />
        </div>
        {error && (
          <p id={errorId} className="text-xs font-medium text-bhoomi-danger">
            {error}
          </p>
        )}
        {!error && helperText && (
          <p id={helperId} className="text-xs text-bhoomi-text-muted">
            {helperText}
          </p>
        )}
      </div>
    );
  }
);

Input.displayName = 'Input';
