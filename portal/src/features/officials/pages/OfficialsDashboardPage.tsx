import { DashboardHeader } from '../components/DashboardHeader';
import { HotspotPreview } from '../components/HotspotPreview';
import { AccuracyPreview } from '../components/AccuracyPreview';
import { QueuePreview } from '../components/QueuePreview';
export function OfficialsDashboardPage() {
  return (
    <div className="flex-1 flex flex-col h-full overflow-hidden bg-bhoomi-surface">
      <DashboardHeader 
        title="Agriculture Officials Dashboard" 
        subtitle="Operational overview of outbreak intelligence and model performance."
      />

      <main className="flex-1 p-4 md:p-6 lg:p-8 max-w-7xl w-full mx-auto overflow-y-auto space-y-6 pb-24">
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
          <section className="lg:col-span-2">
            <HotspotPreview />
          </section>
          
          <section>
            <AccuracyPreview />
          </section>

          <section className="lg:col-span-3">
            <QueuePreview />
          </section>
        </div>
      </main>
    </div>
  );
}
