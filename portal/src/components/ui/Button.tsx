import { ButtonHTMLAttributes, forwardRef } from 'react';
import { cn } from '@/lib/utils/cn';
import { ComponentSize, ComponentVariant } from '@/types/common';
import { Loader2 } from 'lucide-react';

export interface ButtonProps extends ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: ComponentVariant;
  size?: ComponentSize;
  isLoading?: boolean;
}

export const Button = forwardRef<HTMLButtonElement, ButtonProps>(
  (
    {
      className,
      variant = 'primary',
      size = 'md',
      isLoading = false,
      disabled,
      children,
      type = 'button',
      ...props
    },
    ref
  ) => {
    const baseStyles =
      'inline-flex items-center justify-center font-medium transition-all duration-150 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-bhoomi-primary focus-visible:ring-offset-2 disabled:opacity-50 disabled:pointer-events-none rounded-xl select-none';

    const variants: Record<ComponentVariant, string> = {
      primary:
        'bg-bhoomi-green-700 hover:bg-bhoomi-green-800 text-bhoomi-white shadow-xs active:translate-y-px',
      secondary:
        'bg-bhoomi-surface hover:bg-bhoomi-surface-soft text-bhoomi-text-primary border border-bhoomi-border-strong shadow-xs active:translate-y-px',
      outline:
        'bg-transparent hover:bg-bhoomi-primary-light text-bhoomi-primary border border-bhoomi-primary',
      danger:
        'bg-bhoomi-surface hover:bg-bhoomi-danger-soft text-bhoomi-danger border border-red-300 shadow-xs active:translate-y-px',
      ghost:
        'bg-transparent hover:bg-bhoomi-primary-soft text-bhoomi-text-secondary hover:text-bhoomi-primary-dark',
    };

    const sizes: Record<ComponentSize, string> = {
      sm: 'h-8 px-3 text-xs gap-1.5',
      md: 'h-10 px-4 text-sm gap-2',
      lg: 'h-11 px-5 text-base gap-2.5',
    };

    return (
      <button
        ref={ref}
        type={type}
        className={cn(baseStyles, variants[variant], sizes[size], className)}
        disabled={disabled || isLoading}
        {...props}
      >
        {isLoading && <Loader2 className="h-4 w-4 animate-spin text-current shrink-0" />}
        {children}
      </button>
    );
  }
);

Button.displayName = 'Button';
