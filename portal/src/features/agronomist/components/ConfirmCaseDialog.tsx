import { useState, useEffect } from 'react';
import { CheckCircle2, X, AlertCircle } from 'lucide-react';
import { Button } from '@/components/ui/Button';
import { formatTargetLabel } from '@/lib/utils/formatters';
import { CaseConfirmRequest } from '@/types/api';

interface ConfirmCaseDialogProps {
  isOpen: boolean;
  onClose: () => void;
  onConfirm: (payload: CaseConfirmRequest) => void;
  caseId: string;
  targetLabel: string;
  isPending: boolean;
  error?: Error | null;
}

export function ConfirmCaseDialog({
  isOpen,
  onClose,
  onConfirm,
  caseId,
  targetLabel,
  isPending,
  error,
}: ConfirmCaseDialogProps) {
  const [treatment, setTreatment] = useState('');
  const [notes, setNotes] = useState('');

  useEffect(() => {
    if (isOpen) {
      setTreatment('');
      setNotes('');
    }
  }, [isOpen]);

  useEffect(() => {
    if (!isOpen) return;
    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.key === 'Escape' && !isPending) {
        onClose();
      }
    };
    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, [isOpen, isPending, onClose]);

  if (!isOpen) return null;

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    onConfirm({
      verdict: 'confirmed',
      treatment: treatment.trim() || undefined,
      notes: notes.trim() || undefined,
    });
  };

  return (
    <div
      role="dialog"
      aria-modal="true"
      aria-labelledby="confirm-dialog-title"
      className="fixed inset-0 z-50 flex items-center justify-center bg-black/60 p-4 backdrop-blur-sm animate-in fade-in duration-200"
      onClick={() => !isPending && onClose()}
    >
      <div
        className="relative w-full max-w-lg rounded-2xl border border-bhoomi-border bg-bhoomi-surface p-6 shadow-2xl space-y-5"
        onClick={(e) => e.stopPropagation()}
      >
        {/* Header */}
        <div className="flex items-start justify-between">
          <div className="flex items-center gap-3">
            <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-bhoomi-primary-light text-bhoomi-primary border border-bhoomi-primary/20">
              <CheckCircle2 className="h-5 w-5" />
            </div>
            <div>
              <h2 id="confirm-dialog-title" className="text-lg font-bold text-bhoomi-text-primary">
                Confirm Model Diagnosis
              </h2>
              <p className="text-xs text-bhoomi-text-muted">
                Validating case <span className="font-mono font-medium text-bhoomi-text-secondary">{caseId}</span>
              </p>
            </div>
          </div>

          <button
            type="button"
            onClick={onClose}
            disabled={isPending}
            aria-label="Close dialog"
            className="text-bhoomi-text-muted hover:text-bhoomi-text-primary disabled:opacity-50 p-1 rounded-lg transition-colors"
          >
            <X className="h-5 w-5" />
          </button>
        </div>

        {/* Diagnosis Highlight */}
        <div className="rounded-xl border border-bhoomi-primary/20 bg-bhoomi-primary-soft p-3.5">
          <span className="text-[11px] font-bold text-bhoomi-primary block uppercase tracking-wider">
            Confirmed Diagnosis
          </span>
          <p className="text-base font-bold text-bhoomi-text-primary mt-0.5">
            {formatTargetLabel(targetLabel)}
          </p>
          <span className="font-mono text-[10px] text-bhoomi-text-muted">
            wire: {targetLabel}
          </span>
        </div>

        {/* Form Fields */}
        <form onSubmit={handleSubmit} className="space-y-4">
          <div>
            <label htmlFor="treatment-input" className="block text-xs font-bold text-bhoomi-text-secondary mb-1">
              Prescribed Treatment (Optional)
            </label>
            <textarea
              id="treatment-input"
              rows={2}
              value={treatment}
              onChange={(e) => setTreatment(e.target.value)}
              disabled={isPending}
              placeholder="e.g. Apply Tricyclazole 75% WP @ 0.6 g/L with 48h drainage..."
              className="w-full rounded-xl border border-bhoomi-border bg-bhoomi-surface p-2.5 text-xs text-bhoomi-text-primary placeholder:text-bhoomi-text-muted/60 focus:border-bhoomi-primary focus:outline-none focus:ring-2 focus:ring-bhoomi-primary/20 disabled:opacity-50 transition-all"
            />
          </div>

          <div>
            <label htmlFor="notes-input" className="block text-xs font-bold text-bhoomi-text-secondary mb-1">
              Agronomist Remarks / Notes (Optional)
            </label>
            <textarea
              id="notes-input"
              rows={2}
              value={notes}
              onChange={(e) => setNotes(e.target.value)}
              disabled={isPending}
              placeholder="Internal case observations or severity verification notes..."
              className="w-full rounded-xl border border-bhoomi-border bg-bhoomi-surface p-2.5 text-xs text-bhoomi-text-primary placeholder:text-bhoomi-text-muted/60 focus:border-bhoomi-primary focus:outline-none focus:ring-2 focus:ring-bhoomi-primary/20 disabled:opacity-50 transition-all"
            />
          </div>

          {error && (
            <div className="rounded-xl border border-red-200 bg-red-50 p-3 text-xs text-red-700 flex items-start gap-2">
              <AlertCircle className="h-4 w-4 shrink-0 mt-0.5 text-red-600" />
              <span>{error.message || 'Failed to submit confirmation. Please try again.'}</span>
            </div>
          )}

          {/* Action Buttons */}
          <div className="flex items-center justify-end gap-2.5 pt-3 border-t border-bhoomi-border">
            <Button
              type="button"
              variant="outline"
              size="sm"
              onClick={onClose}
              disabled={isPending}
            >
              Cancel
            </Button>
            <Button
              type="submit"
              variant="primary"
              size="sm"
              isLoading={isPending}
              disabled={isPending}
              className="gap-1.5"
            >
              <CheckCircle2 className="h-4 w-4" />
              <span>Confirm Case</span>
            </Button>
          </div>
        </form>
      </div>
    </div>
  );
}
