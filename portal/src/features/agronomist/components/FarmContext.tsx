import { Sprout, MapPin, Layers, Hash } from 'lucide-react';
import { Card, CardHeader, CardTitle, CardContent } from '@/components/ui/Card';
import { FarmSummary } from '@/types/api';

interface FarmContextProps {
  farm: FarmSummary;
}

export function FarmContext({ farm }: FarmContextProps) {
  return (
    <Card className="rounded-2xl border border-bhoomi-border bg-bhoomi-surface shadow-card overflow-hidden">
      <CardHeader className="pb-3 border-b border-bhoomi-border/70 bg-bhoomi-canvas/40">
        <div className="flex items-center justify-between">
          <CardTitle className="text-xs font-bold uppercase tracking-wider text-bhoomi-text-muted flex items-center gap-1.5">
            <Sprout className="h-4 w-4 text-bhoomi-primary" />
            <span>Farm Context</span>
          </CardTitle>
          <span className="font-mono text-xs text-bhoomi-text-secondary bg-bhoomi-surface px-2 py-0.5 rounded-md border border-bhoomi-border shadow-xs">
            {farm.id}
          </span>
        </div>
      </CardHeader>
      <CardContent className="pt-4 grid grid-cols-2 gap-4 sm:grid-cols-4">
        {/* Crop & Variety */}
        <div>
          <span className="text-[11px] font-bold text-bhoomi-text-muted uppercase tracking-wider block">
            Crop & Variety
          </span>
          <p className="text-sm font-semibold text-bhoomi-text-primary capitalize mt-1">
            {farm.crop}
            {farm.variety ? (
              <span className="font-normal text-bhoomi-text-secondary ml-1">({farm.variety})</span>
            ) : null}
          </p>
        </div>

        {/* Growth Stage */}
        <div>
          <span className="text-[11px] font-bold text-bhoomi-text-muted uppercase tracking-wider block flex items-center gap-1">
            <Layers className="h-3 w-3 text-bhoomi-text-muted" />
            Growth Stage
          </span>
          <p className="text-sm font-semibold text-bhoomi-text-primary capitalize mt-1">
            {farm.growth_stage.replace(/_/g, ' ')}
          </p>
        </div>

        {/* Region */}
        <div>
          <span className="text-[11px] font-bold text-bhoomi-text-muted uppercase tracking-wider block flex items-center gap-1">
            <MapPin className="h-3 w-3 text-bhoomi-text-muted" />
            Region
          </span>
          <p className="text-sm font-semibold text-bhoomi-text-primary mt-1">
            {farm.region || 'Maharashtra'}
          </p>
        </div>

        {/* Farm Identifier */}
        <div>
          <span className="text-[11px] font-bold text-bhoomi-text-muted uppercase tracking-wider block flex items-center gap-1">
            <Hash className="h-3 w-3 text-bhoomi-text-muted" />
            Farm ID
          </span>
          <p className="text-sm font-mono font-medium text-bhoomi-text-primary mt-1">
            {farm.id}
          </p>
        </div>
      </CardContent>
    </Card>
  );
}
