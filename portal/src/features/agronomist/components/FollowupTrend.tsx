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
          <Badge variant="success" size="sm" className="gap-1 px-2.5 py-0.5">
            <TrendingUp className="h-3.5 w-3.5" /> Improved
          </Badge>
        );
      case 'got_worse':
        return (
          <Badge variant="danger" size="sm" className="gap-1 px-2.5 py-0.5">
            <TrendingDown className="h-3.5 w-3.5" /> Got Worse
          </Badge>
        );
      case 'no_change':
        return (
          <Badge variant="warning" size="sm" className="gap-1 px-2.5 py-0.5">
            <Minus className="h-3.5 w-3.5" /> No Change
          </Badge>
        );
      default:
        return (
          <span className="text-xs text-bhoomi-text-muted italic">
            No follow-up logged yet
          </span>
        );
    }
  };

  return (
    <Card className="rounded-2xl border border-bhoomi-border bg-bhoomi-surface shadow-card overflow-hidden">
      <CardHeader className="pb-3 border-b border-bhoomi-border/70 bg-bhoomi-canvas/40">
        <div className="flex items-center justify-between">
          <CardTitle className="text-xs font-bold uppercase tracking-wider text-bhoomi-text-muted flex items-center gap-1.5">
            <TrendingUp className="h-4 w-4 text-bhoomi-primary" />
            <span>Follow-up Progression & Summary</span>
          </CardTitle>
          <div>{getTrendBadge(trend)}</div>
        </div>
      </CardHeader>
      <CardContent className="pt-4 space-y-3">
        {spokenSummary ? (
          <div className="rounded-xl border border-bhoomi-primary/20 bg-bhoomi-primary-soft p-3 text-xs">
            <div className="flex items-center gap-1.5 font-bold text-bhoomi-primary mb-1">
              <Volume2 className="h-3.5 w-3.5" />
              <span>Farmer Spoken Summary Note</span>
            </div>
            <p className="text-bhoomi-text-primary leading-relaxed italic">
              &ldquo;{spokenSummary}&rdquo;
            </p>
          </div>
        ) : (
          <p className="text-xs text-bhoomi-text-muted italic">
            No spoken summary audio recorded for this case bundle.
          </p>
        )}
      </CardContent>
    </Card>
  );
}
