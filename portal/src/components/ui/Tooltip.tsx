import { ReactNode, useState } from 'react';
import { cn } from '@/lib/utils/cn';

export interface TooltipProps {
  content: ReactNode;
  children: ReactNode;
  className?: string;
}

export function Tooltip({ content, children, className }: TooltipProps) {
  const [isVisible, setIsVisible] = useState(false);

  return (
    <div
      className="relative inline-flex"
      onMouseEnter={() => setIsVisible(true)}
      onMouseLeave={() => setIsVisible(false)}
      onFocus={() => setIsVisible(true)}
      onBlur={() => setIsVisible(false)}
    >
      {children}
      {isVisible && (
        <div
          role="tooltip"
          className={cn(
            'absolute bottom-full left-1/2 mb-2 -translate-x-1/2 z-50 whitespace-nowrap rounded-lg bg-slate-900 px-3 py-1.5 text-xs font-medium text-white shadow-md transition-opacity pointer-events-none animate-in fade-in-0 duration-150',
            className
          )}
        >
          {content}
          <div className="absolute top-full left-1/2 -translate-x-1/2 border-4 border-transparent border-t-slate-900" />
        </div>
      )}
    </div>
  );
}
