import { vi, describe, it, expect, beforeEach } from 'vitest';
import { render, screen, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { createMemoryRouter, RouterProvider } from 'react-router-dom';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { AuthProvider } from '@/features/auth/AuthProvider';
import { routes } from '@/app/router';
import { OfficialsQueueResponse, UserProfile } from '@/types/api';
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

const mockQueueData: OfficialsQueueResponse = {
  queue: [
    {
      case_id: 'c_101',
      predicted_label: 'wheat_rust',
      confidence: 0.95,
      created_at: '2026-08-18T10:00:00Z',
      region: 'pune',
      severity: 'high',
    },
    {
      case_id: 'c_102',
      predicted_label: 'paddy_blast',
      confidence: 0.72,
      created_at: '2026-08-19T14:30:00Z',
      region: 'nashik',
      severity: 'moderate',
    },
  ],
  next_cursor: null,
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

const setup = (initialRoute = '/official/queue', authUser: UserProfile | null = mockOfficialUser) => {
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

describe('F15 Official Confirmation Queue', () => {
  beforeEach(() => {
    vi.clearAllMocks();
    tokenStorage.clearAll();
    vi.mocked(officialApi.officialsApi.getQueue).mockResolvedValue(mockQueueData);
  });

  describe('Route Protection & Role Access', () => {
    it('redirects unauthenticated users to login', async () => {
      setup('/official/queue', null);
      await waitFor(() => {
        expect(screen.getByText('BHOOMI Portal')).toBeInTheDocument();
      });
    });

    it('prevents agronomists from accessing official queue', async () => {
      setup('/official/queue', mockAgronomistUser);
      await waitFor(() => {
        expect(screen.getByText('Access Restricted')).toBeInTheDocument();
      });
    });

    it('allows officials to access the queue page', async () => {
      setup('/official/queue', mockOfficialUser);
      await waitFor(() => {
        expect(screen.getByText('Official Queue')).toBeInTheDocument();
      });
    });
  });

  describe('Queue API Usage & Separation', () => {
    it('calls official queue endpoint exactly', async () => {
      setup('/official/queue');
      await waitFor(() => {
        expect(officialApi.officialsApi.getQueue).toHaveBeenCalledTimes(1);
        expect(officialApi.officialsApi.getHotspots).not.toHaveBeenCalled();
        expect(officialApi.officialsApi.getAccuracy).not.toHaveBeenCalled();
      });
    });
  });

  describe('Queue Table & Data Rendering', () => {
    it('renders all records with contract-defined fields', async () => {
      setup('/official/queue');

      await waitFor(() => {
        // Case IDs
        expect(screen.getByText('c_101')).toBeInTheDocument();
        expect(screen.getByText('c_102')).toBeInTheDocument();

        // Formatted Diagnoses
        expect(screen.getByText('Wheat Rust')).toBeInTheDocument();
        expect(screen.getByText('Paddy Blast')).toBeInTheDocument();

        // Model Confidence Percentages
        expect(screen.getByText('95%')).toBeInTheDocument();
        expect(screen.getByText('72%')).toBeInTheDocument();

        // Regions
        expect(screen.getByText('pune')).toBeInTheDocument();
        expect(screen.getByText('nashik')).toBeInTheDocument();

        // Severities
        expect(screen.getAllByText('high').length).toBeGreaterThan(0);
        expect(screen.getByText('moderate')).toBeInTheDocument();
      });
    });

    it('renders summary metric cards accurately', async () => {
      setup('/official/queue');

      await waitFor(() => {
        // Total queue count: 2 and Active Regions: 2
        expect(screen.getAllByText('2').length).toBeGreaterThan(0);
        // High severity count: 1
        expect(screen.getAllByText('1').length).toBeGreaterThan(0);
      });
    });
  });

  describe('Loading, Empty & Error States', () => {
    it('displays loading skeleton while fetching queue', async () => {
      vi.mocked(officialApi.officialsApi.getQueue).mockImplementation(
        () => new Promise((resolve) => setTimeout(() => resolve(mockQueueData), 100))
      );
      setup('/official/queue');

      // Before resolution, content is not present
      expect(screen.queryByText('c_101')).not.toBeInTheDocument();

      await waitFor(() => {
        expect(screen.getByText('c_101')).toBeInTheDocument();
      });
    });

    it('displays empty state when no records are in queue', async () => {
      vi.mocked(officialApi.officialsApi.getQueue).mockResolvedValue({
        queue: [],
        next_cursor: null,
      });

      setup('/official/queue');

      await waitFor(() => {
        expect(screen.getByText('No records currently require attention.')).toBeInTheDocument();
      });
    });

    it('displays error state and allows retry on failure', async () => {
      vi.mocked(officialApi.officialsApi.getQueue).mockRejectedValue(
        new Error('Network error')
      );

      setup('/official/queue');

      await waitFor(() => {
        expect(screen.getByText('Unable to load the official queue.')).toBeInTheDocument();
        expect(screen.getByText('Network error')).toBeInTheDocument();
      });

      // Retry
      vi.mocked(officialApi.officialsApi.getQueue).mockResolvedValue(mockQueueData);
      const retryBtn = screen.getByRole('button', { name: /retry/i });
      await userEvent.click(retryBtn);

      await waitFor(() => {
        expect(screen.getByText('c_101')).toBeInTheDocument();
      });
    });
  });

  describe('Refresh Behavior', () => {
    it('triggers a query refetch when the refresh button is clicked', async () => {
      setup('/official/queue');

      await waitFor(() => {
        expect(officialApi.officialsApi.getQueue).toHaveBeenCalledTimes(1);
      });

      const refreshBtn = screen.getByRole('button', { name: /refresh queue data/i });
      await userEvent.click(refreshBtn);

      await waitFor(() => {
        expect(officialApi.officialsApi.getQueue).toHaveBeenCalledTimes(2);
      });
    });
  });
});
