import { useAuth } from '@/features/auth/hooks';
import { Button } from '@/components/ui/Button';
import { Badge } from '@/components/ui/Badge';
import { LogOut, Sprout, Activity } from 'lucide-react';

export function Header() {
  const { user, logout } = useAuth();

  const userInitial = user?.name ? user.name.charAt(0).toUpperCase() : 'U';
  const roleLabel =
    user?.role === 'agronomist'
      ? 'Agronomist Portal'
      : user?.role === 'official'
      ? 'Officials Dashboard'
      : 'BHOOMI Portal';

  return (
    <header className="sticky top-0 z-30 flex h-[72px] w-full items-center justify-between border-b border-bhoomi-border bg-bhoomi-surface px-6 shadow-xs transition-colors">
      {/* Brand & Portal Identity Area */}
      <div className="flex items-center gap-3.5">
        <div className="flex h-10 w-10 shrink-0 items-center justify-center rounded-xl bg-bhoomi-primary text-white shadow-xs">
          <Sprout className="h-6 w-6" />
        </div>

        <div className="flex items-center gap-3">
          <div>
            <div className="flex items-center gap-2.5">
              <span className="text-xl font-bold tracking-tight text-bhoomi-text-primary">
                BHOOMI
              </span>
              {user?.role && (
                <Badge variant="primary" size="sm" className="hidden sm:inline-flex">
                  {roleLabel}
                </Badge>
              )}
            </div>
            <p className="text-xs text-bhoomi-text-muted leading-none mt-0.5 hidden sm:block">
              Government of Maharashtra · Crop Health System
            </p>
          </div>

          <div className="h-8 w-px bg-bhoomi-border hidden md:block" />

          {/* Operational System Indicator */}
          <div className="hidden lg:flex items-center gap-2 rounded-full border border-bhoomi-border bg-bhoomi-canvas px-3 py-1 text-xs text-bhoomi-text-muted">
            <span className="relative flex h-2 w-2">
              <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-emerald-400 opacity-75" />
              <span className="relative inline-flex rounded-full h-2 w-2 bg-emerald-600" />
            </span>
            <span className="font-mono text-[11px] text-bhoomi-text-secondary">API: /api/v1</span>
            <Activity className="h-3 w-3 text-bhoomi-primary" />
          </div>
        </div>
      </div>

      {/* User Session & Actions Area */}
      <div className="flex items-center gap-3.5">
        {user && (
          <div className="flex items-center gap-2.5">
            <div className="flex h-9 w-9 shrink-0 items-center justify-center rounded-full bg-bhoomi-primary-light border border-bhoomi-border-strong text-bhoomi-primary font-bold text-xs shadow-xs">
              {userInitial}
            </div>
            <div className="text-left hidden sm:block">
              <p className="font-semibold text-xs text-bhoomi-text-primary leading-tight">
                {user.name}
              </p>
              <p className="text-[11px] text-bhoomi-text-muted capitalize">
                {user.role === 'agronomist' ? 'Expert Agronomist' : 'Agriculture Official'}
              </p>
            </div>
          </div>
        )}

        <div className="h-6 w-px bg-bhoomi-border hidden sm:block" />

        <Button
          variant="ghost"
          size="sm"
          onClick={logout}
          className="text-bhoomi-text-secondary hover:text-bhoomi-danger hover:bg-bhoomi-danger-soft transition-colors text-xs font-medium"
        >
          <LogOut className="h-3.5 w-3.5 mr-1.5" />
          Sign Out
        </Button>
      </div>
    </header>
  );
}
