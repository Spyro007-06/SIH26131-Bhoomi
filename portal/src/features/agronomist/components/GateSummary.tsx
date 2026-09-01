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
        return <Badge variant="success" size="sm" className="capitalize">Advise</Badge>;
      case 'clarify':
        return <Badge variant="warning" size="sm" className="capitalize">Clarify (Doubt Doctor)</Badge>;
      case 'escalate':
      default:
        return <Badge variant="danger" size="sm" className="capitalize">Escalate to Expert</Badge>;
    }
  };

  return (
    <Card className="rounded-2xl border border-bhoomi-border bg-bhoomi-surface shadow-card overflow-hidden">
      <CardHeader className="pb-3 border-b border-bhoomi-border/70 bg-bhoomi-canvas/40">
        <div className="flex items-center justify-between">
          <CardTitle className="text-xs font-bold uppercase tracking-wider text-bhoomi-text-muted flex items-center gap-1.5">
            <GitFork className="h-4 w-4 text-bhoomi-primary" />
            <span>Decision Gate Context</span>
          </CardTitle>
          {getOutcomeBadge(gate.outcome)}
        </div>
      </CardHeader>
      <CardContent className="pt-4 grid grid-cols-2 gap-3 text-xs sm:grid-cols-3">
        <div>
          <span className="text-[11px] font-bold text-bhoomi-text-muted uppercase tracking-wider block">
            Outcome
          </span>
          <span className="font-semibold text-bhoomi-text-primary capitalize mt-1 block">
            {gate.outcome}
          </span>
        </div>

        <div>
          <span className="text-[11px] font-bold text-bhoomi-text-muted uppercase tracking-wider block">
            Reason Code
          </span>
          <span className="font-mono font-medium text-bhoomi-text-primary mt-1 block">
            {gate.reason_code || 'N/A'}
          </span>
        </div>

        {gate.threshold_applied !== undefined && gate.threshold_applied !== null && (
          <div>
            <span className="text-[11px] font-bold text-bhoomi-text-muted uppercase tracking-wider block">
              Applied Margin / Gate
            </span>
            <span className="font-mono font-medium text-bhoomi-text-primary mt-1 block">
              {gate.threshold_applied}
            </span>
          </div>
        )}

        {gate.is_stub && (
          <div className="col-span-full pt-2">
            <div className="rounded-xl border border-amber-300 bg-amber-50 p-2.5 text-amber-900 text-xs flex items-center gap-2">
              <ShieldAlert className="h-4 w-4 shrink-0 text-amber-700" />
              <span>Vision classification running with stub fallback flag.</span>
            </div>
          </div>
        )}
      </CardContent>
    </Card>
  );
}
