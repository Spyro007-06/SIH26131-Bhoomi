import { useNavigate } from 'react-router-dom';
import { CheckCircle2, Radio, ArrowRight, ShieldCheck } from 'lucide-react';
import { Button } from '@/components/ui/Button';
import { CaseConfirmResponse } from '@/types/api';

interface ResolutionSuccessModalProps {
  isOpen: boolean;
  resolution: CaseConfirmResponse | null;
  onClose: () => void;
}

export function ResolutionSuccessModal({
  isOpen,
  resolution,
  onClose,
}: ResolutionSuccessModalProps) {
  const navigate = useNavigate();

  if (!isOpen || !resolution) return null;

  const handleReturnToQueue = () => {
    onClose();
    navigate('/agronomist/cases');
  };

  return (
    <div
      role="dialog"
      aria-modal="true"
      aria-labelledby="success-modal-title"
      className="fixed inset-0 z-50 flex items-center justify-center bg-black/60 p-4 backdrop-blur-sm animate-in fade-in duration-200"
    >
      <div className="relative w-full max-w-md rounded-2xl border border-bhoomi-green-600/30 bg-bhoomi-white p-6 shadow-2xl space-y-6 text-center">
        {/* Success Icon */}
        <div className="mx-auto flex h-16 w-16 items-center justify-center rounded-full bg-bhoomi-green-100 text-bhoomi-green-800 shadow-sm ring-8 ring-bhoomi-green-50">
          <CheckCircle2 className="h-9 w-9" />
        </div>

        {/* Title & Subtitle */}
        <div className="space-y-1">
          <h2 id="success-modal-title" className="text-xl font-bold text-bhoomi-text">
            Case Resolved
          </h2>
          <p className="text-xs text-bhoomi-text-secondary">
            Expert confirmation has been recorded in the central database.
          </p>
        </div>

        {/* Downstream Effects Card */}
        <div className="rounded-xl border border-bhoomi-border bg-bhoomi-surface-soft/60 p-4 space-y-3 text-left text-xs">
          <div className="flex items-center justify-between border-b border-bhoomi-border/60 pb-2">
            <span className="text-bhoomi-text-secondary font-medium flex items-center gap-1.5">
              <ShieldCheck className="h-3.5 w-3.5 text-bhoomi-green-700" />
              Confirmation ID
            </span>
            <span className="font-mono font-bold text-bhoomi-text">
              {resolution.confirmation_id}
            </span>
          </div>

          <div className="flex items-center justify-between">
            <span className="text-bhoomi-text-secondary font-medium flex items-center gap-1.5">
              <Radio className="h-3.5 w-3.5 text-bhoomi-green-700" />
              Spread Alerts Issued
            </span>
            <span className="font-mono font-bold text-base text-bhoomi-green-900 bg-bhoomi-green-100 px-2 py-0.5 rounded border border-bhoomi-green-500/20">
              {resolution.spread_alerts_issued}
            </span>
          </div>
        </div>

        <p className="text-[11px] text-bhoomi-text-secondary">
          Nearby farms in the affected perimeter have been issued proactive disease warnings.
        </p>

        {/* Action button */}
        <div className="pt-2">
          <Button
            type="button"
            variant="primary"
            size="md"
            onClick={handleReturnToQueue}
            className="w-full gap-2 bg-bhoomi-green-800 hover:bg-bhoomi-green-900 shadow-md"
          >
            <span>Back to Case Queue</span>
            <ArrowRight className="h-4 w-4" />
          </Button>
        </div>
      </div>
    </div>
  );
}
