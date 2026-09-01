import { Info, CheckCircle2, AlertCircle, Sparkles } from 'lucide-react';
import { Card, CardContent } from '@/components/ui/Card';

export function AccuracyExplanation() {
  return (
    <Card className="rounded-2xl border border-blue-200 bg-blue-50/40 shadow-card">
      <CardContent className="p-5">
        <div className="flex items-start gap-3.5">
          <div className="flex h-9 w-9 shrink-0 items-center justify-center rounded-xl bg-blue-100 text-blue-800 border border-blue-200">
            <Info className="h-4 w-4" />
          </div>
          <div className="space-y-3 text-xs text-bhoomi-text-primary">
            <div>
              <h4 className="font-bold text-sm text-bhoomi-text-primary flex items-center gap-2">
                <span>Human-in-the-Loop Diagnostic Validation</span>
                <span className="inline-flex items-center gap-1 px-2 py-0.5 rounded-full bg-blue-100 text-[10px] font-semibold text-blue-800 border border-blue-200">
                  <Sparkles className="h-2.5 w-2.5" />
                  Official Protocol
                </span>
              </h4>
              <p className="text-bhoomi-text-secondary mt-1 leading-relaxed text-xs">
                BHOOMI AI model hypotheses are reviewed by certified agricultural experts before official escalation or regional alert broadcast. The metrics displayed above reflect post-review outcomes:
              </p>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-2 gap-3 pt-1">
              <div className="flex items-start gap-2.5 bg-bhoomi-surface p-3.5 rounded-xl border border-blue-100 shadow-xs">
                <CheckCircle2 className="h-4 w-4 text-bhoomi-primary shrink-0 mt-0.5" />
                <div>
                  <span className="font-bold text-xs text-bhoomi-primary-dark block">
                    Confirmed by Agronomist
                  </span>
                  <span className="text-bhoomi-text-secondary text-[11px] leading-normal mt-0.5 block">
                    The agronomist verified and agreed with the primary AI model diagnosis.
                  </span>
                </div>
              </div>

              <div className="flex items-start gap-2.5 bg-bhoomi-surface p-3.5 rounded-xl border border-amber-100 shadow-xs">
                <AlertCircle className="h-4 w-4 text-amber-700 shrink-0 mt-0.5" />
                <div>
                  <span className="font-bold text-xs text-amber-900 block">
                    Corrected by Agronomist
                  </span>
                  <span className="text-bhoomi-text-secondary text-[11px] leading-normal mt-0.5 block">
                    The agronomist modified the model diagnosis and provided the authoritative label.
                  </span>
                </div>
              </div>
            </div>

            <p className="text-[11px] text-bhoomi-text-muted pt-2 border-t border-blue-200/60">
              * Official accuracy figures are computed directly by the central surveillance service and cannot be modified by local portal clients.
            </p>
          </div>
        </div>
      </CardContent>
    </Card>
  );
}
