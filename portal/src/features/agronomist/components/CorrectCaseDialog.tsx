import { useState, useEffect } from 'react';
import { Edit3, X, AlertCircle } from 'lucide-react';
import { Button } from '@/components/ui/Button';
import {
  PADDY_TARGETS,
  COTTON_TARGETS,
  SOYBEAN_TARGETS,
  JOWAR_TARGETS,
} from '@/types/enums';
import { formatTargetLabel } from '@/lib/utils/formatters';
import { CaseConfirmRequest } from '@/types/api';

interface CorrectCaseDialogProps {
  isOpen: boolean;
  onClose: () => void;
  onCorrect: (payload: CaseConfirmRequest) => void;
  caseId: string;
  currentLabel: string;
  isPending: boolean;
  error?: Error | null;
}

export function CorrectCaseDialog({
  isOpen,
  onClose,
  onCorrect,
  caseId,
  currentLabel,
  isPending,
  error,
}: CorrectCaseDialogProps) {
  const [correctedLabel, setCorrectedLabel] = useState('');
  const [treatment, setTreatment] = useState('');
  const [notes, setNotes] = useState('');
  const [validationError, setValidationError] = useState<string | null>(null);

  useEffect(() => {
    if (isOpen) {
      setCorrectedLabel('');
      setTreatment('');
      setNotes('');
      setValidationError(null);
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
    if (!correctedLabel) {
      setValidationError('Please select the correct diagnosis from the contract-supported list.');
      return;
    }

    setValidationError(null);
    onCorrect({
      verdict: 'corrected',
      corrected_label: correctedLabel,
      treatment: treatment.trim() || undefined,
      notes: notes.trim() || undefined,
    });
  };

  return (
    <div
      role="dialog"
      aria-modal="true"
      aria-labelledby="correct-dialog-title"
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
            <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-amber-100 text-amber-800 border border-amber-300">
              <Edit3 className="h-5 w-5" />
            </div>
            <div>
              <h2 id="correct-dialog-title" className="text-lg font-bold text-bhoomi-text-primary">
                Correct Diagnosis
              </h2>
              <p className="text-xs text-bhoomi-text-muted">
                Case <span className="font-mono font-medium text-bhoomi-text-secondary">{caseId}</span> · Model was{' '}
                <span className="font-semibold text-bhoomi-text-primary">{formatTargetLabel(currentLabel)}</span>
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

        {/* Form Fields */}
        <form onSubmit={handleSubmit} className="space-y-4">
          {/* Target Label Select */}
          <div>
            <label htmlFor="corrected-label-select" className="block text-xs font-bold text-bhoomi-text-secondary mb-1">
              Correct Diagnosis <span className="text-red-500">*</span>
            </label>
            <select
              id="corrected-label-select"
              value={correctedLabel}
              onChange={(e) => {
                setCorrectedLabel(e.target.value);
                setValidationError(null);
              }}
              disabled={isPending}
              className="w-full rounded-xl border border-bhoomi-border bg-bhoomi-surface p-2.5 text-xs text-bhoomi-text-primary focus:border-bhoomi-primary focus:outline-none focus:ring-2 focus:ring-bhoomi-primary/20 disabled:opacity-50 transition-all"
            >
              <option value="">-- Select Corrected Target Diagnosis --</option>
              <optgroup label="Paddy (Rice)">
                {PADDY_TARGETS.map((t) => (
                  <option key={t} value={t}>
                    {formatTargetLabel(t)} ({t})
                  </option>
                ))}
              </optgroup>
              <optgroup label="Cotton">
                {COTTON_TARGETS.map((t) => (
                  <option key={t} value={t}>
                    {formatTargetLabel(t)} ({t})
                  </option>
                ))}
              </optgroup>
              <optgroup label="Soybean">
                {SOYBEAN_TARGETS.map((t) => (
                  <option key={t} value={t}>
                    {formatTargetLabel(t)} ({t})
                  </option>
                ))}
              </optgroup>
              <optgroup label="Jowar (Sorghum)">
                {JOWAR_TARGETS.map((t) => (
                  <option key={t} value={t}>
                    {formatTargetLabel(t)} ({t})
                  </option>
                ))}
              </optgroup>
            </select>
          </div>

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
              placeholder="e.g. Recommended chemical / cultural remedy for corrected diagnosis..."
              className="w-full rounded-xl border border-bhoomi-border bg-bhoomi-surface p-2.5 text-xs text-bhoomi-text-primary placeholder:text-bhoomi-text-muted/60 focus:border-bhoomi-primary focus:outline-none focus:ring-2 focus:ring-bhoomi-primary/20 disabled:opacity-50 transition-all"
            />
          </div>

          <div>
            <label htmlFor="notes-input" className="block text-xs font-bold text-bhoomi-text-secondary mb-1">
              Correction Reason / Expert Notes (Optional)
            </label>
            <textarea
              id="notes-input"
              rows={2}
              value={notes}
              onChange={(e) => setNotes(e.target.value)}
              disabled={isPending}
              placeholder="Reason for overriding model prediction..."
              className="w-full rounded-xl border border-bhoomi-border bg-bhoomi-surface p-2.5 text-xs text-bhoomi-text-primary placeholder:text-bhoomi-text-muted/60 focus:border-bhoomi-primary focus:outline-none focus:ring-2 focus:ring-bhoomi-primary/20 disabled:opacity-50 transition-all"
            />
          </div>

          {validationError && (
            <div className="rounded-xl border border-red-200 bg-red-50 p-2.5 text-xs text-red-700 flex items-center gap-2">
              <AlertCircle className="h-4 w-4 shrink-0 text-red-600" />
              <span>{validationError}</span>
            </div>
          )}

          {error && (
            <div className="rounded-xl border border-red-200 bg-red-50 p-3 text-xs text-red-700 flex items-start gap-2">
              <AlertCircle className="h-4 w-4 shrink-0 mt-0.5 text-red-600" />
              <span>{error.message || 'Failed to submit correction. Please try again.'}</span>
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
              className="gap-1.5 bg-amber-600 hover:bg-amber-700 text-white"
            >
              <Edit3 className="h-4 w-4" />
              <span>Submit Correction</span>
            </Button>
          </div>
        </form>
      </div>
    </div>
  );
}
