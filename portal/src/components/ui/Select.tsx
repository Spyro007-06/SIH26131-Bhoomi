import { SelectHTMLAttributes, forwardRef, useId } from 'react';
import { cn } from '@/lib/utils/cn';

export interface SelectOption {
  value: string;
  label: string;
  disabled?: boolean;
}

export interface SelectProps extends SelectHTMLAttributes<HTMLSelectElement> {
  label?: string;
  error?: string;
  options: SelectOption[];
  placeholder?: string;
}

export const Select = forwardRef<HTMLSelectElement, SelectProps>(
  ({ className, label, error, options, placeholder, id, disabled, ...props }, ref) => {
    const generatedId = useId();
    const selectId = id || generatedId;
    const errorId = `${selectId}-error`;

    return (
      <div className="w-full space-y-1.5">
        {label && (
          <label
            htmlFor={selectId}
            className="block text-xs font-semibold uppercase tracking-wider text-bhoomi-text-secondary"
          >
            {label}
          </label>
        )}
        <select
          id={selectId}
          ref={ref}
          disabled={disabled}
          aria-invalid={!!error}
          aria-describedby={error ? errorId : undefined}
          className={cn(
            'flex h-10 w-full rounded-xl border bg-bhoomi-surface px-3.5 py-2 text-sm text-bhoomi-text-primary focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-bhoomi-primary/20 focus-visible:border-bhoomi-primary disabled:cursor-not-allowed disabled:opacity-50 transition-colors shadow-xs',
            error
              ? 'border-bhoomi-danger focus-visible:ring-bhoomi-danger/20 focus-visible:border-bhoomi-danger'
              : 'border-bhoomi-border-strong hover:border-bhoomi-text-muted',
            className
          )}
          {...props}
        >
          {placeholder && <option value="">{placeholder}</option>}
          {options.map((opt) => (
            <option key={opt.value} value={opt.value} disabled={opt.disabled}>
              {opt.label}
            </option>
          ))}
        </select>
        {error && (
          <p id={errorId} className="text-xs font-medium text-bhoomi-danger">
            {error}
          </p>
        )}
      </div>
    );
  }
);

Select.displayName = 'Select';
