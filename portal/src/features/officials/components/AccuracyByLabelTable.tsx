import {
  Table,
  TableHeader,
  TableBody,
  TableRow,
  TableHead,
  TableCell,
} from '@/components/ui/Table';
import { Card, CardHeader, CardTitle, CardContent } from '@/components/ui/Card';
import { Badge } from '@/components/ui/Badge';
import { formatTargetLabel } from '@/lib/utils/formatters';
import type { LabelAccuracy } from '@/types/api';

interface AccuracyByLabelTableProps {
  rows: LabelAccuracy[];
}

export function AccuracyByLabelTable({ rows }: AccuracyByLabelTableProps) {
  if (rows.length === 0) {
    return null;
  }

  return (
    <Card className="border-bhoomi-border bg-white shadow-sm overflow-hidden">
      <CardHeader className="pb-3 border-b border-bhoomi-border/60">
        <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-1">
          <div>
            <CardTitle className="text-base font-bold text-bhoomi-text">
              Diagnostic Performance by Target Disease
            </CardTitle>
            <p className="text-xs text-bhoomi-text-secondary mt-0.5">
              Breakdown of expert agronomist outcomes and backend-reported accuracy by crop disease
            </p>
          </div>
          <Badge variant="outline" className="text-xs self-start sm:self-auto font-mono text-bhoomi-text-secondary">
            {rows.length} Targets
          </Badge>
        </div>
      </CardHeader>
      <CardContent className="p-0">
        <Table className="w-full">
          <TableHeader>
            <TableRow>
              <TableHead className="w-[30%]">Disease / Pest Target</TableHead>
              <TableHead className="text-right w-[15%]">Confirmed</TableHead>
              <TableHead className="text-right w-[15%]">Corrected</TableHead>
              <TableHead className="text-right w-[15%]">Official Accuracy</TableHead>
              <TableHead className="w-[25%]">Performance Level</TableHead>
            </TableRow>
          </TableHeader>
          <TableBody>
            {rows.map((row) => {
              const accuracyPercent =
                row.accuracy !== null && row.accuracy !== undefined
                  ? `${Math.round(row.accuracy * 100)}%`
                  : 'N/A';

              const progressWidth =
                row.accuracy !== null && row.accuracy !== undefined
                  ? Math.min(100, Math.max(0, Math.round(row.accuracy * 100)))
                  : 0;

              return (
                <TableRow key={row.label} className="hover:bg-bhoomi-surface-soft/50">
                  <TableCell className="font-medium">
                    <div className="flex flex-col">
                      <span className="text-sm font-semibold text-bhoomi-text">
                        {formatTargetLabel(row.label)}
                      </span>
                      <span className="text-[11px] font-mono text-bhoomi-text-tertiary">
                        {row.label}
                      </span>
                    </div>
                  </TableCell>
                  <TableCell className="text-right">
                    <span className="font-mono font-semibold text-bhoomi-green-900 bg-bhoomi-green-50 px-2 py-0.5 rounded border border-bhoomi-green-200">
                      {row.confirmed}
                    </span>
                  </TableCell>
                  <TableCell className="text-right">
                    <span className="font-mono font-semibold text-amber-900 bg-amber-50 px-2 py-0.5 rounded border border-amber-200">
                      {row.corrected}
                    </span>
                  </TableCell>
                  <TableCell className="text-right font-mono font-bold text-sm text-bhoomi-green-950">
                    {accuracyPercent}
                  </TableCell>
                  <TableCell>
                    {row.accuracy !== null && row.accuracy !== undefined ? (
                      <div className="flex items-center gap-3">
                        <div className="h-2 w-full max-w-[140px] rounded-full bg-bhoomi-border overflow-hidden">
                          <div
                            className="h-full bg-bhoomi-green-600 rounded-full transition-all duration-300"
                            style={{ width: `${progressWidth}%` }}
                          />
                        </div>
                        <span className="text-xs text-bhoomi-text-secondary font-mono">
                          {progressWidth}%
                        </span>
                      </div>
                    ) : (
                      <span className="text-xs text-bhoomi-text-tertiary italic">
                        Insufficient sample
                      </span>
                    )}
                  </TableCell>
                </TableRow>
              );
            })}
          </TableBody>
        </Table>
      </CardContent>
    </Card>
  );
}
