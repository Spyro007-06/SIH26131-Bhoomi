import { createBrowserRouter, Navigate, RouteObject } from 'react-router-dom';
import { LoginPage } from '@/features/auth/pages/LoginPage';
import { ProtectedRoute } from '@/routes/ProtectedRoute';
import { RoleRoute } from '@/routes/RoleRoute';
import { AppShell } from '@/components/layout/AppShell';

// Agronomist Pages
import { CaseQueuePage } from '@/features/agronomist/pages/CaseQueuePage';
import { CaseWorkspacePage } from '@/features/agronomist/pages/CaseWorkspacePage';

// Officials Pages (F15)
import { OfficialsDashboardPage } from '@/features/officials/pages/OfficialsDashboardPage';
import { OfficialsHotspotsPage } from '@/features/officials/pages/OfficialsHotspotsPage';
import { OfficialsAccuracyPage } from '@/features/officials/pages/OfficialsAccuracyPage';
import { OfficialsQueuePage } from '@/features/officials/pages/OfficialsQueuePage';

export const routes: RouteObject[] = [
  {
    path: '/login',
    element: <LoginPage />,
  },
  {
    element: <ProtectedRoute />,
    children: [
      {
        element: <AppShell />,
        children: [
          // F12 Agronomist Surface
          {
            element: <RoleRoute allowedRoles={['agronomist']} />,
            children: [
              {
                path: '/agronomist',
                element: <Navigate to="/agronomist/cases" replace />,
              },
              {
                path: '/agronomist/cases',
                element: <CaseQueuePage />,
              },
              {
                path: '/agronomist/cases/:caseId',
                element: <CaseWorkspacePage />,
              },
            ],
          },
          // F15 Officials Surface
          {
            element: <RoleRoute allowedRoles={['official']} />,
            children: [
              {
                path: '/official',
                element: <OfficialsDashboardPage />,
              },
              {
                path: '/official/hotspots',
                element: <OfficialsHotspotsPage />,
              },
              {
                path: '/official/accuracy',
                element: <OfficialsAccuracyPage />,
              },
              {
                path: '/official/queue',
                element: <OfficialsQueuePage />,
              },
            ],
          },
        ],
      },
    ],
  },
  {
    path: '/',
    element: <Navigate to="/login" replace />,
  },
  {
    path: '*',
    element: <Navigate to="/login" replace />,
  },
];

export const router = createBrowserRouter(routes);
