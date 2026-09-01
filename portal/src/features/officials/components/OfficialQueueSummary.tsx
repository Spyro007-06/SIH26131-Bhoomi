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
      <Card className="border-bhoomi-border bg-white shadow-sm overflow-hidden">
        <CardContent className="p-5">
          <div className="flex items-center justify-between">
            <span className="text-xs font-semibold uppercase tracking-wider text-bhoomi-text-secondary">
              Active Queue
            </span>
            <div className="flex h-8 w-8 items-center justify-center rounded-lg bg-amber-100 text-amber-800">
              <ListTodo className="h-4 w-4" />
            </div>
          </div>
          <div className="mt-3 flex items-baseline gap-2">
            <span className="text-3xl font-bold font-mono text-bhoomi-text">
              {totalCount}
            </span>
            <span className="text-xs text-bhoomi-text-secondary">records pending</span>
          </div>
          <p className="mt-1 text-[11px] text-bhoomi-text-tertiary">
            Cases awaiting agronomist review
          </p>
        </CardContent>
      </Card>

      {/* High Severity */}
      <Card className="border-red-200/60 bg-white shadow-sm overflow-hidden">
        <CardContent className="p-5">
          <div className="flex items-center justify-between">
            <span className="text-xs font-semibold uppercase tracking-wider text-bhoomi-text-secondary">
              High Severity
            </span>
            <div className="flex h-8 w-8 items-center justify-center rounded-lg bg-red-100 text-red-800">
              <AlertTriangle className="h-4 w-4" />
            </div>
          </div>
          <div className="mt-3 flex items-baseline gap-2">
            <span className="text-3xl font-bold font-mono text-red-900">
              {highSeverityCount}
            </span>
            <span className="text-xs text-bhoomi-text-secondary">critical cases</span>
          </div>
          <p className="mt-1 text-[11px] text-bhoomi-text-tertiary">
            Priority surveillance attention
          </p>
        </CardContent>
      </Card>

      {/* Monitored Regions */}
      <Card className="border-bhoomi-border bg-white shadow-sm overflow-hidden">
        <CardContent className="p-5">
          <div className="flex items-center justify-between">
            <span className="text-xs font-semibold uppercase tracking-wider text-bhoomi-text-secondary">
              Active Regions
            </span>
            <div className="flex h-8 w-8 items-center justify-center rounded-lg bg-blue-50 text-blue-700">
              <MapPin className="h-4 w-4" />
            </div>
          </div>
          <div className="mt-3 flex items-baseline gap-2">
            <span className="text-3xl font-bold font-mono text-bhoomi-text">
              {uniqueRegions}
            </span>
            <span className="text-xs text-bhoomi-text-secondary">districts active</span>
          </div>
          <p className="mt-1 text-[11px] text-bhoomi-text-tertiary">
            Geographic jurisdictions represented
          </p>
        </CardContent>
      </Card>

      {/* High Confidence Predictions */}
      <Card className="border-bhoomi-green-600/30 bg-white shadow-sm overflow-hidden">
        <CardContent className="p-5">
          <div className="flex items-center justify-between">
            <span className="text-xs font-semibold uppercase tracking-wider text-bhoomi-text-secondary">
              High Model Conf
            </span>
            <div className="flex h-8 w-8 items-center justify-center rounded-lg bg-bhoomi-green-100 text-bhoomi-green-800">
              <CheckCircle2 className="h-4 w-4" />
            </div>
          </div>
          <div className="mt-3 flex items-baseline gap-2">
            <span className="text-3xl font-bold font-mono text-bhoomi-green-900">
              {highConfidenceCount}
            </span>
            <span className="text-xs text-bhoomi-text-secondary">≥ 80% confidence</span>
          </div>
          <p className="mt-1 text-[11px] text-bhoomi-text-tertiary">
            Strong preliminary model hypotheses
          </p>
        </CardContent>
      </Card>
    </div>
  );
}
