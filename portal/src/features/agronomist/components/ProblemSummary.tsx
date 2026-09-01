import { AlertTriangle, Bug, Activity } from 'lucide-react';
import { Card, CardHeader, CardTitle, CardContent } from '@/components/ui/Card';
import { Badge } from '@/components/ui/Badge';
import { formatTargetLabel } from '@/lib/utils/formatters';
import { CaseProblem } from '@/types/api';

interface ProblemSummaryProps {
  problem: CaseProblem;
}

export function ProblemSummary({ problem }: ProblemSummaryProps) {
  const getSeverityBadge = (severity: string) => {
    switch (severity) {
      case 'severe':
        return <Badge variant="danger" size="sm">Severe</Badge>;
      case 'moderate':
        return <Badge variant="warning" size="sm">Moderate</Badge>;
      case 'early':
      default:
        return <Badge variant="info" size="sm">Early Stage</Badge>;
    }
  };

  return (
    <Card className="rounded-2xl border border-bhoomi-border bg-bhoomi-surface shadow-card overflow-hidden">
      <CardHeader className="pb-3 border-b border-bhoomi-border/70 bg-bhoomi-canvas/40">
        <div className="flex items-center justify-between">
          <CardTitle className="text-xs font-bold uppercase tracking-wider text-bhoomi-text-muted flex items-center gap-1.5">
            <Activity className="h-4 w-4 text-bhoomi-primary" />
            <span>Reported Issue</span>
          </CardTitle>
          <span className="font-mono text-xs text-bhoomi-text-secondary bg-bhoomi-surface px-2 py-0.5 rounded-md border border-bhoomi-border shadow-xs">
            {problem.id}
          </span>
        </div>
      </CardHeader>
      <CardContent className="pt-4 space-y-2">
        <div className="flex items-center gap-2">
          <Badge variant="neutral" size="sm" className="capitalize">
            {problem.type === 'pest' ? (
              <span className="flex items-center gap-1">
                <Bug className="h-3 w-3" /> Pest
              </span>
            ) : (
              <span className="flex items-center gap-1">
                <AlertTriangle className="h-3 w-3" /> Disease
              </span>
            )}
          </Badge>
          {getSeverityBadge(problem.severity)}
        </div>

        <div>
          <h2 className="text-xl font-bold tracking-tight text-bhoomi-text-primary">
            {formatTargetLabel(problem.label)}
          </h2>
          <span className="font-mono text-xs text-bhoomi-text-muted block mt-0.5">
            wire: {problem.label}
          </span>
        </div>
      </CardContent>
    </Card>
  );
}
