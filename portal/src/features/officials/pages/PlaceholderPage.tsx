import { DashboardHeader } from '../components/DashboardHeader';
import { Card, CardContent } from '@/components/ui/Card';
import { MapPin, Activity, ListTodo, Wrench } from 'lucide-react';

interface PlaceholderPageProps {
  title: string;
  subtitle: string;
  type: 'hotspots' | 'accuracy' | 'queue';
}

export function PlaceholderPage({ title, subtitle, type }: PlaceholderPageProps) {
  const Icon = {
    hotspots: MapPin,
    accuracy: Activity,
    queue: ListTodo,
  }[type];

  return (
    <div className="flex-1 overflow-auto bg-bhoomi-surface">
      <DashboardHeader title={title} subtitle={subtitle} />
      
      <main className="p-4 md:p-6 lg:p-8 max-w-7xl mx-auto">
        <Card className="border-dashed border-2 border-bhoomi-border shadow-none bg-bhoomi-surface-soft/30">
          <CardContent className="flex flex-col items-center justify-center py-20 text-center space-y-4">
            <div className="h-16 w-16 rounded-full bg-bhoomi-green-100 flex items-center justify-center text-bhoomi-green-700">
              <Icon className="h-8 w-8" />
            </div>
            <div className="space-y-2 max-w-md">
              <h3 className="text-lg font-bold text-bhoomi-text flex items-center justify-center gap-2">
                <Wrench className="h-5 w-5 text-bhoomi-text-secondary" />
                Under Construction
              </h3>
              <p className="text-sm text-bhoomi-text-secondary">
                This feature is scheduled for a future development phase. The foundation and API integration are established.
              </p>
            </div>
          </CardContent>
        </Card>
      </main>
    </div>
  );
}
