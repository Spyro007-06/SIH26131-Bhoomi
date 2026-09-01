import { CheckCircle2, Edit3, HelpCircle } from 'lucide-react';
import { Button } from '@/components/ui/Button';

interface CaseActionBarProps {
  onConfirmClick: () => void;
  onCorrectClick: () => void;
  onRequestInfoClick: () => void;
  isPending: boolean;
  isResolved?: boolean;
}

export function CaseActionBar({
  onConfirmClick,
  onCorrectClick,
  onRequestInfoClick,
  isPending,
  isResolved,
}: CaseActionBarProps) {
  if (isResolved) {
    return (
      <div className="sticky bottom-0 z-20 flex items-center justify-between border-t border-bhoomi-green-600/30 bg-bhoomi-green-900/95 px-6 py-3.5 text-bhoomi-cream shadow-lg backdrop-blur-md rounded-xl">
        <div className="flex items-center gap-2 text-xs font-medium">
          <CheckCircle2 className="h-4 w-4 text-bhoomi-green-400" />
          <span>This case has been resolved and confirmed.</span>
        </div>
      </div>
    );
  }

  return (
    <div className="sticky bottom-0 z-20 flex flex-col sm:flex-row items-center justify-between gap-3 border-t border-bhoomi-border bg-bhoomi-white/95 px-6 py-3.5 shadow-lg backdrop-blur-md rounded-xl">
      <div className="text-xs text-bhoomi-text-secondary hidden sm:block">
        <span className="font-semibold text-bhoomi-text">Expert Decision:</span> Choose an action after inspecting all evidence.
      </div>

      <div className="flex items-center gap-2.5 w-full sm:w-auto justify-end">
        {/* Request Info Button */}
        <Button
          type="button"
          variant="outline"
          size="sm"
          onClick={onRequestInfoClick}
          disabled={isPending}
          className="gap-1.5 text-xs flex-1 sm:flex-initial"
        >
          <HelpCircle className="h-4 w-4 text-blue-600" />
          Request Information
        </Button>

        {/* Correct Button */}
        <Button
          type="button"
          variant="outline"
          size="sm"
          onClick={onCorrectClick}
          disabled={isPending}
          className="gap-1.5 text-xs flex-1 sm:flex-initial border-amber-500/40 text-amber-900 hover:bg-amber-50"
        >
          <Edit3 className="h-4 w-4 text-amber-600" />
          Correct Diagnosis
        </Button>

        {/* Confirm Button */}
        <Button
          type="button"
          variant="primary"
          size="sm"
          onClick={onConfirmClick}
          disabled={isPending}
          className="gap-1.5 text-xs flex-1 sm:flex-initial bg-bhoomi-green-800 hover:bg-bhoomi-green-900 text-bhoomi-cream shadow-sm"
        >
          <CheckCircle2 className="h-4 w-4 text-bhoomi-green-300" />
          Confirm Diagnosis
        </Button>
      </div>
    </div>
  );
}
