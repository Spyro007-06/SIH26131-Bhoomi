import { MapContainer, TileLayer, CircleMarker, Popup } from 'react-leaflet';
import { useOfficialHotspots } from '../hooks';
import { HotspotMapBounds } from './HotspotMapBounds';
import { formatTargetLabel } from '@/lib/utils/formatters';
import { formatDate } from '@/lib/utils/dates';
import { AlertCircle, RefreshCw, Map as MapIcon, ShieldCheck } from 'lucide-react';
import { Button } from '@/components/ui/Button';
import { Skeleton } from '@/components/ui/Skeleton';

// Define standard deep green for confirmed hotspots per requirements
const CONFIRMED_HOTSPOT_COLOR = '#166534';
const DEFAULT_CENTER: [number, number] = [19.7515, 75.7139];
const DEFAULT_ZOOM = 6;

// Helper to determine map radius based on confirmation count
function calculateRadius(count: number): number {
  return Math.max(6, Math.min(24, 4 + Math.sqrt(count) * 2));
}

export function OfficialHotspotMap() {
  const { data, isLoading, isError, error, refetch } = useOfficialHotspots();

  if (isLoading) {
    return (
      <div className="w-full h-[520px] lg:h-[620px] bg-bhoomi-surface rounded-2xl border border-bhoomi-border shadow-card flex flex-col overflow-hidden relative">
        <Skeleton className="absolute inset-0 rounded-2xl" />
        <div className="absolute inset-0 flex items-center justify-center bg-bhoomi-surface/60 backdrop-blur-xs z-10">
          <div className="flex flex-col items-center gap-2.5 p-6 rounded-2xl bg-bhoomi-surface/90 border border-bhoomi-border shadow-lg">
            <RefreshCw className="h-7 w-7 animate-spin text-bhoomi-primary" />
            <p className="font-semibold text-sm text-bhoomi-text-primary">Loading confirmed hotspot data...</p>
          </div>
        </div>
      </div>
    );
  }

  if (isError) {
    return (
      <div className="w-full h-[520px] lg:h-[620px] bg-bhoomi-surface rounded-2xl border border-red-200 shadow-card flex flex-col items-center justify-center p-6 text-center gap-4">
        <div className="h-12 w-12 rounded-2xl bg-red-100 border border-red-200 flex items-center justify-center">
          <AlertCircle className="h-6 w-6 text-red-600" />
        </div>
        <div>
          <h3 className="text-base font-bold text-bhoomi-text-primary">Unable to load confirmed hotspot data.</h3>
          <p className="text-xs text-bhoomi-text-muted mt-1 max-w-sm">
            Confirmed hotspot data is temporarily unavailable. 
            {error instanceof Error && <span className="block mt-1 text-xs text-red-700 font-mono">{error.message}</span>}
          </p>
        </div>
        <Button onClick={() => refetch()} className="mt-2 text-xs" variant="outline">
          <RefreshCw className="h-3.5 w-3.5 mr-1.5" />
          Retry
        </Button>
      </div>
    );
  }

  const points = data?.points || [];

  return (
    <div className="w-full h-[520px] lg:h-[620px] bg-bhoomi-surface rounded-2xl border border-bhoomi-border shadow-card flex flex-col overflow-hidden relative">
      {points.length === 0 && (
        <div className="absolute inset-0 flex items-center justify-center bg-bhoomi-surface/90 backdrop-blur-xs z-[400] pointer-events-none">
          <div className="flex flex-col items-center p-6 bg-bhoomi-surface rounded-2xl shadow-xl border border-bhoomi-border max-w-sm text-center">
            <MapIcon className="h-10 w-10 text-bhoomi-text-muted mb-3" />
            <h3 className="text-base font-bold text-bhoomi-text-primary">No confirmed hotspots available.</h3>
            <p className="text-xs text-bhoomi-text-muted mt-1">
              There are currently no confirmed agricultural outbreak records matching this criteria.
            </p>
          </div>
        </div>
      )}

      <MapContainer
        center={DEFAULT_CENTER}
        zoom={DEFAULT_ZOOM}
        className="w-full h-full z-0"
        preferCanvas={true}
        zoomControl={true}
      >
        <TileLayer
          attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
          url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
        />

        <HotspotMapBounds points={points} />

        {points.map((point) => {
          // Validate coordinates again just in case (already filtered in bounds, but need it here too)
          if (
            typeof point.lat !== 'number' || isNaN(point.lat) || point.lat < -90 || point.lat > 90 ||
            typeof point.lng !== 'number' || isNaN(point.lng) || point.lng < -180 || point.lng > 180
          ) {
            return null;
          }

          const radius = calculateRadius(point.confirmed_count);
          const formattedLabel = formatTargetLabel(point.label);
          const markerKey = `${point.lat}-${point.lng}-${point.label}`;

          return (
            <CircleMarker
              key={markerKey}
              center={[point.lat, point.lng]}
              radius={radius}
              pathOptions={{
                color: CONFIRMED_HOTSPOT_COLOR,
                fillColor: CONFIRMED_HOTSPOT_COLOR,
                fillOpacity: 0.75,
                weight: 2,
              }}
            >
              <Popup className="bhoomi-map-popup">
                <div className="min-w-[210px] p-1.5 font-sans">
                  <div className="flex items-center gap-1.5 pb-2 border-b border-bhoomi-border mb-2.5">
                    <span className="flex h-2 w-2 rounded-full bg-emerald-600 animate-pulse"></span>
                    <h4 className="font-bold text-xs text-bhoomi-text-primary uppercase tracking-wider flex items-center gap-1">
                      <ShieldCheck className="h-3.5 w-3.5 text-bhoomi-primary" />
                      Confirmed Outbreak
                    </h4>
                  </div>
                  
                  <div className="space-y-2">
                    <div>
                      <span className="block text-[11px] font-bold text-bhoomi-text-muted uppercase tracking-wider">Disease / Pest</span>
                      <span className="block text-xs text-bhoomi-text-primary font-bold">{formattedLabel}</span>
                    </div>
                    
                    <div>
                      <span className="block text-[11px] font-bold text-bhoomi-text-muted uppercase tracking-wider">Confirmed Cases</span>
                      <span className="block text-xs font-mono font-bold text-bhoomi-primary">{point.confirmed_count} records</span>
                    </div>

                    <div className="grid grid-cols-2 gap-2 pt-2 border-t border-bhoomi-border/70">
                      <div>
                        <span className="block text-[10px] font-bold text-bhoomi-text-muted uppercase tracking-wider">First Seen</span>
                        <span className="block text-[11px] text-bhoomi-text-secondary">{formatDate(point.first_seen)}</span>
                      </div>
                      <div>
                        <span className="block text-[10px] font-bold text-bhoomi-text-muted uppercase tracking-wider">Last Seen</span>
                        <span className="block text-[11px] text-bhoomi-text-secondary">{formatDate(point.last_seen)}</span>
                      </div>
                    </div>
                  </div>
                </div>
              </Popup>
            </CircleMarker>
          );
        })}
      </MapContainer>
      
      {points.length > 0 && (
        <div className="absolute bottom-4 left-4 z-[400] bg-bhoomi-surface/95 backdrop-blur-sm shadow-card border border-bhoomi-border rounded-xl p-3 text-xs flex flex-col gap-2">
          <div className="font-bold text-xs uppercase tracking-wider text-bhoomi-text-muted border-b border-bhoomi-border pb-1 mb-0.5">Legend</div>
          <div className="flex items-center gap-2 text-bhoomi-text-secondary">
            <span className="block h-3 w-3 rounded-full" style={{ backgroundColor: CONFIRMED_HOTSPOT_COLOR }}></span>
            <span className="font-medium text-xs text-bhoomi-text-primary">Confirmed outbreak location</span>
          </div>
          <div className="flex items-center gap-2 text-bhoomi-text-secondary">
            <span className="block h-3 w-3 rounded-full border border-emerald-800 bg-transparent" style={{ borderColor: CONFIRMED_HOTSPOT_COLOR }}></span>
            <span className="text-xs text-bhoomi-text-muted">Size scales with count</span>
          </div>
        </div>
      )}
    </div>
  );
}
