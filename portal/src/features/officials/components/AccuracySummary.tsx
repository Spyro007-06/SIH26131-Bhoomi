import { CheckCircle, AlertCircle, ShieldCheck, Calendar } from 'lucide-react';
import { Card, CardContent } from '@/components/ui/Card';
import { formatDate } from '@/lib/utils/dates';
import type { LabelAccuracy, AccuracyWindow } from '@/types/api';

interface AccuracySummaryProps {
  rows: LabelAccuracy[];
  window?: AccuracyWindow;
}

export function AccuracySummary({ rows, window }: AccuracySummaryProps) {
  const totalConfirmed = rows.reduce((sum, r) => sum + r.confirmed, 0);
  const totalCorrected = rows.reduce((sum, r) => sum + r.corrected, 0);
  const totalMonitored = rows.length;

  const windowLabel =
    window?.from && window?.to
      ? `${formatDate(window.from)} – ${formatDate(window.to)}`
      : window?.from
      ? `Since ${formatDate(window.from)}`
      : 'Active Surveillance';

  return (
    <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
      {/* Confirmed */}
      <Card className="border-bhoomi-green-600/30 bg-white shadow-sm overflow-hidden">
        <CardContent className="p-5">
          <div className="flex items-center justify-between">
            <span className="text-xs font-semibold uppercase tracking-wider text-bhoomi-text-secondary">
              Confirmed Diagnoses
            </span>
            <div className="flex h-8 w-8 items-center justify-center rounded-lg bg-bhoomi-green-100 text-bhoomi-green-800">
              <CheckCircle className="h-4 w-4" />
            </div>
          </div>
          <div className="mt-3 flex items-baseline gap-2">
            <span className="text-3xl font-bold font-mono text-bhoomi-green-900">
              {totalConfirmed}
            </span>
            <span className="text-xs text-bhoomi-text-secondary">cases verified</span>
          </div>
          <p className="mt-1 text-[11px] text-bhoomi-text-tertiary">
            Agronomists agreed with model diagnosis
          </p>
        </CardContent>
      </Card>

      {/* Corrected */}
      <Card className="border-amber-500/30 bg-white shadow-sm overflow-hidden">
        <CardContent className="p-5">
          <div className="flex items-center justify-between">
            <span className="text-xs font-semibold uppercase tracking-wider text-bhoomi-text-secondary">
              Corrected Diagnoses
            </span>
            <div className="flex h-8 w-8 items-center justify-center rounded-lg bg-amber-100 text-amber-800">
              <AlertCircle className="h-4 w-4" />
            </div>
          </div>
          <div className="mt-3 flex items-baseline gap-2">
            <span className="text-3xl font-bold font-mono text-amber-900">
              {totalCorrected}
            </span>
            <span className="text-xs text-bhoomi-text-secondary">cases corrected</span>
          </div>
          <p className="mt-1 text-[11px] text-bhoomi-text-tertiary">
            Agronomists supplied alternative label
          </p>
        </CardContent>
      </Card>

      {/* Diseases Monitored */}
      <Card className="border-bhoomi-border bg-white shadow-sm overflow-hidden">
        <CardContent className="p-5">
          <div className="flex items-center justify-between">
            <span className="text-xs font-semibold uppercase tracking-wider text-bhoomi-text-secondary">
              Target Diseases
            </span>
            <div className="flex h-8 w-8 items-center justify-center rounded-lg bg-bhoomi-surface-soft text-bhoomi-text-secondary">
              <ShieldCheck className="h-4 w-4" />
            </div>
          </div>
          <div className="mt-3 flex items-baseline gap-2">
            <span className="text-3xl font-bold font-mono text-bhoomi-text">
              {totalMonitored}
            </span>
            <span className="text-xs text-bhoomi-text-secondary">labels evaluated</span>
          </div>
          <p className="mt-1 text-[11px] text-bhoomi-text-tertiary">
            Active pathogens with validated records
          </p>
        </CardContent>
      </Card>

      {/* Surveillance Window */}
      <Card className="border-bhoomi-border bg-white shadow-sm overflow-hidden">
        <CardContent className="p-5">
          <div className="flex items-center justify-between">
            <span className="text-xs font-semibold uppercase tracking-wider text-bhoomi-text-secondary">
              Review Window
            </span>
            <div className="flex h-8 w-8 items-center justify-center rounded-lg bg-blue-50 text-blue-700">
              <Calendar className="h-4 w-4" />
            </div>
          </div>
          <div className="mt-3">
            <span className="text-sm font-semibold text-bhoomi-text block truncate" title={windowLabel}>
              {windowLabel}
            </span>
            <span className="text-xs text-bhoomi-text-secondary">Server aggregation period</span>
          </div>
          <p className="mt-1 text-[11px] text-bhoomi-text-tertiary">
            Data window returned by official API
          </p>
        </CardContent>
      </Card>
    </div>
  );
}
