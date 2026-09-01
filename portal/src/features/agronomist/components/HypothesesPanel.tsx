import { BrainCircuit, Info } from 'lucide-react';
import { Card, CardHeader, CardTitle, CardContent } from '@/components/ui/Card';
import { formatTargetLabel } from '@/lib/utils/formatters';
import { Prediction } from '@/types/api';

interface HypothesesPanelProps {
  hypotheses: Prediction[];
}

export function HypothesesPanel({ hypotheses }: HypothesesPanelProps) {
  return (
    <Card className="rounded-2xl border border-bhoomi-border bg-bhoomi-surface shadow-card overflow-hidden">
      <CardHeader className="pb-3 border-b border-bhoomi-border/70 bg-bhoomi-canvas/40">
        <div className="flex items-center justify-between">
          <CardTitle className="text-xs font-bold uppercase tracking-wider text-bhoomi-text-muted flex items-center gap-1.5">
            <BrainCircuit className="h-4 w-4 text-bhoomi-primary" />
            <span>Model Hypotheses</span>
          </CardTitle>
          <span className="text-[11px] font-medium text-bhoomi-text-muted">
            Ranked Candidates
          </span>
        </div>
      </CardHeader>
      <CardContent className="pt-4 space-y-3.5">
        {hypotheses.length === 0 ? (
          <p className="text-xs text-bhoomi-text-muted italic">No hypotheses provided</p>
        ) : (
          hypotheses.map((hypothesis, index) => {
            const percentage = Math.round(hypothesis.confidence * 100);
            const isTop = index === 0;

            return (
              <div key={hypothesis.label || index} className="space-y-1.5">
                <div className="flex items-center justify-between text-xs">
                  <div className="flex items-center gap-2">
                    <span
                      className={`flex h-5 w-5 items-center justify-center rounded-md text-[11px] font-bold shadow-xs ${
                        isTop
                          ? 'bg-bhoomi-primary text-white'
                          : 'bg-bhoomi-canvas text-bhoomi-text-secondary border border-bhoomi-border'
                      }`}
                    >
                      #{index + 1}
                    </span>
                    <span className="font-semibold text-bhoomi-text-primary">
                      {formatTargetLabel(hypothesis.label)}
                    </span>
                  </div>
                  <span className="font-mono font-bold text-bhoomi-text-primary">{percentage}%</span>
                </div>

                <div className="h-2 w-full overflow-hidden rounded-full bg-bhoomi-canvas border border-bhoomi-border/40">
                  <div
                    className={`h-full rounded-full transition-all duration-300 ${
                      isTop
                        ? 'bg-bhoomi-primary'
                        : index === 1
                        ? 'bg-emerald-500'
                        : 'bg-emerald-400'
                    }`}
                    style={{ width: `${Math.min(100, Math.max(0, percentage))}%` }}
                  />
                </div>
              </div>
            );
          })
        )}

        <div className="pt-2 border-t border-bhoomi-border/60 flex items-start gap-1.5 text-[11px] text-bhoomi-text-muted">
          <Info className="h-3.5 w-3.5 shrink-0 mt-0.5 text-bhoomi-text-muted" />
          <span>Top candidates across all target classes. Confidence scores reflect raw model probabilities.</span>
        </div>
      </CardContent>
    </Card>
  );
}
