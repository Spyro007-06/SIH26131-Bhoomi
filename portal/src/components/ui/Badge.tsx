import { HTMLAttributes } from 'react';
import { cn } from '@/lib/utils/cn';

export interface BadgeProps extends HTMLAttributes<HTMLSpanElement> {
  variant?:
    | 'primary'
    | 'secondary'
    | 'success'
    | 'warning'
    | 'danger'
    | 'info'
    | 'escalation'
    | 'neutral'
    | 'outline';
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
    primary: 'bg-bhoomi-primary-light text-bhoomi-primary border-bhoomi-primary/20',
    secondary: 'bg-bhoomi-surface-soft text-bhoomi-text-secondary border-bhoomi-border',
    success: 'bg-emerald-50 text-emerald-700 border-emerald-200',
    warning: 'bg-amber-50 text-amber-800 border-amber-200',
    danger: 'bg-rose-50 text-rose-700 border-rose-200',
    info: 'bg-sky-50 text-sky-700 border-sky-200',
    escalation: 'bg-purple-50 text-purple-700 border-purple-200',
    neutral: 'bg-slate-100 text-slate-700 border-slate-200',
    outline: 'bg-transparent text-bhoomi-text-primary border-bhoomi-border-strong',
  };

  const sizes = {
    sm: 'text-[11px] font-semibold px-2 py-0.5',
    md: 'text-xs font-semibold px-2.5 py-1',
  };

  return (
    <span
      className={cn(
        'inline-flex items-center rounded-full border font-semibold transition-colors',
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
