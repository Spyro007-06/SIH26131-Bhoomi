import { HelpCircle, Clock, CheckCircle, XCircle, HelpCircle as QuestionIcon } from 'lucide-react';
import { Card, CardHeader, CardTitle, CardContent } from '@/components/ui/Card';
import { Badge } from '@/components/ui/Badge';
import { formatDateTime } from '@/lib/utils/formatters';
import { FieldObservation } from '@/types/api';

interface FieldObservationsProps {
  observations: FieldObservation[];
}

export function FieldObservations({ observations }: FieldObservationsProps) {
  const getAnswerBadge = (answer: string) => {
    const lower = answer.toLowerCase();
    if (lower === 'yes') {
      return (
        <Badge variant="success" size="sm" className="gap-1 px-2 py-0.5">
          <CheckCircle className="h-3 w-3" /> Answer: Yes
        </Badge>
      );
    }
    if (lower === 'no') {
      return (
        <Badge variant="neutral" size="sm" className="gap-1 px-2 py-0.5">
          <XCircle className="h-3 w-3" /> Answer: No
        </Badge>
      );
    }
    return (
      <Badge variant="warning" size="sm" className="gap-1 px-2 py-0.5">
        <QuestionIcon className="h-3 w-3" /> Answer: Unknown
      </Badge>
    );
  };

  return (
    <Card className="rounded-2xl border border-bhoomi-border bg-bhoomi-surface shadow-card overflow-hidden">
      <CardHeader className="pb-3 border-b border-bhoomi-border/70 bg-bhoomi-canvas/40">
        <div className="flex items-center justify-between">
          <CardTitle className="text-xs font-bold uppercase tracking-wider text-bhoomi-text-muted flex items-center gap-1.5">
            <HelpCircle className="h-4 w-4 text-bhoomi-primary" />
            <span>Doubt Doctor · Field Observations</span>
          </CardTitle>
          <span className="text-xs text-bhoomi-text-muted">
            {observations.length} {observations.length === 1 ? 'response' : 'responses'}
          </span>
        </div>
      </CardHeader>
      <CardContent className="pt-4">
        {observations.length === 0 ? (
          <p className="text-xs text-bhoomi-text-muted italic">
            No interactive clarification observations recorded for this case.
          </p>
        ) : (
          <div className="space-y-3">
            {observations.map((obs, idx) => (
              <div
                key={idx}
                className="flex flex-col sm:flex-row sm:items-center justify-between gap-2 p-3 rounded-xl border border-bhoomi-border bg-bhoomi-canvas text-xs"
              >
                <div className="space-y-1 max-w-xl">
                  <p className="font-medium text-bhoomi-text-primary leading-relaxed">
                    &ldquo;{obs.question}&rdquo;
                  </p>
                  {obs.at && (
                    <span className="flex items-center gap-1 text-[11px] text-bhoomi-text-muted">
                      <Clock className="h-3 w-3 text-bhoomi-text-muted" />
                      {formatDateTime(obs.at)}
                    </span>
                  )}
                </div>
                <div className="shrink-0">{getAnswerBadge(obs.answer)}</div>
              </div>
            ))}
          </div>
        )}
      </CardContent>
    </Card>
  );
}
