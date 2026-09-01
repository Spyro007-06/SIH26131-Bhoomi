import { CaseQueueItem } from '@/types/api';
import {
  Table,
  TableHeader,
  TableBody,
  TableRow,
  TableHead,
  TableCell,
} from '@/components/ui/Table';
import { Skeleton } from '@/components/ui/Skeleton';
import { CaseQueueRow } from './CaseQueueRow';

export interface CaseQueueTableProps {
  cases: CaseQueueItem[];
  isLoading?: boolean;
}

export function CaseQueueTable({ cases, isLoading }: CaseQueueTableProps) {
  return (
    <div className="rounded-xl border border-bhoomi-border bg-bhoomi-surface shadow-sm overflow-hidden">
      <div className="overflow-x-auto">
        <Table>
          <TableHeader>
            <TableRow className="bg-bhoomi-background/50 hover:bg-bhoomi-background/50">
              <TableHead className="w-20 font-semibold text-bhoomi-text">Queue #</TableHead>
              <TableHead className="w-32 font-semibold text-bhoomi-text">Case ID</TableHead>
              <TableHead className="font-semibold text-bhoomi-text">Target Problem</TableHead>
              <TableHead className="w-36 font-semibold text-bhoomi-text">Region</TableHead>
              <TableHead className="w-28 font-semibold text-bhoomi-text">Status</TableHead>
              <TableHead className="w-32 font-semibold text-bhoomi-text">Received</TableHead>
              <TableHead className="w-24 text-right font-semibold text-bhoomi-text">Action</TableHead>
            </TableRow>
          </TableHeader>

          <TableBody>
            {isLoading ? (
              Array.from({ length: 5 }).map((_, index) => (
                <TableRow key={`skeleton-row-${index}`}>
                  <TableCell>
                    <Skeleton className="h-5 w-10" />
                  </TableCell>
                  <TableCell>
                    <Skeleton className="h-4 w-20" />
                  </TableCell>
                  <TableCell>
                    <Skeleton className="h-4 w-40" />
                  </TableCell>
                  <TableCell>
                    <Skeleton className="h-4 w-24" />
                  </TableCell>
                  <TableCell>
                    <Skeleton className="h-5 w-16" />
                  </TableCell>
                  <TableCell>
                    <Skeleton className="h-4 w-20" />
                  </TableCell>
                  <TableCell className="text-right">
                    <Skeleton className="h-8 w-16 ml-auto" />
                  </TableCell>
                </TableRow>
              ))
            ) : (
              cases.map((caseItem) => (
                <CaseQueueRow key={caseItem.case_id} item={caseItem} />
              ))
            )}
          </TableBody>
        </Table>
      </div>
    </div>
  );
}
