import { ShieldCheck, Clock, AlertTriangle, CheckCircle2 } from 'lucide-react';
import { Card, CardHeader, CardTitle, CardContent } from '@/components/ui/Card';
import { Badge } from '@/components/ui/Badge';
import { formatDateTime } from '@/lib/utils/formatters';
import { CaseLabelCheck } from '@/types/api';

interface LabelChecksProps {
  labelChecks: CaseLabelCheck[];
}

export function LabelChecks({ labelChecks }: LabelChecksProps) {
  const getVerdictBadge = (verdict: string) => {
    switch (verdict) {
      case 'NO_OBJECTION_FOUND':
        return (
          <Badge variant="success" className="gap-1">
            <CheckCircle2 className="h-3 w-3" /> No Objection
          </Badge>
        );
      case 'WRONG_CLASS':
        return (
          <Badge variant="danger" className="gap-1">
            <AlertTriangle className="h-3 w-3" /> Wrong Chemical Class
          </Badge>
        );
      case 'WRONG_CROP':
        return (
          <Badge variant="danger" className="gap-1">
            <AlertTriangle className="h-3 w-3" /> Wrong Crop
          </Badge>
        );
      case 'PHI_CONFLICT':
        return (
          <Badge variant="warning" className="gap-1">
            <AlertTriangle className="h-3 w-3" /> PHI Harvest Conflict
          </Badge>
        );
      default:
        return (
          <Badge variant="secondary" className="gap-1 font-mono">
            {verdict}
          </Badge>
        );
    }
  };

  return (
    <Card className="shadow-subtle border-bhoomi-border bg-bhoomi-white">
      <CardHeader className="pb-3 border-b border-bhoomi-border/60">
        <div className="flex items-center justify-between">
          <CardTitle className="text-sm font-semibold uppercase tracking-wider text-bhoomi-text-secondary flex items-center gap-1.5">
            <ShieldCheck className="h-4 w-4 text-bhoomi-green-700" />
            Pesticide Label Check History
          </CardTitle>
          <span className="text-xs text-bhoomi-text-secondary">
            {labelChecks.length} checks
          </span>
        </div>
      </CardHeader>
      <CardContent className="pt-4">
        {labelChecks.length === 0 ? (
          <p className="text-xs text-bhoomi-text-secondary italic">
            No chemical label checks queried for this problem instance.
          </p>
        ) : (
          <div className="space-y-2.5">
            {labelChecks.map((check, idx) => (
              <div
                key={idx}
                className="flex flex-col sm:flex-row sm:items-center justify-between gap-2 p-2.5 rounded-lg border border-bhoomi-border bg-bhoomi-surface-soft/30 text-xs"
              >
                <div className="space-y-0.5">
                  <div className="flex items-center gap-2">
                    <span className="font-semibold text-bhoomi-text capitalize">
                      {check.ingredient}
                    </span>
                  </div>
                  {check.at && (
                    <span className="flex items-center gap-1 text-[11px] text-bhoomi-text-secondary">
                      <Clock className="h-3 w-3 text-bhoomi-text-secondary/70" />
                      {formatDateTime(check.at)}
                    </span>
                  )}
                </div>
                <div className="shrink-0">{getVerdictBadge(check.verdict)}</div>
              </div>
            ))}
          </div>
        )}
      </CardContent>
    </Card>
  );
}
