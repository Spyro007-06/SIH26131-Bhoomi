import { vi, describe, it, expect, beforeEach } from 'vitest';
import { render, screen, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { createMemoryRouter, RouterProvider } from 'react-router-dom';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { AuthProvider } from '@/features/auth/AuthProvider';
import { routes } from '@/app/router';
import { AccuracyResponse, UserProfile } from '@/types/api';
import * as officialApi from '../features/officials/api';
import { tokenStorage } from '../lib/auth/token-storage';

vi.mock('../lib/api/client', () => {
  return {
    apiClient: {
      get: vi.fn(),
      post: vi.fn(),
      onUnauthorized: vi.fn(() => vi.fn()),
    },
  };
});

vi.mock('../features/officials/api', () => {
  return {
    officialsApi: {
      getHotspots: vi.fn(),
      getAccuracy: vi.fn(),
      getQueue: vi.fn(),
    },
  };
});

// Mock recharts responsive container for JSDOM test runner
vi.mock('recharts', async (importOriginal) => {
  const actual = await importOriginal<typeof import('recharts')>();
  return {
    ...actual,
    ResponsiveContainer: ({ children }: { children: React.ReactNode }) => (
      <div data-testid="responsive-container" style={{ width: '800px', height: '400px' }}>
        {children}
      </div>
    ),
  };
});

const mockAccuracyData: AccuracyResponse = {
  window: { from: '2026-08-01', to: '2026-08-29' },
  by_label: [
    { label: 'paddy_blast', confirmed: 12, corrected: 3, accuracy: 0.80 },
    { label: 'paddy_brown_spot', confirmed: 5, corrected: 6, accuracy: 0.45 },
  ],
};

const mockOfficialUser: UserProfile = {
  id: 'u_2',
  email: 'official@bhoomi.gov.in',
  name: 'O. Smith',
  role: 'official',
};

const mockAgronomistUser: UserProfile = {
  id: 'u_1',
  email: 'agro@bhoomi.gov.in',
  name: 'A. Smith',
  role: 'agronomist',
};

const setup = (initialRoute = '/official/accuracy', authUser: UserProfile | null = mockOfficialUser) => {
  const queryClient = new QueryClient({
    defaultOptions: {
      queries: {
        retry: false,
        gcTime: 0,
        staleTime: 0,
      },
    },
  });

  const router = createMemoryRouter(routes, {
    initialEntries: [initialRoute],
  });

  if (authUser) {
    tokenStorage.setToken('mock_token');
    tokenStorage.setUser(authUser);
  } else {
    tokenStorage.clearAll();
  }

  render(
    <QueryClientProvider client={queryClient}>
      <AuthProvider>
        <RouterProvider router={router} />
      </AuthProvider>
    </QueryClientProvider>
  );

  return { router, queryClient };
};

describe('F15 Official Accuracy & Validation Analytics', () => {
  beforeEach(() => {
    vi.clearAllMocks();
    tokenStorage.clearAll();
    vi.mocked(officialApi.officialsApi.getAccuracy).mockResolvedValue(mockAccuracyData);
  });

  describe('Route Protection & Role Access', () => {
    it('redirects unauthenticated users to login', async () => {
      setup('/official/accuracy', null);
      await waitFor(() => {
        expect(screen.getByText('BHOOMI Portal')).toBeInTheDocument();
      });
    });

    it('prevents agronomists from accessing official accuracy page', async () => {
      setup('/official/accuracy', mockAgronomistUser);
      await waitFor(() => {
        expect(screen.getByText('Access Restricted')).toBeInTheDocument();
      });
    });

    it('allows officials to access the accuracy page', async () => {
      setup('/official/accuracy', mockOfficialUser);
      await waitFor(() => {
        expect(screen.getByText('Model Validation')).toBeInTheDocument();
      });
    });
  });

  describe('Data Rendering & Accuracy Semantics', () => {
    it('calls official accuracy API endpoint', async () => {
      setup('/official/accuracy');
      await waitFor(() => {
        expect(officialApi.officialsApi.getAccuracy).toHaveBeenCalledTimes(1);
      });
    });

    it('renders confirmed and corrected summary metrics accurately', async () => {
      setup('/official/accuracy');
      await waitFor(() => {
        // Total confirmed: 12 + 5 = 17
        expect(screen.getByText('17')).toBeInTheDocument();
        // Total corrected: 3 + 6 = 9
        expect(screen.getByText('9')).toBeInTheDocument();
        // Total targets: 2
        expect(screen.getByText('2')).toBeInTheDocument();
      });
    });

    it('renders per-target labels and backend accuracy values', async () => {
      setup('/official/accuracy');
      await waitFor(() => {
        expect(screen.getAllByText('Paddy Blast').length).toBeGreaterThan(0);
        expect(screen.getAllByText('Paddy Brown Spot').length).toBeGreaterThan(0);
        // Server reported 0.80 -> 80% and 0.45 -> 45%
        expect(screen.getAllByText('80%').length).toBeGreaterThan(0);
        expect(screen.getAllByText('45%').length).toBeGreaterThan(0);
      });
    });

    it('strictly preserves backend accuracy without client-side recalculation', async () => {
      // In this fixture, confirmed = 10, corrected = 10 (which is 50%),
      // but the server explicitly returns accuracy: 0.85
      const customDiscrepantData: AccuracyResponse = {
        window: { from: '2026-08-01', to: '2026-08-29' },
        by_label: [
          {
            label: 'cotton_pink_bollworm',
            confirmed: 10,
            corrected: 10,
            accuracy: 0.85,
          },
        ],
      };
      vi.mocked(officialApi.officialsApi.getAccuracy).mockResolvedValue(customDiscrepantData);

      setup('/official/accuracy');

      await waitFor(() => {
        expect(screen.getAllByText('Cotton Pink Bollworm').length).toBeGreaterThan(0);
        // Must show 85% from backend, NOT 50% from mathematical calculation
        expect(screen.getAllByText('85%').length).toBeGreaterThan(0);
        expect(screen.queryByText('50%')).not.toBeInTheDocument();
      });
    });

    it('handles null accuracy values gracefully without crashing', async () => {
      const nullAccuracyData: AccuracyResponse = {
        window: {},
        by_label: [
          {
            label: 'soybean_stem_fly',
            confirmed: 0,
            corrected: 0,
            accuracy: null,
          },
        ],
      };
      vi.mocked(officialApi.officialsApi.getAccuracy).mockResolvedValue(nullAccuracyData);

      setup('/official/accuracy');

      await waitFor(() => {
        expect(screen.getAllByText('Soybean Stem Fly').length).toBeGreaterThan(0);
        expect(screen.getByText('N/A')).toBeInTheDocument();
      });
    });
  });

  describe('Loading, Empty & Error States', () => {
    it('displays loading skeleton while fetching', async () => {
      vi.mocked(officialApi.officialsApi.getAccuracy).mockImplementation(
        () => new Promise((resolve) => setTimeout(() => resolve(mockAccuracyData), 100))
      );
      setup('/official/accuracy');

      // Before resolution, content is not present
      expect(screen.queryByText('Paddy Blast')).not.toBeInTheDocument();

      await waitFor(() => {
        expect(screen.getAllByText('Paddy Blast').length).toBeGreaterThan(0);
      });
    });

    it('displays empty state when no accuracy data is available', async () => {
      vi.mocked(officialApi.officialsApi.getAccuracy).mockResolvedValue({
        by_label: [],
        window: {},
      });

      setup('/official/accuracy');

      await waitFor(() => {
        expect(screen.getByText('No validation data available yet.')).toBeInTheDocument();
      });
    });

    it('displays error state and allows retry on failure', async () => {
      vi.mocked(officialApi.officialsApi.getAccuracy).mockRejectedValue(
        new Error('Database unavailable')
      );

      setup('/official/accuracy');

      await waitFor(() => {
        expect(screen.getByText('Unable to load validation analytics.')).toBeInTheDocument();
        expect(screen.getByText('Database unavailable')).toBeInTheDocument();
      });

      // Retry
      vi.mocked(officialApi.officialsApi.getAccuracy).mockResolvedValue(mockAccuracyData);
      const retryBtn = screen.getByRole('button', { name: /retry/i });
      await userEvent.click(retryBtn);

      await waitFor(() => {
        expect(screen.getByText('Paddy Blast')).toBeInTheDocument();
      });
    });
  });

  describe('Refresh Behavior', () => {
    it('triggers a query refetch when the refresh button is clicked', async () => {
      setup('/official/accuracy');

      await waitFor(() => {
        expect(officialApi.officialsApi.getAccuracy).toHaveBeenCalledTimes(1);
      });

      const refreshBtn = screen.getByRole('button', { name: /refresh accuracy data/i });
      await userEvent.click(refreshBtn);

      await waitFor(() => {
        expect(officialApi.officialsApi.getAccuracy).toHaveBeenCalledTimes(2);
      });
    });
  });
});
