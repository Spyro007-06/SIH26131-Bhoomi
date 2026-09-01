import { NavLink } from 'react-router-dom';
import { useAuth } from '@/features/auth/hooks';
import { cn } from '@/lib/utils/cn';
import {
  ClipboardList,
  LayoutDashboard,
  MapPin,
  Activity,
  ListChecks,
  ShieldCheck,
} from 'lucide-react';

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
    <aside className="w-72 shrink-0 border-r border-bhoomi-border bg-bhoomi-surface p-4 min-h-[calc(100vh-72px)] flex flex-col justify-between select-none">
      <div className="space-y-6">
        <div>
          <h2 className="px-3.5 text-[11px] font-bold uppercase tracking-wider text-bhoomi-text-disabled mb-2.5">
            {role === 'agronomist' ? 'Expert Workspace' : 'Surveillance Operations'}
          </h2>

          <nav className="space-y-1.5">
            {items.map((item) => (
              <NavLink
                key={item.to}
                to={item.to}
                className={({ isActive }) =>
                  cn(
                    'group flex items-center gap-3 rounded-xl px-3.5 py-3 text-sm font-medium transition-all duration-150 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-bhoomi-primary focus-visible:ring-offset-2',
                    isActive
                      ? 'bg-bhoomi-primary-light text-bhoomi-primary font-semibold border-l-4 border-bhoomi-primary shadow-xs'
                      : 'text-bhoomi-text-secondary hover:bg-bhoomi-primary-soft hover:text-bhoomi-primary-dark'
                  )
                }
              >
                {({ isActive }) => (
                  <>
                    <item.icon
                      className={cn(
                        'h-4 w-4 shrink-0 transition-colors duration-150',
                        isActive
                          ? 'text-bhoomi-primary'
                          : 'text-bhoomi-text-muted group-hover:text-bhoomi-primary'
                      )}
                    />
                    <div className="text-left flex-1 min-w-0">
                      <p className="leading-tight truncate">{item.label}</p>
                    </div>
                  </>
                )}
              </NavLink>
            ))}
          </nav>
        </div>
      </div>

      {/* Enterprise Shell Status Footer */}
      <div className="rounded-2xl border border-bhoomi-border bg-bhoomi-canvas p-3.5 text-xs text-bhoomi-text-muted space-y-1">
        <div className="flex items-center gap-1.5 text-bhoomi-text-primary font-semibold text-xs">
          <ShieldCheck className="h-3.5 w-3.5 text-bhoomi-primary" />
          <span>BHOOMI v3.0</span>
        </div>
        <p className="text-[11px] text-bhoomi-text-secondary leading-snug">
          Enterprise Operations Shell
        </p>
      </div>
    </aside>
  );
}
