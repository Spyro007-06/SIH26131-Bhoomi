import { Button } from '@/components/ui/Button';
import { ChevronDown, Loader2 } from 'lucide-react';

export interface QueuePaginationProps {
  hasNextPage?: boolean;
  isFetchingNextPage?: boolean;
  onLoadMore: () => void;
}

export function QueuePagination({
  hasNextPage,
  isFetchingNextPage,
  onLoadMore,
}: QueuePaginationProps) {
  if (!hasNextPage) {
    return null;
  }

  return (
    <div className="flex justify-center pt-4 pb-2">
      <Button
        variant="secondary"
        onClick={onLoadMore}
        disabled={isFetchingNextPage}
        className="min-w-[200px] gap-2 shadow-xs"
        aria-label="Load more cases"
      >
        {isFetchingNextPage ? (
          <>
            <Loader2 className="h-4 w-4 animate-spin text-bhoomi-primary shrink-0" />
            <span>Loading more cases...</span>
          </>
        ) : (
          <>
            <ChevronDown className="h-4 w-4 text-bhoomi-primary shrink-0" />
            <span>Load More Cases</span>
          </>
        )}
      </Button>
    </div>
  );
}
