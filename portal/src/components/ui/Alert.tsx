import { HTMLAttributes, ReactNode } from 'react';
import { cn } from '@/lib/utils/cn';
import { AlertCircle, CheckCircle2, Info, AlertTriangle, ShieldAlert } from 'lucide-react';

export type AlertVariant = 'success' | 'warning' | 'danger' | 'info' | 'escalation';

export interface AlertProps extends HTMLAttributes<HTMLDivElement> {
  variant?: AlertVariant;
  title?: string;
  icon?: ReactNode;
}

export function Alert({
  className,
  variant = 'info',
  title,
  icon,
  children,
  ...props
}: AlertProps) {
  const variantStyles = {
    success: 'border-emerald-200 bg-emerald-50 text-emerald-900',
    warning: 'border-amber-200 bg-amber-50 text-amber-900',
    danger: 'border-rose-200 bg-rose-50 text-rose-900',
    info: 'border-sky-200 bg-sky-50 text-sky-900',
    escalation: 'border-purple-200 bg-purple-50 text-purple-900',
  };

  const defaultIcons = {
    success: <CheckCircle2 className="h-5 w-5 text-emerald-600 shrink-0" />,
    warning: <AlertTriangle className="h-5 w-5 text-amber-600 shrink-0" />,
    danger: <AlertCircle className="h-5 w-5 text-rose-600 shrink-0" />,
    info: <Info className="h-5 w-5 text-sky-600 shrink-0" />,
    escalation: <ShieldAlert className="h-5 w-5 text-purple-600 shrink-0" />,
  };

  return (
    <div
      role="alert"
      className={cn(
        'flex gap-3 rounded-2xl border p-4 text-sm transition-all',
        variantStyles[variant],
        className
      )}
      {...props}
    >
      <div className="pt-0.5">{icon || defaultIcons[variant]}</div>
      <div className="flex-1 space-y-1">
        {title && <h5 className="font-semibold leading-none tracking-tight">{title}</h5>}
        {children && <div className="text-xs leading-relaxed opacity-90">{children}</div>}
      </div>
    </div>
  );
}
