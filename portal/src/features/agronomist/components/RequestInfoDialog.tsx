import { useState, useEffect } from 'react';
import { HelpCircle, X, AlertCircle } from 'lucide-react';
import { Button } from '@/components/ui/Button';
import { CaseRequestInfoRequest } from '@/types/api';

interface RequestInfoDialogProps {
  isOpen: boolean;
  onClose: () => void;
  onRequestInfo: (payload: CaseRequestInfoRequest) => void;
  caseId: string;
  isPending: boolean;
  error?: Error | null;
}

export function RequestInfoDialog({
  isOpen,
  onClose,
  onRequestInfo,
  caseId,
  isPending,
  error,
}: RequestInfoDialogProps) {
  const [question, setQuestion] = useState('');
  const [validationError, setValidationError] = useState<string | null>(null);

  useEffect(() => {
    if (isOpen) {
      setQuestion('');
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
    if (!question.trim()) {
      setValidationError('Please specify the question or evidence required from the farmer.');
      return;
    }

    setValidationError(null);
    onRequestInfo({
      question: question.trim(),
    });
  };

  return (
    <div
      role="dialog"
      aria-modal="true"
      aria-labelledby="request-info-dialog-title"
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
            <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-blue-100 text-blue-800 border border-blue-200">
              <HelpCircle className="h-5 w-5" />
            </div>
            <div>
              <h2 id="request-info-dialog-title" className="text-lg font-bold text-bhoomi-text-primary">
                Request Additional Information
              </h2>
              <p className="text-xs text-bhoomi-text-muted">
                Case <span className="font-mono font-medium text-bhoomi-text-secondary">{caseId}</span> · Will notify field user
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
          <div>
            <label htmlFor="info-question-input" className="block text-xs font-bold text-bhoomi-text-secondary mb-1">
              Required Information / Question <span className="text-red-500">*</span>
            </label>
            <textarea
              id="info-question-input"
              rows={3}
              value={question}
              onChange={(e) => {
                setQuestion(e.target.value);
                setValidationError(null);
              }}
              disabled={isPending}
              placeholder="e.g. Please capture a clear close-up photo of the leaf underside, or clarify if pesticide was sprayed in the last 7 days..."
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
              <span>{error.message || 'Failed to submit request. Please try again.'}</span>
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
              className="gap-1.5 bg-blue-600 hover:bg-blue-700 text-white"
            >
              <HelpCircle className="h-4 w-4" />
              <span>Send Request</span>
            </Button>
          </div>
        </form>
      </div>
    </div>
  );
}
