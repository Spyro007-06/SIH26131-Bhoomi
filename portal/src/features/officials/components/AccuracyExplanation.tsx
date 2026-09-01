import { Info, CheckCircle2, AlertCircle, Sparkles } from 'lucide-react';
import { Card, CardContent } from '@/components/ui/Card';

export function AccuracyExplanation() {
  return (
    <Card className="border-blue-100 bg-blue-50/40 shadow-xs">
      <CardContent className="p-5">
        <div className="flex items-start gap-3">
          <div className="flex h-8 w-8 shrink-0 items-center justify-center rounded-lg bg-blue-100 text-blue-800">
            <Info className="h-4 w-4" />
          </div>
          <div className="space-y-3 text-xs text-bhoomi-text">
            <div>
              <h4 className="font-semibold text-sm text-bhoomi-text flex items-center gap-1.5">
                <span>Human-in-the-Loop Diagnostic Validation</span>
                <span className="inline-flex items-center gap-1 px-1.5 py-0.5 rounded bg-blue-100/80 text-[10px] font-medium text-blue-800">
                  <Sparkles className="h-2.5 w-2.5" />
                  Official Protocol
                </span>
              </h4>
              <p className="text-bhoomi-text-secondary mt-1 leading-relaxed">
                BHOOMI AI model hypotheses are reviewed by certified agricultural experts before official escalation or regional alert broadcast. The metrics displayed above reflect post-review outcomes:
              </p>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-2 gap-3 pt-1">
              <div className="flex items-start gap-2 bg-white/80 p-3 rounded-lg border border-blue-100">
                <CheckCircle2 className="h-4 w-4 text-bhoomi-green-700 shrink-0 mt-0.5" />
                <div>
                  <span className="font-semibold text-bhoomi-green-900 block">
                    Confirmed by Agronomist
                  </span>
                  <span className="text-bhoomi-text-secondary text-[11px] leading-normal">
                    The agronomist verified and agreed with the primary AI model diagnosis.
                  </span>
                </div>
              </div>

              <div className="flex items-start gap-2 bg-white/80 p-3 rounded-lg border border-amber-100">
                <AlertCircle className="h-4 w-4 text-amber-700 shrink-0 mt-0.5" />
                <div>
                  <span className="font-semibold text-amber-900 block">
                    Corrected by Agronomist
                  </span>
                  <span className="text-bhoomi-text-secondary text-[11px] leading-normal">
                    The agronomist modified the model diagnosis and provided the authoritative label.
                  </span>
                </div>
              </div>
            </div>

            <p className="text-[11px] text-bhoomi-text-tertiary pt-1 border-t border-blue-200/50">
              * Official accuracy figures are computed directly by the central surveillance service and cannot be modified by local portal clients.
            </p>
          </div>
        </div>
      </CardContent>
    </Card>
  );
}
