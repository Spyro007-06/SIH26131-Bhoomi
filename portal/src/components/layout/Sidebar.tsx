import { NavLink } from 'react-router-dom';
import { useAuth } from '@/features/auth/hooks';
import { cn } from '@/lib/utils/cn';
import { ClipboardList, LayoutDashboard, MapPin, Activity, ListChecks } from 'lucide-react';

export function Sidebar() {
  const { user } = useAuth();
  const role = user?.role;

  const agronomistNav = [
    {
      to: '/agronomist/cases',
      label: 'Case Queue',
      icon: ClipboardList,
      description: 'Pending escalated cases',
    },
  ];

  const officialNav = [
    {
      to: '/official',
      label: 'Dashboard',
      icon: LayoutDashboard,
      description: 'System overview',
    },
    {
      to: '/official/hotspots',
      label: 'Hotspots Map',
      icon: MapPin,
      description: 'Outbreak surveillance',
    },
    {
      to: '/official/accuracy',
      label: 'Model Accuracy',
      icon: Activity,
      description: 'Confirmed vs corrected',
    },
    {
      to: '/official/queue',
      label: 'Confirmation Queue',
      icon: ListChecks,
      description: 'Regional queue load',
    },
  ];

  const items = role === 'agronomist' ? agronomistNav : role === 'official' ? officialNav : [];

  return (
    <aside className="w-64 shrink-0 border-r border-bhoomi-border bg-bhoomi-white/80 backdrop-blur-sm p-4 min-h-[calc(100vh-4rem)] flex flex-col justify-between">
      <div className="space-y-6">
        <div>
          <h2 className="px-3 text-xs font-semibold uppercase tracking-wider text-bhoomi-text-secondary">
            {role === 'agronomist' ? 'Expert Workspace' : 'Surveillance'}
          </h2>
          <nav className="mt-2 space-y-1">
            {items.map((item) => (
              <NavLink
                key={item.to}
                to={item.to}
                className={({ isActive }) =>
                  cn(
                    'flex items-center gap-3 rounded-lg px-3 py-2.5 text-sm font-medium transition-colors',
                    isActive
                      ? 'bg-bhoomi-green-100 text-bhoomi-green-900 shadow-xs'
                      : 'text-bhoomi-text-secondary hover:bg-bhoomi-surface-soft hover:text-bhoomi-text'
                  )
                }
              >
                <item.icon className="h-4 w-4 shrink-0" />
                <div className="text-left">
                  <p className="leading-tight">{item.label}</p>
                </div>
              </NavLink>
            ))}
          </nav>
        </div>
      </div>

      <div className="rounded-card border border-bhoomi-border bg-bhoomi-surface-soft/60 p-3 text-xs text-bhoomi-text-secondary">
        <p className="font-medium text-bhoomi-text">BHOOMI v3.0</p>
        <p className="mt-0.5">Desktop Portal Foundation</p>
      </div>
    </aside>
  );
}
