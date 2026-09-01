import { vi, describe, it, expect, beforeEach } from 'vitest';
import { render, screen, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { createMemoryRouter, RouterProvider } from 'react-router-dom';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { AuthProvider } from '@/features/auth/AuthProvider';
import { routes } from '@/app/router';
import {
  HotspotsResponse,
  AccuracyResponse,
  OfficialsQueueResponse,
  UserProfile,
} from '@/types/api';
import * as officialApi from '../features/officials/api';
import { tokenStorage } from '../lib/auth/token-storage';

vi.mock('../lib/api/client', () => {
  return {
    apiClient: {
      get: vi.fn(),
      post: vi.fn(),
      onUnauthorized: vi.fn(() => vi.fn()),
    }
  };
});

vi.mock('../features/officials/api', () => {
  return {
    officialsApi: {
      getHotspots: vi.fn(),
      getAccuracy: vi.fn(),
      getQueue: vi.fn(),
    }
  };
});

const mockHotspotsData: HotspotsResponse = {
  points: [
    {
      lat: 18.5204,
      lng: 73.8567,
      label: 'wheat_rust',
      confirmed_count: 5,
      first_seen: '2026-08-01T00:00:00Z',
      last_seen: '2026-08-15T00:00:00Z',
    },
    {
      lat: 19.0760,
      lng: 72.8777,
      label: 'paddy_blast',
      confirmed_count: 12,
      first_seen: '2026-08-10T00:00:00Z',
      last_seen: '2026-08-20T00:00:00Z',
    }
  ],
  totals_by_label: {
    wheat_rust: 5,
    paddy_blast: 12,
  },
};

const mockAccuracyData: AccuracyResponse = {
  window: { from: '2023-01-01T00:00:00Z', to: '2023-12-31T23:59:59Z' },
  by_label: [
    { label: 'paddy_blast', confirmed: 80, corrected: 20, accuracy: 0.80 },
    { label: 'wheat_rust', confirmed: 45, corrected: 5, accuracy: 0.90 }
  ]
};

const mockQueueData: OfficialsQueueResponse = {
  queue: [
    {
      case_id: 'c_101',
      predicted_label: 'wheat_rust',
      confidence: 0.95,
      created_at: '2026-08-18T10:00:00Z',
      region: 'pune',
      severity: 'high',
    }
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


const setup = (initialRoute = '/official', authUser: UserProfile | null = mockOfficialUser) => {
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

  // Mock auth storage using the application's actual auth keys
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

describe('F15 Official Dashboard Foundation', () => {
  beforeEach(() => {
    vi.clearAllMocks();
    tokenStorage.clearAll();
    
    // Default success for API calls
    vi.mocked(officialApi.officialsApi.getHotspots).mockResolvedValue(mockHotspotsData);
    vi.mocked(officialApi.officialsApi.getAccuracy).mockResolvedValue(mockAccuracyData);
    vi.mocked(officialApi.officialsApi.getQueue).mockResolvedValue(mockQueueData);
  });

  describe('Route Protection & Role Access', () => {
    it('redirects unauthenticated users to login', async () => {
      setup('/official', null);
      await waitFor(() => {
        expect(screen.getByText('BHOOMI Portal')).toBeInTheDocument();
      });
    });

    it('prevents agronomist from accessing official dashboard', async () => {
      setup('/official', mockAgronomistUser);
      await waitFor(() => {
        expect(screen.getByText('Access Restricted')).toBeInTheDocument();
      });
    });

    it('allows official to access official dashboard', async () => {
      setup('/official', mockOfficialUser);
      await waitFor(() => {
        expect(screen.getByText('Agriculture Officials Dashboard')).toBeInTheDocument();
      });
    });
  });

  describe('Dashboard API Usage', () => {
    it('uses correct hotspots endpoint', async () => {
      setup('/official');
      await waitFor(() => {
        expect(officialApi.officialsApi.getHotspots).toHaveBeenCalled();
      });
    });

    it('uses correct accuracy endpoint', async () => {
      setup('/official');
      await waitFor(() => {
        expect(officialApi.officialsApi.getAccuracy).toHaveBeenCalled();
      });
    });

    it('uses correct queue endpoint', async () => {
      setup('/official');
      await waitFor(() => {
        expect(officialApi.officialsApi.getQueue).toHaveBeenCalled();
      });
    });
  });

  describe('Dashboard Loading & Display', () => {
    it('shows loading skeletons while fetching data', async () => {
      // Delay API resolution
      vi.mocked(officialApi.officialsApi.getHotspots).mockImplementation(() => new Promise(resolve => setTimeout(() => resolve(mockHotspotsData), 100)));
      setup('/official');
      
      // Before data loads, skeleton should be there
      expect(screen.queryByText('Outbreak Clusters')).not.toBeInTheDocument();
      
      await waitFor(() => {
        expect(screen.getByText('Confirmed Outbreak Hotspots')).toBeInTheDocument();
      });
    });

    it('renders empty hotspot state', async () => {
      vi.mocked(officialApi.officialsApi.getHotspots).mockResolvedValue({ points: [], totals_by_label: {} });
      setup('/official');
      
      await waitFor(() => {
        expect(screen.getByText('No Confirmed Outbreak Hotspots')).toBeInTheDocument();
      });
    });

    it('renders empty queue state', async () => {
      vi.mocked(officialApi.officialsApi.getQueue).mockResolvedValue({ queue: [], next_cursor: null });
      setup('/official');
      
      await waitFor(() => {
        expect(screen.getByText('Queue is Empty')).toBeInTheDocument();
      });
    });
  });

  describe('Partial Failure', () => {
    it('keeps working sections alive if one endpoint fails', async () => {
      // Hotspots fail, but others succeed
      vi.mocked(officialApi.officialsApi.getHotspots).mockRejectedValue(new Error('Failed to load'));
      
      setup('/official');
      
      await waitFor(() => {
        // Hotspots should show error
        expect(screen.getByText('Failed to Load Hotspots')).toBeInTheDocument();
        
        // But Accuracy should render fine
        expect(screen.getByText('80%')).toBeInTheDocument();
        
        // And Queue should render fine
        expect(screen.getByText('c_101')).toBeInTheDocument();
      });
    });
  });

  describe('Refresh Behavior', () => {
    it('refetches queries when refresh button is clicked', async () => {
      setup('/official');
      
      await waitFor(() => {
        expect(officialApi.officialsApi.getHotspots).toHaveBeenCalledTimes(1);
      });
      
      const refreshBtn = screen.getByRole('button', { name: /refresh dashboard data/i });
      await userEvent.click(refreshBtn);
      
      await waitFor(() => {
        expect(officialApi.officialsApi.getHotspots).toHaveBeenCalledTimes(2);
      });
    });
  });
});
