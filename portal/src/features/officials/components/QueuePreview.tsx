import { Link } from 'react-router-dom';
import { ListTodo, ArrowRight, Clock, AlertTriangle, AlertCircle } from 'lucide-react';
import { Card, CardHeader, CardTitle, CardContent } from '@/components/ui/Card';
import { Badge } from '@/components/ui/Badge';
import { ErrorState } from '@/components/feedback/ErrorState';
import { formatTargetLabel } from '@/lib/utils/formatters';
import { useOfficialQueue } from '../hooks';

export function QueuePreview() {
  const { data, isLoading, isError, error, refetch } = useOfficialQueue({ limit: 5 });

  if (isLoading) {
    return (
      <Card className="h-full flex flex-col justify-between animate-pulse">
        <CardHeader className="pb-3 border-b border-bhoomi-border/60">
          <div className="h-5 w-44 bg-bhoomi-surface-soft rounded" />
          <div className="h-3.5 w-60 bg-bhoomi-surface-soft rounded mt-1.5" />
        </CardHeader>
        <CardContent className="pt-4 space-y-4 flex-1">
          <div className="space-y-3">
            {[1, 2, 3].map((i) => (
              <div key={i} className="h-12 bg-bhoomi-surface-soft rounded-lg" />
            ))}
          </div>
        </CardContent>
      </Card>
    );
  }

  if (isError) {
    return (
      <Card className="h-full border-red-200 bg-red-50/30">
        <CardHeader className="pb-2">
          <CardTitle className="text-base font-semibold text-bhoomi-text flex items-center gap-2">
            <ListTodo className="h-4 w-4 text-bhoomi-danger" />
            Confirmation Queue
          </CardTitle>
        </CardHeader>
        <CardContent>
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
    <Card className="h-full flex flex-col justify-between shadow-sm hover:border-bhoomi-green-600/40 transition-colors">
      <div>
        <CardHeader className="pb-3 border-b border-bhoomi-border/60">
          <div className="flex items-center justify-between gap-2">
            <div className="flex items-center gap-2">
              <div className="flex h-8 w-8 items-center justify-center rounded-lg bg-amber-100 text-amber-700">
                <ListTodo className="h-4 w-4" />
              </div>
              <div>
                <CardTitle className="text-base font-bold text-bhoomi-text">
                  Action Queue
                </CardTitle>
                <p className="text-xs text-bhoomi-text-secondary">
                  Recent cases pending agronomist confirmation
                </p>
              </div>
            </div>
            {pendingCount > 0 && (
              <Badge variant="outline" size="sm" className="bg-amber-50 text-amber-800 border-amber-200 gap-1 text-[11px]">
                <Clock className="h-3 w-3" />
                {pendingCount} Pending
              </Badge>
            )}
          </div>
        </CardHeader>

        <CardContent className="pt-4">
          {items.length === 0 ? (
            <div className="rounded-xl border border-dashed border-bhoomi-border p-6 text-center text-xs text-bhoomi-text-secondary space-y-2">
              <AlertCircle className="h-6 w-6 text-amber-500 mx-auto" />
              <p className="font-medium text-bhoomi-text">Queue is Empty</p>
              <p className="text-[11px]">
                No cases are currently pending confirmation.
              </p>
            </div>
          ) : (
            <div className="space-y-2.5">
              {items.slice(0, 4).map((item) => (
                <div
                  key={item.case_id}
                  className="flex items-center justify-between rounded-lg border border-bhoomi-border bg-bhoomi-surface-soft/60 p-2.5 text-xs transition-colors hover:bg-bhoomi-surface"
                >
                  <div className="space-y-1">
                    <p className="font-medium text-bhoomi-text">
                      {item.case_id}
                    </p>
                    <div className="flex items-center gap-2 text-[11px] text-bhoomi-text-secondary">
                      <span>{formatTargetLabel(item.predicted_label)}</span>
                      <span>·</span>
                      <span className={item.confidence < 0.6 ? 'text-amber-600 font-medium' : ''}>
                        {Math.round(item.confidence * 100)}% conf
                      </span>
                    </div>
                  </div>
                  <div className="flex flex-col items-end gap-1">
                    {item.severity === 'high' ? (
                      <Badge variant="danger" size="sm" className="h-5 px-1.5 text-[10px]">
                        <AlertTriangle className="h-3 w-3 mr-1" />
                        High
                      </Badge>
                    ) : (
                      <Badge variant="outline" size="sm" className="h-5 px-1.5 text-[10px] uppercase">
                        {item.severity}
                      </Badge>
                    )}
                    <span className="text-[10px] text-bhoomi-text-secondary">
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
          className="inline-flex w-full items-center justify-center gap-2 rounded-lg border border-bhoomi-border bg-bhoomi-surface-soft/80 px-3 py-2 text-xs font-semibold text-bhoomi-text hover:bg-bhoomi-surface-soft hover:text-bhoomi-green-900 transition-colors shadow-xs"
        >
          <span>View Full Action Queue</span>
          <ArrowRight className="h-3.5 w-3.5" />
        </Link>
      </div>
    </Card>
  );
}
