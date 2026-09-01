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
      <Card className="rounded-2xl border border-bhoomi-primary/20 bg-bhoomi-surface shadow-card overflow-hidden">
        <CardContent className="p-5">
          <div className="flex items-center justify-between">
            <span className="text-xs font-bold uppercase tracking-wider text-bhoomi-text-muted">
              Confirmed Diagnoses
            </span>
            <div className="flex h-8 w-8 items-center justify-center rounded-xl bg-bhoomi-primary-light text-bhoomi-primary border border-bhoomi-primary/20">
              <CheckCircle className="h-4 w-4" />
            </div>
          </div>
          <div className="mt-3 flex items-baseline gap-2">
            <span className="text-3xl font-bold font-mono text-bhoomi-primary-dark">
              {totalConfirmed}
            </span>
            <span className="text-xs text-bhoomi-text-muted">cases verified</span>
          </div>
          <p className="mt-1 text-[11px] text-bhoomi-text-secondary">
            Agronomists agreed with model diagnosis
          </p>
        </CardContent>
      </Card>

      {/* Corrected */}
      <Card className="rounded-2xl border border-amber-300 bg-amber-50/40 shadow-card overflow-hidden">
        <CardContent className="p-5">
          <div className="flex items-center justify-between">
            <span className="text-xs font-bold uppercase tracking-wider text-amber-800">
              Corrected Diagnoses
            </span>
            <div className="flex h-8 w-8 items-center justify-center rounded-xl bg-amber-100 text-amber-800 border border-amber-300">
              <AlertCircle className="h-4 w-4" />
            </div>
          </div>
          <div className="mt-3 flex items-baseline gap-2">
            <span className="text-3xl font-bold font-mono text-amber-900">
              {totalCorrected}
            </span>
            <span className="text-xs text-amber-800/80">cases corrected</span>
          </div>
          <p className="mt-1 text-[11px] text-amber-800/70">
            Agronomists supplied alternative label
          </p>
        </CardContent>
      </Card>

      {/* Diseases Monitored */}
      <Card className="rounded-2xl border border-bhoomi-border bg-bhoomi-surface shadow-card overflow-hidden">
        <CardContent className="p-5">
          <div className="flex items-center justify-between">
            <span className="text-xs font-bold uppercase tracking-wider text-bhoomi-text-muted">
              Target Diseases
            </span>
            <div className="flex h-8 w-8 items-center justify-center rounded-xl bg-bhoomi-canvas text-bhoomi-text-muted border border-bhoomi-border">
              <ShieldCheck className="h-4 w-4" />
            </div>
          </div>
          <div className="mt-3 flex items-baseline gap-2">
            <span className="text-3xl font-bold font-mono text-bhoomi-text-primary">
              {totalMonitored}
            </span>
            <span className="text-xs text-bhoomi-text-muted">labels evaluated</span>
          </div>
          <p className="mt-1 text-[11px] text-bhoomi-text-secondary">
            Active pathogens with validated records
          </p>
        </CardContent>
      </Card>

      {/* Surveillance Window */}
      <Card className="rounded-2xl border border-bhoomi-border bg-bhoomi-surface shadow-card overflow-hidden">
        <CardContent className="p-5">
          <div className="flex items-center justify-between">
            <span className="text-xs font-bold uppercase tracking-wider text-bhoomi-text-muted">
              Review Window
            </span>
            <div className="flex h-8 w-8 items-center justify-center rounded-xl bg-blue-50 text-blue-700 border border-blue-200">
              <Calendar className="h-4 w-4" />
            </div>
          </div>
          <div className="mt-3">
            <span className="text-sm font-bold text-bhoomi-text-primary block truncate font-mono" title={windowLabel}>
              {windowLabel}
            </span>
            <span className="text-xs text-bhoomi-text-muted">Server aggregation period</span>
          </div>
          <p className="mt-1 text-[11px] text-bhoomi-text-secondary">
            Data window returned by official API
          </p>
        </CardContent>
      </Card>
    </div>
  );
}
