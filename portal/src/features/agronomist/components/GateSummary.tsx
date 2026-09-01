import { ShieldAlert, GitFork } from 'lucide-react';
import { Card, CardHeader, CardTitle, CardContent } from '@/components/ui/Card';
import { Badge } from '@/components/ui/Badge';
import { GateInfo } from '@/types/api';

interface GateSummaryProps {
  gate: GateInfo;
}

export function GateSummary({ gate }: GateSummaryProps) {
  const getOutcomeBadge = (outcome: string) => {
    switch (outcome) {
      case 'advise':
        return <Badge variant="success" className="capitalize">Advise</Badge>;
      case 'clarify':
        return <Badge variant="warning" className="capitalize">Clarify (Doubt Doctor)</Badge>;
      case 'escalate':
      default:
        return <Badge variant="danger" className="capitalize">Escalate to Expert</Badge>;
    }
  };

  return (
    <Card className="shadow-subtle border-bhoomi-border bg-bhoomi-white">
      <CardHeader className="pb-3 border-b border-bhoomi-border/60">
        <div className="flex items-center justify-between">
          <CardTitle className="text-sm font-semibold uppercase tracking-wider text-bhoomi-text-secondary flex items-center gap-1.5">
            <GitFork className="h-4 w-4 text-bhoomi-green-700" />
            Decision Gate Context
          </CardTitle>
          {getOutcomeBadge(gate.outcome)}
        </div>
      </CardHeader>
      <CardContent className="pt-4 grid grid-cols-2 gap-3 text-xs sm:grid-cols-3">
        <div>
          <span className="text-bhoomi-text-secondary block font-medium">Outcome</span>
          <span className="font-semibold text-bhoomi-text capitalize">{gate.outcome}</span>
        </div>

        <div>
          <span className="text-bhoomi-text-secondary block font-medium">Reason Code</span>
          <span className="font-mono font-medium text-bhoomi-text">
            {gate.reason_code || 'N/A'}
          </span>
        </div>

        {gate.threshold_applied !== undefined && gate.threshold_applied !== null && (
          <div>
            <span className="text-bhoomi-text-secondary block font-medium">Applied Margin / Gate</span>
            <span className="font-mono font-medium text-bhoomi-text">
              {gate.threshold_applied}
            </span>
          </div>
        )}

        {gate.is_stub && (
          <div className="col-span-full pt-2">
            <div className="rounded border border-amber-300 bg-amber-50 p-2 text-amber-900 text-xs flex items-center gap-2">
              <ShieldAlert className="h-4 w-4 shrink-0" />
              <span>Vision classification running with stub fallback flag.</span>
            </div>
          </div>
        )}
      </CardContent>
    </Card>
  );
}
