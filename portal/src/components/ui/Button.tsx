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
      'inline-flex items-center justify-center font-medium transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-bhoomi-green-600 focus-visible:ring-offset-2 disabled:opacity-50 disabled:pointer-events-none rounded-lg';

    const variants: Record<ComponentVariant, string> = {
      primary: 'bg-bhoomi-green-700 hover:bg-bhoomi-green-800 text-bhoomi-white shadow-sm',
      secondary:
        'bg-bhoomi-white hover:bg-bhoomi-surface-soft text-bhoomi-text border border-bhoomi-border shadow-sm',
      outline:
        'bg-transparent hover:bg-bhoomi-green-50 text-bhoomi-green-800 border border-bhoomi-green-700',
      danger: 'bg-bhoomi-danger hover:bg-red-800 text-bhoomi-white shadow-sm',
      ghost: 'bg-transparent hover:bg-bhoomi-surface-soft text-bhoomi-text',
    };

    const sizes: Record<ComponentSize, string> = {
      sm: 'h-8 px-3 text-xs gap-1.5',
      md: 'h-10 px-4 text-sm gap-2',
      lg: 'h-12 px-6 text-base gap-2.5',
    };

    return (
      <button
        ref={ref}
        type={type}
        className={cn(baseStyles, variants[variant], sizes[size], className)}
        disabled={disabled || isLoading}
        {...props}
      >
        {isLoading && <Loader2 className="h-4 w-4 animate-spin text-current" />}
        {children}
      </button>
    );
  }
);

Button.displayName = 'Button';
