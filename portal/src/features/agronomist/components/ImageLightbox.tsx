import { useEffect } from 'react';
import { X, ChevronLeft, ChevronRight } from 'lucide-react';
import { formatDateTime } from '@/lib/utils/formatters';
import { CaseImage } from '@/types/api';

interface ImageLightboxProps {
  images: CaseImage[];
  currentIndex: number;
  isOpen: boolean;
  onClose: () => void;
  onNavigate: (index: number) => void;
}

export function ImageLightbox({
  images,
  currentIndex,
  isOpen,
  onClose,
  onNavigate,
}: ImageLightboxProps) {
  useEffect(() => {
    if (!isOpen) return;

    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.key === 'Escape') {
        onClose();
      } else if (e.key === 'ArrowLeft' && images.length > 1) {
        onNavigate((currentIndex - 1 + images.length) % images.length);
      } else if (e.key === 'ArrowRight' && images.length > 1) {
        onNavigate((currentIndex + 1) % images.length);
      }
    };

    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, [isOpen, currentIndex, images.length, onClose, onNavigate]);

  if (!isOpen || !images[currentIndex]) return null;

  const currentImage = images[currentIndex];

  return (
    <div
      role="dialog"
      aria-modal="true"
      aria-label="Image Lightbox"
      className="fixed inset-0 z-50 flex items-center justify-center bg-black/90 p-4 sm:p-6 backdrop-blur-sm animate-in fade-in duration-200"
      onClick={onClose}
    >
      {/* Lightbox Container */}
      <div
        className="relative flex flex-col max-h-full max-w-5xl w-full items-center justify-center"
        onClick={(e) => e.stopPropagation()}
      >
        {/* Top Control Bar */}
        <div className="flex w-full items-center justify-between text-white/90 mb-3 px-2">
          <div className="flex items-center gap-3 text-xs">
            <span className="font-mono bg-white/10 px-2.5 py-1 rounded">
              Asset: {currentImage.asset_id}
            </span>
            {currentImage.at && <span>Captured: {formatDateTime(currentImage.at)}</span>}
            <span className="text-white/60">
              ({currentIndex + 1} of {images.length})
            </span>
          </div>

          <button
            type="button"
            onClick={onClose}
            aria-label="Close Lightbox"
            className="flex h-9 w-9 items-center justify-center rounded-full bg-white/10 text-white hover:bg-white/20 transition-colors focus:outline-none focus:ring-2 focus:ring-white"
          >
            <X className="h-5 w-5" />
          </button>
        </div>

        {/* Main Image Frame */}
        <div className="relative flex items-center justify-center max-h-[75vh] w-full overflow-hidden rounded-lg bg-black/60 border border-white/10">
          <img
            src={currentImage.url}
            alt={`Field sample asset ${currentImage.asset_id}`}
            className="max-h-[75vh] w-auto max-w-full object-contain select-none"
          />

          {/* Previous Button */}
          {images.length > 1 && (
            <button
              type="button"
              onClick={() => onNavigate((currentIndex - 1 + images.length) % images.length)}
              aria-label="Previous Image"
              className="absolute left-3 top-1/2 -translate-y-1/2 flex h-10 w-10 items-center justify-center rounded-full bg-black/60 text-white hover:bg-black/80 transition-colors border border-white/20 focus:outline-none focus:ring-2 focus:ring-white"
            >
              <ChevronLeft className="h-6 w-6" />
            </button>
          )}

          {/* Next Button */}
          {images.length > 1 && (
            <button
              type="button"
              onClick={() => onNavigate((currentIndex + 1) % images.length)}
              aria-label="Next Image"
              className="absolute right-3 top-1/2 -translate-y-1/2 flex h-10 w-10 items-center justify-center rounded-full bg-black/60 text-white hover:bg-black/80 transition-colors border border-white/20 focus:outline-none focus:ring-2 focus:ring-white"
            >
              <ChevronRight className="h-6 w-6" />
            </button>
          )}
        </div>

        <p className="text-[11px] text-white/60 mt-2 text-center">
          Use Left/Right arrow keys to switch images, Escape to close
        </p>
      </div>
    </div>
  );
}
