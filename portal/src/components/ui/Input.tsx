import { InputHTMLAttributes, forwardRef, useId } from 'react';
import { cn } from '@/lib/utils/cn';

export interface InputProps extends InputHTMLAttributes<HTMLInputElement> {
  label?: string;
  error?: string;
  helperText?: string;
}

export const Input = forwardRef<HTMLInputElement, InputProps>(
  ({ className, type = 'text', label, error, helperText, id, disabled, ...props }, ref) => {
    const generatedId = useId();
    const inputId = id || generatedId;
    const errorId = `${inputId}-error`;
    const helperId = `${inputId}-helper`;

    return (
      <div className="w-full space-y-1.5">
        {label && (
          <label htmlFor={inputId} className="block text-sm font-medium text-bhoomi-text">
            {label}
          </label>
        )}
        <input
          type={type}
          id={inputId}
          ref={ref}
          disabled={disabled}
          aria-invalid={!!error}
          aria-describedby={error ? errorId : helperText ? helperId : undefined}
          className={cn(
            'flex h-10 w-full rounded-lg border bg-bhoomi-white px-3 py-2 text-sm text-bhoomi-text placeholder:text-bhoomi-text-secondary/60 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-bhoomi-green-600 focus-visible:ring-offset-1 disabled:cursor-not-allowed disabled:opacity-50 transition-colors',
            error
              ? 'border-bhoomi-danger focus-visible:ring-bhoomi-danger'
              : 'border-bhoomi-border hover:border-bhoomi-border-strong',
            className
          )}
          {...props}
        />
        {error && (
          <p id={errorId} className="text-xs font-medium text-bhoomi-danger">
            {error}
          </p>
        )}
        {!error && helperText && (
          <p id={helperId} className="text-xs text-bhoomi-text-secondary">
            {helperText}
          </p>
        )}
      </div>
    );
  }
);

Input.displayName = 'Input';
