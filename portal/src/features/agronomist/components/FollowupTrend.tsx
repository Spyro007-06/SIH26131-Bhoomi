import { TrendingUp, TrendingDown, Minus, Volume2 } from 'lucide-react';
import { Card, CardHeader, CardTitle, CardContent } from '@/components/ui/Card';
import { Badge } from '@/components/ui/Badge';

interface FollowupTrendProps {
  trend?: string | null;
  spokenSummary?: string | null;
}

export function FollowupTrend({ trend, spokenSummary }: FollowupTrendProps) {
  const getTrendBadge = (trendValue?: string | null) => {
    switch (trendValue) {
      case 'improved':
        return (
          <Badge variant="success" className="gap-1 px-2.5 py-1">
            <TrendingUp className="h-3.5 w-3.5" /> Improved
          </Badge>
        );
      case 'got_worse':
        return (
          <Badge variant="danger" className="gap-1 px-2.5 py-1">
            <TrendingDown className="h-3.5 w-3.5" /> Got Worse
          </Badge>
        );
      case 'no_change':
        return (
          <Badge variant="warning" className="gap-1 px-2.5 py-1">
            <Minus className="h-3.5 w-3.5" /> No Change
          </Badge>
        );
      default:
        return (
          <span className="text-xs text-bhoomi-text-secondary italic">
            No follow-up logged yet
          </span>
        );
    }
  };

  return (
    <Card className="shadow-subtle border-bhoomi-border bg-bhoomi-white">
      <CardHeader className="pb-3 border-b border-bhoomi-border/60">
        <div className="flex items-center justify-between">
          <CardTitle className="text-sm font-semibold uppercase tracking-wider text-bhoomi-text-secondary flex items-center gap-1.5">
            <TrendingUp className="h-4 w-4 text-bhoomi-green-700" />
            Follow-up Progression & Summary
          </CardTitle>
          <div>{getTrendBadge(trend)}</div>
        </div>
      </CardHeader>
      <CardContent className="pt-4 space-y-3">
        {spokenSummary ? (
          <div className="rounded-lg border border-bhoomi-green-600/30 bg-bhoomi-surface-soft/60 p-3 text-xs">
            <div className="flex items-center gap-1.5 font-semibold text-bhoomi-green-900 mb-1">
              <Volume2 className="h-3.5 w-3.5 text-bhoomi-green-700" />
              Farmer Spoken Summary Note
            </div>
            <p className="text-bhoomi-text leading-relaxed italic">
              &ldquo;{spokenSummary}&rdquo;
            </p>
          </div>
        ) : (
          <p className="text-xs text-bhoomi-text-secondary italic">
            No spoken summary audio recorded for this case bundle.
          </p>
        )}
      </CardContent>
    </Card>
  );
}
