import { HTMLAttributes } from 'react';
import { cn } from '@/lib/utils/cn';

export type SkeletonProps = HTMLAttributes<HTMLDivElement>;

export function Skeleton({ className, ...props }: SkeletonProps) {
  return (
    <div
      className={cn('animate-pulse rounded-xl bg-slate-100 border border-slate-200/50', className)}
      {...props}
    />
  );
}
