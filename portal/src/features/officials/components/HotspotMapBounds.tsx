import { useEffect } from 'react';
import { useMap } from 'react-leaflet';
import L from 'leaflet';
import type { HotspotPoint } from '@/types/api';

interface HotspotMapBoundsProps {
  points: HotspotPoint[];
}

// Default to Maharashtra center if no data
const DEFAULT_CENTER: [number, number] = [19.7515, 75.7139];
const DEFAULT_ZOOM = 6;

export function HotspotMapBounds({ points }: HotspotMapBoundsProps) {
  const map = useMap();

  useEffect(() => {
    // Filter out invalid coordinates before processing
    const validPoints = points.filter(
      (p) => 
        typeof p.lat === 'number' && !isNaN(p.lat) && p.lat >= -90 && p.lat <= 90 &&
        typeof p.lng === 'number' && !isNaN(p.lng) && p.lng >= -180 && p.lng <= 180
    );

    if (validPoints.length === 0) {
      map.setView(DEFAULT_CENTER, DEFAULT_ZOOM);
      return;
    }

    const firstPoint = validPoints[0];
    if (validPoints.length === 1 && firstPoint) {
      map.setView([firstPoint.lat, firstPoint.lng], 10);
      return;
    }

    const bounds = L.latLngBounds(
      validPoints.map((p) => [p.lat, p.lng])
    );
    
    // Pad bounds slightly so markers aren't cut off at the edges
    map.fitBounds(bounds, { padding: [50, 50] });
  }, [map, points]);

  return null;
}
