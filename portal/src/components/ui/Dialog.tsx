import { ReactNode, useEffect } from 'react';
import { cn } from '@/lib/utils/cn';
import { X } from 'lucide-react';

export interface DialogProps {
  isOpen: boolean;
  onClose: () => void;
  title?: string;
  description?: string;
  children: ReactNode;
  className?: string;
}

export function Dialog({
  isOpen,
  onClose,
  title,
  description,
  children,
  className,
}: DialogProps) {
  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.key === 'Escape' && isOpen) {
        onClose();
      }
    };
    if (isOpen) {
      document.body.style.overflow = 'hidden';
      window.addEventListener('keydown', handleKeyDown);
    }
    return () => {
      document.body.style.overflow = '';
      window.removeEventListener('keydown', handleKeyDown);
    };
  }, [isOpen, onClose]);

  if (!isOpen) return null;

  return (
    <div
      role="dialog"
      aria-modal="true"
      aria-labelledby={title ? 'dialog-title' : undefined}
      aria-describedby={description ? 'dialog-description' : undefined}
      className="fixed inset-0 z-50 flex items-center justify-center p-4"
    >
      {/* Backdrop */}
      <div
        className="fixed inset-0 bg-black/40 backdrop-blur-[2px] transition-opacity"
        onClick={onClose}
        aria-hidden="true"
      />

      {/* Dialog Surface */}
      <div
        className={cn(
          'relative z-50 w-full max-w-lg rounded-card bg-bhoomi-white p-6 shadow-lg border border-bhoomi-border animate-in fade-in-0 zoom-in-95 duration-150',
          className
        )}
      >
        <button
          type="button"
          onClick={onClose}
          className="absolute right-4 top-4 rounded-md p-1.5 text-bhoomi-text-secondary hover:bg-bhoomi-surface-soft focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-bhoomi-green-600"
          aria-label="Close dialog"
        >
          <X className="h-4 w-4" />
        </button>

        {title && (
          <h2 id="dialog-title" className="text-lg font-semibold text-bhoomi-text">
            {title}
          </h2>
        )}
        {description && (
          <p id="dialog-description" className="mt-1 text-sm text-bhoomi-text-secondary">
            {description}
          </p>
        )}

        <div className="mt-4">{children}</div>
      </div>
    </div>
  );
}
