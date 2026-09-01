import { useState } from 'react';
import { Image as ImageIcon, ZoomIn, AlertCircle, Clock } from 'lucide-react';
import { Card, CardHeader, CardTitle, CardContent } from '@/components/ui/Card';
import { ImageLightbox } from './ImageLightbox';
import { formatRelativeTime } from '@/lib/utils/formatters';
import { CaseImage } from '@/types/api';

interface EvidenceGalleryProps {
  images: CaseImage[];
}

export function EvidenceGallery({ images }: EvidenceGalleryProps) {
  const [selectedImageIndex, setSelectedImageIndex] = useState<number | null>(null);
  const [failedImages, setFailedImages] = useState<Record<string, boolean>>({});

  const handleImageError = (assetId: string) => {
    setFailedImages((prev) => ({ ...prev, [assetId]: true }));
  };

  return (
    <>
      <Card className="shadow-subtle border-bhoomi-border bg-bhoomi-white">
        <CardHeader className="pb-3 border-b border-bhoomi-border/60">
          <div className="flex items-center justify-between">
            <CardTitle className="text-sm font-semibold uppercase tracking-wider text-bhoomi-text-secondary flex items-center gap-1.5">
              <ImageIcon className="h-4 w-4 text-bhoomi-green-700" />
              Field Image Evidence
            </CardTitle>
            <span className="text-xs text-bhoomi-text-secondary">
              {images.length} {images.length === 1 ? 'photo' : 'photos'} captured
            </span>
          </div>
        </CardHeader>
        <CardContent className="pt-4">
          {images.length === 0 ? (
            <div className="flex flex-col items-center justify-center p-8 text-center rounded-lg border border-dashed border-bhoomi-border bg-bhoomi-surface-soft/40 text-bhoomi-text-secondary">
              <ImageIcon className="h-8 w-8 text-bhoomi-text-secondary/60 mb-2" />
              <p className="text-sm font-medium">No images submitted for this case</p>
            </div>
          ) : (
            <div
              className={`grid gap-4 ${
                images.length === 1
                  ? 'grid-cols-1 max-w-md mx-auto'
                  : images.length === 2
                  ? 'grid-cols-1 sm:grid-cols-2'
                  : 'grid-cols-1 sm:grid-cols-2 lg:grid-cols-3'
              }`}
            >
              {images.map((img, idx) => {
                const isFailed = failedImages[img.asset_id];

                return (
                  <div
                    key={img.asset_id || idx}
                    className="group relative flex flex-col rounded-lg border border-bhoomi-border bg-bhoomi-surface-soft/40 overflow-hidden transition-all duration-200 hover:border-bhoomi-green-600/40 hover:shadow-card"
                  >
                    {/* Image Viewport */}
                    <div className="relative h-60 sm:h-72 w-full bg-stone-900/90 overflow-hidden flex items-center justify-center">
                      {isFailed ? (
                        <div className="flex flex-col items-center justify-center p-4 text-center text-stone-300">
                          <AlertCircle className="h-8 w-8 text-red-400 mb-2" />
                          <p className="text-xs font-medium">Failed to load asset</p>
                          <span className="font-mono text-[10px] text-stone-400 mt-0.5">
                            {img.asset_id}
                          </span>
                        </div>
                      ) : (
                        <>
                          <img
                            src={img.url}
                            alt={`Field sample photo ${idx + 1}`}
                            onError={() => handleImageError(img.asset_id)}
                            className="h-full w-full object-contain transition-transform duration-300 group-hover:scale-[1.02]"
                            loading="eager"
                          />
                          <button
                            type="button"
                            onClick={() => setSelectedImageIndex(idx)}
                            aria-label={`Enlarge photo ${idx + 1}`}
                            className="absolute inset-0 flex items-center justify-center bg-black/30 opacity-0 transition-opacity group-hover:opacity-100 focus-visible:opacity-100 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-bhoomi-green-600"
                          >
                            <span className="flex items-center gap-1.5 rounded-full bg-white/90 px-3 py-1.5 text-xs font-semibold text-bhoomi-text shadow-md">
                              <ZoomIn className="h-3.5 w-3.5" /> Enlarge
                            </span>
                          </button>
                        </>
                      )}
                    </div>

                    {/* Metadata Footer */}
                    <div className="flex items-center justify-between p-2.5 bg-bhoomi-white border-t border-bhoomi-border text-xs text-bhoomi-text-secondary">
                      <span className="font-mono font-medium text-bhoomi-text">
                        Asset #{img.asset_id}
                      </span>
                      {img.at && (
                        <span className="flex items-center gap-1 text-[11px]">
                          <Clock className="h-3 w-3 text-bhoomi-text-secondary/70" />
                          {formatRelativeTime(img.at)}
                        </span>
                      )}
                    </div>
                  </div>
                );
              })}
            </div>
          )}
        </CardContent>
      </Card>

      {/* Fullscreen accessible lightbox */}
      <ImageLightbox
        images={images}
        currentIndex={selectedImageIndex ?? 0}
        isOpen={selectedImageIndex !== null}
        onClose={() => setSelectedImageIndex(null)}
        onNavigate={(idx) => setSelectedImageIndex(idx)}
      />
    </>
  );
}
