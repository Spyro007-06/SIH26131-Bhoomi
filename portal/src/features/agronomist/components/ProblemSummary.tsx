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
        return <Badge variant="danger">Severe</Badge>;
      case 'moderate':
        return <Badge variant="warning">Moderate</Badge>;
      case 'early':
      default:
        return <Badge variant="info">Early Stage</Badge>;
    }
  };

  return (
    <Card className="shadow-subtle border-bhoomi-border bg-bhoomi-white">
      <CardHeader className="pb-3 border-b border-bhoomi-border/60">
        <div className="flex items-center justify-between">
          <CardTitle className="text-sm font-semibold uppercase tracking-wider text-bhoomi-text-secondary flex items-center gap-1.5">
            <Activity className="h-4 w-4 text-bhoomi-green-700" />
            Reported Issue
          </CardTitle>
          <span className="font-mono text-xs text-bhoomi-text-secondary/80 bg-bhoomi-surface-soft px-2 py-0.5 rounded border border-bhoomi-border/50">
            {problem.id}
          </span>
        </div>
      </CardHeader>
      <CardContent className="pt-4 space-y-4">
        <div>
          <div className="flex items-center gap-2 mb-1">
            <Badge variant="outline" className="capitalize text-xs">
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
          <h2 className="text-xl font-bold tracking-tight text-bhoomi-text">
            {formatTargetLabel(problem.label)}
          </h2>
          <span className="font-mono text-xs text-bhoomi-text-secondary">
            wire: {problem.label}
          </span>
        </div>
      </CardContent>
    </Card>
  );
}
