import { Link } from 'react-router-dom';
import { ListTodo, ArrowRight, Clock, AlertTriangle, AlertCircle } from 'lucide-react';
import { Card, CardHeader, CardTitle, CardContent } from '@/components/ui/Card';
import { Badge } from '@/components/ui/Badge';
import { Skeleton } from '@/components/ui/Skeleton';
import { ErrorState } from '@/components/feedback/ErrorState';
import { formatTargetLabel } from '@/lib/utils/formatters';
import { useOfficialQueue } from '../hooks';

export function QueuePreview() {
  const { data, isLoading, isError, error, refetch } = useOfficialQueue({ limit: 5 });

  if (isLoading) {
    return (
      <Card className="rounded-2xl border border-bhoomi-border bg-bhoomi-surface shadow-card overflow-hidden h-full flex flex-col justify-between">
        <CardHeader className="pb-3 border-b border-bhoomi-border/70 bg-bhoomi-canvas/40">
          <Skeleton className="h-5 w-44 rounded-lg" />
          <Skeleton className="h-3.5 w-60 rounded-md mt-1.5" />
        </CardHeader>
        <CardContent className="pt-4 space-y-4 flex-1">
          <div className="space-y-3">
            {[1, 2, 3].map((i) => (
              <Skeleton key={i} className="h-14 rounded-xl" />
            ))}
          </div>
        </CardContent>
      </Card>
    );
  }

  if (isError) {
    return (
      <Card className="rounded-2xl border border-red-200 bg-red-50/30 shadow-card overflow-hidden h-full">
        <CardHeader className="pb-2 border-b border-red-100">
          <CardTitle className="text-base font-semibold text-bhoomi-text-primary flex items-center gap-2">
            <ListTodo className="h-4 w-4 text-red-600" />
            <span>Confirmation Queue</span>
          </CardTitle>
        </CardHeader>
        <CardContent className="pt-4">
          <ErrorState
            error={error}
            title="Failed to Load Queue"
            onRetry={() => refetch()}
          />
        </CardContent>
      </Card>
    );
  }

  const items = data?.queue || [];
  const pendingCount = items.length;

  return (
    <Card className="rounded-2xl border border-bhoomi-border bg-bhoomi-surface shadow-card overflow-hidden h-full flex flex-col justify-between hover:border-bhoomi-primary/40 transition-all duration-200">
      <div>
        <CardHeader className="pb-3 border-b border-bhoomi-border/70 bg-bhoomi-canvas/40">
          <div className="flex items-center justify-between gap-2">
            <div className="flex items-center gap-2.5">
              <div className="flex h-8 w-8 items-center justify-center rounded-xl bg-amber-100 text-amber-800 border border-amber-300">
                <ListTodo className="h-4 w-4" />
              </div>
              <div>
                <CardTitle className="text-base font-bold text-bhoomi-text-primary">
                  Action Queue
                </CardTitle>
                <p className="text-xs text-bhoomi-text-muted">
                  Recent cases pending agronomist confirmation
                </p>
              </div>
            </div>
            {pendingCount > 0 && (
              <Badge variant="warning" size="sm" className="gap-1 text-[11px]">
                <Clock className="h-3 w-3" />
                <span>{pendingCount} Pending</span>
              </Badge>
            )}
          </div>
        </CardHeader>

        <CardContent className="pt-4">
          {items.length === 0 ? (
            <div className="rounded-xl border border-dashed border-bhoomi-border p-6 text-center text-xs text-bhoomi-text-secondary space-y-2 bg-bhoomi-canvas/40">
              <AlertCircle className="h-6 w-6 text-amber-500 mx-auto" />
              <p className="font-semibold text-bhoomi-text-primary">Queue is Empty</p>
              <p className="text-[11px] text-bhoomi-text-muted">
                No cases are currently pending confirmation.
              </p>
            </div>
          ) : (
            <div className="space-y-2.5">
              {items.slice(0, 4).map((item) => (
                <div
                  key={item.case_id}
                  className="flex items-center justify-between rounded-xl border border-bhoomi-border bg-bhoomi-canvas p-3 text-xs transition-colors hover:bg-bhoomi-primary-soft/50 shadow-xs"
                >
                  <div className="space-y-1">
                    <p className="font-semibold text-bhoomi-text-primary font-mono text-xs">
                      {item.case_id}
                    </p>
                    <div className="flex items-center gap-2 text-[11px] text-bhoomi-text-secondary">
                      <span className="font-medium text-bhoomi-text-primary">{formatTargetLabel(item.predicted_label)}</span>
                      <span>·</span>
                      <span className={item.confidence < 0.6 ? 'text-amber-700 font-semibold' : 'text-bhoomi-text-muted'}>
                        {Math.round(item.confidence * 100)}% conf
                      </span>
                    </div>
                  </div>
                  <div className="flex flex-col items-end gap-1">
                    {item.severity === 'high' ? (
                      <Badge variant="danger" size="sm" className="h-5 px-2 text-[10px] gap-1">
                        <AlertTriangle className="h-3 w-3" />
                        <span>High</span>
                      </Badge>
                    ) : (
                      <Badge variant="neutral" size="sm" className="h-5 px-2 text-[10px] uppercase">
                        {item.severity}
                      </Badge>
                    )}
                    <span className="text-[10px] text-bhoomi-text-muted">
                      {new Date(item.created_at).toLocaleDateString()}
                    </span>
                  </div>
                </div>
              ))}
            </div>
          )}
        </CardContent>
      </div>

      <div className="p-4 pt-0">
        <Link
          to="/official/queue"
          className="inline-flex w-full items-center justify-center gap-2 rounded-xl border border-bhoomi-border bg-bhoomi-canvas px-3 py-2.5 text-xs font-semibold text-bhoomi-text-primary hover:bg-bhoomi-primary-light hover:text-bhoomi-primary hover:border-bhoomi-primary/30 transition-colors shadow-xs"
        >
          <span>View Full Action Queue</span>
          <ArrowRight className="h-3.5 w-3.5" />
        </Link>
      </div>
    </Card>
  );
}
