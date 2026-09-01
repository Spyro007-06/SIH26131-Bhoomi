import { HTMLAttributes } from 'react';
import { cn } from '@/lib/utils/cn';

export type SkeletonProps = HTMLAttributes<HTMLDivElement>;

export function Skeleton({ className, ...props }: SkeletonProps) {
  return (
    <div
      className={cn('animate-pulse rounded-md bg-bhoomi-surface-soft border border-bhoomi-border/30', className)}
      {...props}
    />
  );
}
