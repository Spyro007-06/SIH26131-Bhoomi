import { FlaskConical, Check } from 'lucide-react';
import { Card, CardHeader, CardTitle, CardContent } from '@/components/ui/Card';

interface TreatmentsTriedProps {
  treatments: string[];
}

export function TreatmentsTried({ treatments }: TreatmentsTriedProps) {
  return (
    <Card className="shadow-subtle border-bhoomi-border bg-bhoomi-white">
      <CardHeader className="pb-3 border-b border-bhoomi-border/60">
        <div className="flex items-center justify-between">
          <CardTitle className="text-sm font-semibold uppercase tracking-wider text-bhoomi-text-secondary flex items-center gap-1.5">
            <FlaskConical className="h-4 w-4 text-bhoomi-green-700" />
            Treatments Already Tried
          </CardTitle>
          <span className="text-xs text-bhoomi-text-secondary">
            {treatments.length} logged
          </span>
        </div>
      </CardHeader>
      <CardContent className="pt-4">
        {treatments.length === 0 ? (
          <p className="text-xs text-bhoomi-text-secondary italic">
            No previous treatments reported by the farmer before escalation.
          </p>
        ) : (
          <ul className="space-y-2 text-xs">
            {treatments.map((treatment, idx) => (
              <li
                key={idx}
                className="flex items-start gap-2 p-2.5 rounded-lg border border-bhoomi-border bg-bhoomi-surface-soft/30 text-bhoomi-text"
              >
                <div className="flex h-5 w-5 shrink-0 items-center justify-center rounded-full bg-bhoomi-green-100 text-bhoomi-green-800 mt-0.5">
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
