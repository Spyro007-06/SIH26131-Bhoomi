import { ShieldCheck, AlertTriangle, CheckCircle2, Clock } from 'lucide-react';
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
          <Badge variant="success" size="sm" className="gap-1">
            <CheckCircle2 className="h-3 w-3" /> No Objection
          </Badge>
        );
      case 'WRONG_CLASS':
        return (
          <Badge variant="danger" size="sm" className="gap-1">
            <AlertTriangle className="h-3 w-3" /> Wrong Chemical Class
          </Badge>
        );
      case 'WRONG_CROP':
        return (
          <Badge variant="danger" size="sm" className="gap-1">
            <AlertTriangle className="h-3 w-3" /> Wrong Crop
          </Badge>
        );
      case 'PHI_CONFLICT':
        return (
          <Badge variant="warning" size="sm" className="gap-1">
            <AlertTriangle className="h-3 w-3" /> PHI Conflict
          </Badge>
        );
      case 'DOSE_OUT_OF_RANGE':
        return (
          <Badge variant="warning" size="sm" className="gap-1">
            <AlertTriangle className="h-3 w-3" /> Dose Out of Range
          </Badge>
        );
      default:
        return (
          <Badge variant="neutral" size="sm" className="gap-1">
            {verdict}
          </Badge>
        );
    }
  };

  return (
    <Card className="rounded-2xl border border-bhoomi-border bg-bhoomi-surface shadow-card overflow-hidden">
      <CardHeader className="pb-3 border-b border-bhoomi-border/70 bg-bhoomi-canvas/40">
        <div className="flex items-center justify-between">
          <CardTitle className="text-xs font-bold uppercase tracking-wider text-bhoomi-text-muted flex items-center gap-1.5">
            <ShieldCheck className="h-4 w-4 text-bhoomi-primary" />
            <span>Pesticide Label Check History</span>
          </CardTitle>
          <span className="text-xs text-bhoomi-text-muted">
            {labelChecks.length} {labelChecks.length === 1 ? 'check' : 'checks'}
          </span>
        </div>
      </CardHeader>
      <CardContent className="pt-4">
        {labelChecks.length === 0 ? (
          <p className="text-xs text-bhoomi-text-muted italic">
            No chemical label checks queried for this problem instance.
          </p>
        ) : (
          <div className="space-y-2.5">
            {labelChecks.map((check, idx) => (
              <div
                key={idx}
                className="flex flex-col sm:flex-row sm:items-center justify-between gap-2 p-3 rounded-xl border border-bhoomi-border bg-bhoomi-canvas text-xs"
              >
                <div className="space-y-0.5">
                  <div className="flex items-center gap-2">
                    <span className="font-semibold text-bhoomi-text-primary capitalize">
                      {check.ingredient}
                    </span>
                  </div>
                  {check.at && (
                    <span className="flex items-center gap-1 text-[11px] text-bhoomi-text-muted">
                      <Clock className="h-3 w-3 text-bhoomi-text-muted" />
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
