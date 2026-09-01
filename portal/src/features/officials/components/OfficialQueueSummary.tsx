import { ListTodo, AlertTriangle, MapPin, CheckCircle2 } from 'lucide-react';
import { Card, CardContent } from '@/components/ui/Card';
import type { OfficialQueueItem } from '@/types/api';

interface OfficialQueueSummaryProps {
  items: OfficialQueueItem[];
}

export function OfficialQueueSummary({ items }: OfficialQueueSummaryProps) {
  const totalCount = items.length;
  const highSeverityCount = items.filter(
    (i) => i.severity?.toLowerCase() === 'high' || i.severity?.toLowerCase() === 'severe'
  ).length;
  const uniqueRegions = new Set(items.map((i) => i.region)).size;
  const highConfidenceCount = items.filter((i) => i.confidence >= 0.8).length;

  return (
    <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
      {/* Total Active Queue */}
      <Card className="rounded-2xl border border-bhoomi-border bg-bhoomi-surface shadow-card overflow-hidden">
        <CardContent className="p-5">
          <div className="flex items-center justify-between">
            <span className="text-xs font-bold uppercase tracking-wider text-bhoomi-text-muted">
              Active Queue
            </span>
            <div className="flex h-8 w-8 items-center justify-center rounded-xl bg-amber-100 text-amber-800 border border-amber-300">
              <ListTodo className="h-4 w-4" />
            </div>
          </div>
          <div className="mt-3 flex items-baseline gap-2">
            <span className="text-3xl font-bold font-mono text-bhoomi-text-primary">
              {totalCount}
            </span>
            <span className="text-xs text-bhoomi-text-muted">records pending</span>
          </div>
          <p className="mt-1 text-[11px] text-bhoomi-text-secondary">
            Cases awaiting agronomist review
          </p>
        </CardContent>
      </Card>

      {/* High Severity */}
      <Card className="rounded-2xl border border-red-200 bg-red-50/30 shadow-card overflow-hidden">
        <CardContent className="p-5">
          <div className="flex items-center justify-between">
            <span className="text-xs font-bold uppercase tracking-wider text-red-800">
              High Severity
            </span>
            <div className="flex h-8 w-8 items-center justify-center rounded-xl bg-red-100 text-red-800 border border-red-200">
              <AlertTriangle className="h-4 w-4" />
            </div>
          </div>
          <div className="mt-3 flex items-baseline gap-2">
            <span className="text-3xl font-bold font-mono text-red-900">
              {highSeverityCount}
            </span>
            <span className="text-xs text-red-800/80">critical cases</span>
          </div>
          <p className="mt-1 text-[11px] text-red-800/70">
            Priority surveillance attention
          </p>
        </CardContent>
      </Card>

      {/* Monitored Regions */}
      <Card className="rounded-2xl border border-bhoomi-border bg-bhoomi-surface shadow-card overflow-hidden">
        <CardContent className="p-5">
          <div className="flex items-center justify-between">
            <span className="text-xs font-bold uppercase tracking-wider text-bhoomi-text-muted">
              Active Regions
            </span>
            <div className="flex h-8 w-8 items-center justify-center rounded-xl bg-blue-50 text-blue-700 border border-blue-200">
              <MapPin className="h-4 w-4" />
            </div>
          </div>
          <div className="mt-3 flex items-baseline gap-2">
            <span className="text-3xl font-bold font-mono text-bhoomi-text-primary">
              {uniqueRegions}
            </span>
            <span className="text-xs text-bhoomi-text-muted">districts active</span>
          </div>
          <p className="mt-1 text-[11px] text-bhoomi-text-secondary">
            Geographic jurisdictions represented
          </p>
        </CardContent>
      </Card>

      {/* High Confidence Predictions */}
      <Card className="rounded-2xl border border-bhoomi-primary/20 bg-bhoomi-surface shadow-card overflow-hidden">
        <CardContent className="p-5">
          <div className="flex items-center justify-between">
            <span className="text-xs font-bold uppercase tracking-wider text-bhoomi-text-muted">
              High Model Conf
            </span>
            <div className="flex h-8 w-8 items-center justify-center rounded-xl bg-bhoomi-primary-light text-bhoomi-primary border border-bhoomi-primary/20">
              <CheckCircle2 className="h-4 w-4" />
            </div>
          </div>
          <div className="mt-3 flex items-baseline gap-2">
            <span className="text-3xl font-bold font-mono text-bhoomi-primary-dark">
              {highConfidenceCount}
            </span>
            <span className="text-xs text-bhoomi-text-muted">≥ 80% confidence</span>
          </div>
          <p className="mt-1 text-[11px] text-bhoomi-text-secondary">
            Strong preliminary model hypotheses
          </p>
        </CardContent>
      </Card>
    </div>
  );
}
