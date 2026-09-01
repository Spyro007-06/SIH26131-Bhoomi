import { HTMLAttributes } from 'react';
import { cn } from '@/lib/utils/cn';

export interface BadgeProps extends HTMLAttributes<HTMLSpanElement> {
  variant?: 'primary' | 'secondary' | 'success' | 'warning' | 'danger' | 'info' | 'outline';
  size?: 'sm' | 'md';
}

export function Badge({
  className,
  variant = 'primary',
  size = 'md',
  children,
  ...props
}: BadgeProps) {
  const variants = {
    primary: 'bg-bhoomi-green-100 text-bhoomi-green-900 border-bhoomi-green-500/30',
    secondary: 'bg-bhoomi-surface-soft text-bhoomi-text-secondary border-bhoomi-border',
    success: 'bg-emerald-50 text-emerald-800 border-emerald-300',
    warning: 'bg-amber-50 text-amber-900 border-amber-300',
    danger: 'bg-red-50 text-red-900 border-red-200',
    info: 'bg-blue-50 text-blue-900 border-blue-200',
    outline: 'bg-transparent text-bhoomi-text border-bhoomi-border-strong',
  };

  const sizes = {
    sm: 'text-xs px-2 py-0.5',
    md: 'text-xs font-medium px-2.5 py-1',
  };

  return (
    <span
      className={cn(
        'inline-flex items-center rounded-full border font-medium transition-colors',
        variants[variant],
        sizes[size],
        className
      )}
      {...props}
    >
      {children}
    </span>
  );
}
