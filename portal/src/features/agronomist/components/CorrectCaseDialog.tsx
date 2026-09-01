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
        className="relative w-full max-w-lg rounded-xl border border-bhoomi-border bg-bhoomi-white p-6 shadow-2xl space-y-5"
        onClick={(e) => e.stopPropagation()}
      >
        {/* Header */}
        <div className="flex items-start justify-between">
          <div className="flex items-center gap-3">
            <div className="flex h-10 w-10 items-center justify-center rounded-full bg-amber-100 text-amber-800">
              <Edit3 className="h-5 w-5" />
            </div>
            <div>
              <h2 id="correct-dialog-title" className="text-lg font-bold text-bhoomi-text">
                Correct Diagnosis
              </h2>
              <p className="text-xs text-bhoomi-text-secondary">
                Case <span className="font-mono font-medium">{caseId}</span> · Model was{' '}
                <span className="font-semibold text-bhoomi-text">{formatTargetLabel(currentLabel)}</span>
              </p>
            </div>
          </div>

          <button
            type="button"
            onClick={onClose}
            disabled={isPending}
            aria-label="Close dialog"
            className="text-bhoomi-text-secondary hover:text-bhoomi-text disabled:opacity-50"
          >
            <X className="h-5 w-5" />
          </button>
        </div>

        {/* Form Fields */}
        <form onSubmit={handleSubmit} className="space-y-4">
          {/* Target Label Select */}
          <div>
            <label htmlFor="corrected-label-select" className="block text-xs font-semibold text-bhoomi-text mb-1">
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
              className="w-full rounded-lg border border-bhoomi-border bg-bhoomi-white p-2.5 text-xs text-bhoomi-text focus:border-bhoomi-green-600 focus:outline-none focus:ring-1 focus:ring-bhoomi-green-600 disabled:opacity-50"
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
            <label htmlFor="treatment-input" className="block text-xs font-semibold text-bhoomi-text mb-1">
              Prescribed Treatment (Optional)
            </label>
            <textarea
              id="treatment-input"
              rows={2}
              value={treatment}
              onChange={(e) => setTreatment(e.target.value)}
              disabled={isPending}
              placeholder="e.g. Recommended chemical / cultural remedy for corrected diagnosis..."
              className="w-full rounded-lg border border-bhoomi-border bg-bhoomi-white p-2.5 text-xs text-bhoomi-text placeholder:text-bhoomi-text-secondary/50 focus:border-bhoomi-green-600 focus:outline-none focus:ring-1 focus:ring-bhoomi-green-600 disabled:opacity-50"
            />
          </div>

          <div>
            <label htmlFor="notes-input" className="block text-xs font-semibold text-bhoomi-text mb-1">
              Correction Reason / Expert Notes (Optional)
            </label>
            <textarea
              id="notes-input"
              rows={2}
              value={notes}
              onChange={(e) => setNotes(e.target.value)}
              disabled={isPending}
              placeholder="Reason for overriding model prediction..."
              className="w-full rounded-lg border border-bhoomi-border bg-bhoomi-white p-2.5 text-xs text-bhoomi-text placeholder:text-bhoomi-text-secondary/50 focus:border-bhoomi-green-600 focus:outline-none focus:ring-1 focus:ring-bhoomi-green-600 disabled:opacity-50"
            />
          </div>

          {validationError && (
            <div className="rounded-lg border border-red-200 bg-red-50 p-2.5 text-xs text-red-700 flex items-center gap-2">
              <AlertCircle className="h-4 w-4 shrink-0" />
              <span>{validationError}</span>
            </div>
          )}

          {error && (
            <div className="rounded-lg border border-red-200 bg-red-50 p-3 text-xs text-red-700 flex items-start gap-2">
              <AlertCircle className="h-4 w-4 shrink-0 mt-0.5" />
              <span>{error.message || 'Failed to submit correction. Please try again.'}</span>
            </div>
          )}

          {/* Action Buttons */}
          <div className="flex items-center justify-end gap-2 pt-2 border-t border-bhoomi-border">
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
              className="gap-1.5 bg-amber-700 hover:bg-amber-800"
            >
              <Edit3 className="h-4 w-4" />
              Submit Correction
            </Button>
          </div>
        </form>
      </div>
    </div>
  );
}
