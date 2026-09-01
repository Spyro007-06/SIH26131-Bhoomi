import { HTMLAttributes, TdHTMLAttributes, ThHTMLAttributes, forwardRef } from 'react';
import { cn } from '@/lib/utils/cn';

export const Table = forwardRef<HTMLTableElement, HTMLAttributes<HTMLTableElement>>(
  ({ className, ...props }, ref) => (
    <div className="relative w-full overflow-auto rounded-2xl border border-bhoomi-border bg-bhoomi-surface shadow-xs">
      <table ref={ref} className={cn('w-full caption-bottom text-sm', className)} {...props} />
    </div>
  )
);
Table.displayName = 'Table';

export const TableHeader = forwardRef<
  HTMLTableSectionElement,
  HTMLAttributes<HTMLTableSectionElement>
>(({ className, ...props }, ref) => (
  <thead
    ref={ref}
    className={cn('bg-bhoomi-canvas border-b border-bhoomi-border', className)}
    {...props}
  />
));
TableHeader.displayName = 'TableHeader';

export const TableBody = forwardRef<
  HTMLTableSectionElement,
  HTMLAttributes<HTMLTableSectionElement>
>(({ className, ...props }, ref) => (
  <tbody ref={ref} className={cn('[&_tr:last-child]:border-0', className)} {...props} />
));
TableBody.displayName = 'TableBody';

export const TableFooter = forwardRef<
  HTMLTableSectionElement,
  HTMLAttributes<HTMLTableSectionElement>
>(({ className, ...props }, ref) => (
  <tfoot
    ref={ref}
    className={cn('bg-bhoomi-canvas font-medium border-t border-bhoomi-border', className)}
    {...props}
  />
));
TableFooter.displayName = 'TableFooter';

export const TableRow = forwardRef<HTMLTableRowElement, HTMLAttributes<HTMLTableRowElement>>(
  ({ className, ...props }, ref) => (
    <tr
      ref={ref}
      className={cn(
        'border-b border-slate-100 transition-colors hover:bg-bhoomi-canvas/80 data-[state=selected]:bg-bhoomi-primary-soft',
        className
      )}
      {...props}
    />
  )
);
TableRow.displayName = 'TableRow';

export const TableHead = forwardRef<
  HTMLTableCellElement,
  ThHTMLAttributes<HTMLTableCellElement>
>(({ className, ...props }, ref) => (
  <th
    ref={ref}
    className={cn(
      'h-11 px-4 text-left align-middle font-bold text-bhoomi-text-muted text-[11px] uppercase tracking-wider',
      className
    )}
    {...props}
  />
));
TableHead.displayName = 'TableHead';

export const TableCell = forwardRef<
  HTMLTableCellElement,
  TdHTMLAttributes<HTMLTableCellElement>
>(({ className, ...props }, ref) => (
  <td ref={ref} className={cn('p-4 align-middle text-bhoomi-text-primary', className)} {...props} />
));
TableCell.displayName = 'TableCell';

export const TableCaption = forwardRef<
  HTMLTableCaptionElement,
  HTMLAttributes<HTMLTableCaptionElement>
>(({ className, ...props }, ref) => (
  <caption ref={ref} className={cn('mt-4 text-sm text-bhoomi-text-muted', className)} {...props} />
));
TableCaption.displayName = 'TableCaption';
