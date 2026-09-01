import { Navigate, Outlet } from 'react-router-dom';
import { useAuth } from '@/features/auth/hooks';
import { Role } from '@/types/enums';
import { ForbiddenPage } from './ForbiddenPage';

export interface RoleRouteProps {
  allowedRoles: Role[];
}

export function RoleRoute({ allowedRoles }: RoleRouteProps) {
  const { user } = useAuth();

  if (!user) {
    return <Navigate to="/login" replace />;
  }

  if (!allowedRoles.includes(user.role)) {
    return <ForbiddenPage />;
  }

  return <Outlet />;
}
