import { Sprout, MapPin, Layers, Hash } from 'lucide-react';
import { Card, CardHeader, CardTitle, CardContent } from '@/components/ui/Card';
import { FarmSummary } from '@/types/api';

interface FarmContextProps {
  farm: FarmSummary;
}

export function FarmContext({ farm }: FarmContextProps) {
  return (
    <Card className="shadow-subtle border-bhoomi-border bg-bhoomi-white">
      <CardHeader className="pb-3 border-b border-bhoomi-border/60">
        <div className="flex items-center justify-between">
          <CardTitle className="text-sm font-semibold uppercase tracking-wider text-bhoomi-text-secondary flex items-center gap-1.5">
            <Sprout className="h-4 w-4 text-bhoomi-green-700" />
            Farm Context
          </CardTitle>
          <span className="font-mono text-xs text-bhoomi-text-secondary/80 bg-bhoomi-surface-soft px-2 py-0.5 rounded border border-bhoomi-border/50">
            {farm.id}
          </span>
        </div>
      </CardHeader>
      <CardContent className="pt-4 grid grid-cols-2 gap-4 sm:grid-cols-4">
        {/* Crop & Variety */}
        <div>
          <span className="text-xs font-medium text-bhoomi-text-secondary block">Crop & Variety</span>
          <p className="text-sm font-semibold text-bhoomi-text capitalize mt-0.5">
            {farm.crop}
            {farm.variety ? (
              <span className="font-normal text-bhoomi-text-secondary ml-1">({farm.variety})</span>
            ) : null}
          </p>
        </div>

        {/* Growth Stage */}
        <div>
          <span className="text-xs font-medium text-bhoomi-text-secondary block flex items-center gap-1">
            <Layers className="h-3 w-3 text-bhoomi-text-secondary/70" />
            Growth Stage
          </span>
          <p className="text-sm font-semibold text-bhoomi-text capitalize mt-0.5">
            {farm.growth_stage.replace(/_/g, ' ')}
          </p>
        </div>

        {/* Region */}
        <div>
          <span className="text-xs font-medium text-bhoomi-text-secondary block flex items-center gap-1">
            <MapPin className="h-3 w-3 text-bhoomi-text-secondary/70" />
            Region
          </span>
          <p className="text-sm font-semibold text-bhoomi-text mt-0.5">
            {farm.region || 'Maharashtra'}
          </p>
        </div>

        {/* Farm Identifier */}
        <div>
          <span className="text-xs font-medium text-bhoomi-text-secondary block flex items-center gap-1">
            <Hash className="h-3 w-3 text-bhoomi-text-secondary/70" />
            Farm ID
          </span>
          <p className="text-sm font-mono font-medium text-bhoomi-text mt-0.5">
            {farm.id}
          </p>
        </div>
      </CardContent>
    </Card>
  );
}
