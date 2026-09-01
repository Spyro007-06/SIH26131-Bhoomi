import { useAuth } from '@/features/auth/hooks';
import { Button } from '@/components/ui/Button';
import { Badge } from '@/components/ui/Badge';
import { LogOut, User, Sprout } from 'lucide-react';

export function Header() {
  const { user, logout } = useAuth();

  return (
    <header className="sticky top-0 z-30 flex h-16 w-full items-center justify-between border-b border-bhoomi-border bg-bhoomi-white px-6 shadow-sm">
      <div className="flex items-center gap-3">
        <div className="flex h-9 w-9 items-center justify-center rounded-lg bg-bhoomi-green-800 text-bhoomi-cream">
          <Sprout className="h-5 w-5" />
        </div>
        <div>
          <div className="flex items-center gap-2">
            <span className="font-bold tracking-tight text-bhoomi-green-900 text-lg">BHOOMI</span>
            {user?.role && (
              <Badge variant="primary" size="sm">
                {user.role === 'agronomist' ? 'Agronomist Portal' : 'Officials Dashboard'}
              </Badge>
            )}
          </div>
          <p className="text-xs text-bhoomi-text-secondary">
            Government of Maharashtra · Crop Health System
          </p>
        </div>
      </div>

      <div className="flex items-center gap-4">
        {user && (
          <div className="flex items-center gap-2 text-sm text-bhoomi-text">
            <div className="flex h-8 w-8 items-center justify-center rounded-full bg-bhoomi-surface-soft border border-bhoomi-border text-bhoomi-text-secondary">
              <User className="h-4 w-4" />
            </div>
            <div className="text-left">
              <p className="font-medium leading-none text-xs">{user.name}</p>
              <p className="text-[11px] text-bhoomi-text-secondary capitalize">{user.role}</p>
            </div>
          </div>
        )}

        <Button
          variant="ghost"
          size="sm"
          onClick={logout}
          className="text-bhoomi-text-secondary hover:text-bhoomi-danger"
        >
          <LogOut className="h-4 w-4 mr-1.5" />
          Sign Out
        </Button>
      </div>
    </header>
  );
}
