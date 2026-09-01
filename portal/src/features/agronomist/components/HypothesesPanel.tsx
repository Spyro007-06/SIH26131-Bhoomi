import { BrainCircuit, Info } from 'lucide-react';
import { Card, CardHeader, CardTitle, CardContent } from '@/components/ui/Card';
import { formatTargetLabel } from '@/lib/utils/formatters';
import { Prediction } from '@/types/api';

interface HypothesesPanelProps {
  hypotheses: Prediction[];
}

export function HypothesesPanel({ hypotheses }: HypothesesPanelProps) {
  return (
    <Card className="shadow-subtle border-bhoomi-border bg-bhoomi-white">
      <CardHeader className="pb-3 border-b border-bhoomi-border/60">
        <div className="flex items-center justify-between">
          <CardTitle className="text-sm font-semibold uppercase tracking-wider text-bhoomi-text-secondary flex items-center gap-1.5">
            <BrainCircuit className="h-4 w-4 text-bhoomi-green-700" />
            Model Hypotheses
          </CardTitle>
          <span className="text-[11px] text-bhoomi-text-secondary">
            Ranked Candidates
          </span>
        </div>
      </CardHeader>
      <CardContent className="pt-4 space-y-3.5">
        {hypotheses.length === 0 ? (
          <p className="text-xs text-bhoomi-text-secondary italic">No hypotheses provided</p>
        ) : (
          hypotheses.map((hypothesis, index) => {
            const percentage = Math.round(hypothesis.confidence * 100);
            const isTop = index === 0;

            return (
              <div key={hypothesis.label || index} className="space-y-1.5">
                <div className="flex items-center justify-between text-xs">
                  <div className="flex items-center gap-2">
                    <span
                      className={`flex h-5 w-5 items-center justify-center rounded-full text-[11px] font-bold ${
                        isTop
                          ? 'bg-bhoomi-green-800 text-bhoomi-cream'
                          : 'bg-bhoomi-surface-soft text-bhoomi-text-secondary border border-bhoomi-border'
                      }`}
                    >
                      #{index + 1}
                    </span>
                    <span className="font-semibold text-bhoomi-text">
                      {formatTargetLabel(hypothesis.label)}
                    </span>
                  </div>
                  <span className="font-mono font-bold text-bhoomi-text">{percentage}%</span>
                </div>

                <div className="h-2 w-full overflow-hidden rounded-full bg-bhoomi-surface-soft border border-bhoomi-border/40">
                  <div
                    className={`h-full rounded-full transition-all duration-300 ${
                      isTop
                        ? 'bg-bhoomi-green-700'
                        : index === 1
                        ? 'bg-bhoomi-green-500'
                        : 'bg-bhoomi-green-300'
                    }`}
                    style={{ width: `${Math.min(100, Math.max(0, percentage))}%` }}
                  />
                </div>
              </div>
            );
          })
        )}

        <div className="pt-2 border-t border-bhoomi-border/40 flex items-start gap-1.5 text-[11px] text-bhoomi-text-secondary">
          <Info className="h-3.5 w-3.5 shrink-0 mt-0.5 text-bhoomi-text-secondary/70" />
          <span>Top candidates across all target classes. Confidence scores reflect raw model probabilities.</span>
        </div>
      </CardContent>
    </Card>
  );
}
