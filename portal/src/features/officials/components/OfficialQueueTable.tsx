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
import { AlertTriangle, MapPin } from 'lucide-react';
import { formatTargetLabel, formatDateTime } from '@/lib/utils/formatters';
import type { OfficialQueueItem } from '@/types/api';

interface OfficialQueueTableProps {
  items: OfficialQueueItem[];
}

export function OfficialQueueTable({ items }: OfficialQueueTableProps) {
  if (items.length === 0) {
    return null;
  }

  return (
    <Card className="rounded-2xl border border-bhoomi-border bg-bhoomi-surface shadow-card overflow-hidden">
      <CardHeader className="pb-3 border-b border-bhoomi-border/70 bg-bhoomi-canvas/40">
        <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-1">
          <div>
            <CardTitle className="text-base font-bold text-bhoomi-text-primary">
              Official Confirmation Records
            </CardTitle>
            <p className="text-xs text-bhoomi-text-muted mt-0.5">
              Live cases awaiting expert agronomist validation and official confirmation
            </p>
          </div>
          <Badge variant="outline" className="text-xs self-start sm:self-auto font-mono text-bhoomi-text-muted">
            {items.length} Records
          </Badge>
        </div>
      </CardHeader>
      <CardContent className="p-0">
        <Table className="w-full">
          <TableHeader>
            <TableRow>
              <TableHead className="w-[18%]">Case Identifier</TableHead>
              <TableHead className="w-[28%]">Predicted Diagnosis</TableHead>
              <TableHead className="w-[14%] text-right">Confidence</TableHead>
              <TableHead className="w-[14%]">Region</TableHead>
              <TableHead className="w-[12%] text-center">Severity</TableHead>
              <TableHead className="w-[14%] text-right">Logged At</TableHead>
            </TableRow>
          </TableHeader>
          <TableBody>
            {items.map((item) => {
              const confidencePercent = Math.round(item.confidence * 100);
              const isHighSeverity =
                item.severity?.toLowerCase() === 'high' || item.severity?.toLowerCase() === 'severe';
              const isModerateSeverity = item.severity?.toLowerCase() === 'moderate';

              return (
                <TableRow key={item.case_id} className="hover:bg-bhoomi-primary-soft/40 transition-colors">
                  {/* Case ID */}
                  <TableCell className="font-mono text-xs font-bold text-bhoomi-text-primary">
                    <span className="bg-bhoomi-canvas px-2.5 py-1 rounded-lg border border-bhoomi-border inline-block shadow-xs">
                      {item.case_id}
                    </span>
                  </TableCell>

                  {/* Predicted Diagnosis */}
                  <TableCell>
                    <div className="flex flex-col">
                      <span className="text-xs font-bold text-bhoomi-text-primary">
                        {formatTargetLabel(item.predicted_label)}
                      </span>
                      <span className="text-[11px] font-mono text-bhoomi-text-muted">
                        {item.predicted_label}
                      </span>
                    </div>
                  </TableCell>

                  {/* Model Confidence */}
                  <TableCell className="text-right">
                    <div className="flex flex-col items-end">
                      <span
                        className={`font-mono font-bold text-xs ${
                          item.confidence >= 0.8
                            ? 'text-bhoomi-primary-dark'
                            : item.confidence < 0.6
                            ? 'text-amber-800'
                            : 'text-bhoomi-text-primary'
                        }`}
                      >
                        {confidencePercent}%
                      </span>
                      <span className="text-[10px] text-bhoomi-text-muted">model estimate</span>
                    </div>
                  </TableCell>

                  {/* Region */}
                  <TableCell className="capitalize text-xs font-semibold text-bhoomi-text-secondary">
                    <div className="flex items-center gap-1">
                      <MapPin className="h-3 w-3 text-bhoomi-text-muted" />
                      <span>{item.region}</span>
                    </div>
                  </TableCell>

                  {/* Severity Badge */}
                  <TableCell className="text-center">
                    {isHighSeverity ? (
                      <Badge variant="danger" size="sm" className="font-semibold gap-1 text-[11px]">
                        <AlertTriangle className="h-3 w-3" />
                        <span className="capitalize">{item.severity}</span>
                      </Badge>
                    ) : isModerateSeverity ? (
                      <Badge variant="warning" size="sm" className="font-semibold capitalize text-[11px]">
                        {item.severity}
                      </Badge>
                    ) : (
                      <Badge variant="outline" size="sm" className="font-semibold capitalize text-[11px]">
                        {item.severity}
                      </Badge>
                    )}
                  </TableCell>

                  {/* Logged At */}
                  <TableCell className="text-right text-xs text-bhoomi-text-muted whitespace-nowrap font-mono">
                    {formatDateTime(item.created_at)}
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
