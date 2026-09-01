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
    <div className="flex justify-center pt-6 pb-2">
      <Button
        variant="outline"
        onClick={onLoadMore}
        disabled={isFetchingNextPage}
        className="min-w-[180px] gap-2 shadow-xs"
        aria-label="Load more cases"
      >
        {isFetchingNextPage ? (
          <>
            <Loader2 className="h-4 w-4 animate-spin text-bhoomi-green-800" />
            Loading more...
          </>
        ) : (
          <>
            <ChevronDown className="h-4 w-4 text-bhoomi-green-800" />
            Load More Cases
          </>
        )}
      </Button>
    </div>
  );
}
