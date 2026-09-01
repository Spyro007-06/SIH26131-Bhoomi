import { FlaskConical, Check } from 'lucide-react';
import { Card, CardHeader, CardTitle, CardContent } from '@/components/ui/Card';

interface TreatmentsTriedProps {
  treatments: string[];
}

export function TreatmentsTried({ treatments }: TreatmentsTriedProps) {
  return (
    <Card className="rounded-2xl border border-bhoomi-border bg-bhoomi-surface shadow-card overflow-hidden">
      <CardHeader className="pb-3 border-b border-bhoomi-border/70 bg-bhoomi-canvas/40">
        <div className="flex items-center justify-between">
          <CardTitle className="text-xs font-bold uppercase tracking-wider text-bhoomi-text-muted flex items-center gap-1.5">
            <FlaskConical className="h-4 w-4 text-bhoomi-primary" />
            <span>Treatments Already Tried</span>
          </CardTitle>
          <span className="text-xs text-bhoomi-text-muted">
            {treatments.length} logged
          </span>
        </div>
      </CardHeader>
      <CardContent className="pt-4">
        {treatments.length === 0 ? (
          <p className="text-xs text-bhoomi-text-muted italic">
            No previous treatments reported by the farmer before escalation.
          </p>
        ) : (
          <ul className="space-y-2 text-xs">
            {treatments.map((treatment, idx) => (
              <li
                key={idx}
                className="flex items-start gap-2 p-2.5 rounded-xl border border-bhoomi-border bg-bhoomi-canvas text-bhoomi-text-primary"
              >
                <div className="flex h-5 w-5 shrink-0 items-center justify-center rounded-md bg-bhoomi-primary-light text-bhoomi-primary mt-0.5 border border-bhoomi-primary/20">
                  <Check className="h-3 w-3" />
                </div>
                <span className="font-medium leading-relaxed">{treatment}</span>
              </li>
            ))}
          </ul>
        )}
      </CardContent>
    </Card>
  );
}
