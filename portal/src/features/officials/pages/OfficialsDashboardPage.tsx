import { DashboardHeader } from '../components/DashboardHeader';
import { HotspotPreview } from '../components/HotspotPreview';
import { AccuracyPreview } from '../components/AccuracyPreview';
import { QueuePreview } from '../components/QueuePreview';

export function OfficialsDashboardPage() {
  return (
    <div className="space-y-6 max-w-7xl mx-auto pb-20">
      <DashboardHeader 
        title="Agriculture Officials Dashboard" 
        subtitle="Operational overview of outbreak intelligence and model performance."
      />

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6 items-stretch">
        <section className="lg:col-span-2">
          <HotspotPreview />
        </section>
        
        <section className="lg:col-span-1">
          <AccuracyPreview />
        </section>

        <section className="lg:col-span-3">
          <QueuePreview />
        </section>
      </div>
    </div>
  );
}
