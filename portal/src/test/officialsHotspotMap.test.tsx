import { vi, describe, it, expect, beforeEach } from 'vitest';
import { render, screen, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { createMemoryRouter, RouterProvider } from 'react-router-dom';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { AuthProvider } from '@/features/auth/AuthProvider';
import { routes } from '@/app/router';
import { ReactNode } from 'react';
import { HotspotsResponse, UserProfile } from '@/types/api';
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

// Mock react-leaflet as JSDOM does not support its full DOM requirements
vi.mock('react-leaflet', () => {
  return {
    MapContainer: ({ children }: { children?: ReactNode }) => <div data-testid="map-container">{children}</div>,
    TileLayer: () => <div data-testid="tile-layer" />,
    CircleMarker: ({ children, center }: { children?: ReactNode; center: [number, number] }) => (
      <div data-testid={`marker-${center.join(',')}`}>
        {children}
      </div>
    ),
    Popup: ({ children }: { children?: ReactNode }) => <div data-testid="popup">{children}</div>,
    useMap: () => ({
      setView: vi.fn(),
      fitBounds: vi.fn(),
    }),
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

const setup = (initialRoute = '/official/hotspots', authUser: UserProfile | null = mockOfficialUser) => {
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

describe('F15 Official Hotspot Map', () => {
  beforeEach(() => {
    vi.clearAllMocks();
    tokenStorage.clearAll();
    vi.mocked(officialApi.officialsApi.getHotspots).mockResolvedValue(mockHotspotsData);
  });

  describe('Route Protection & Role Access', () => {
    it('redirects unauthenticated users to login', async () => {
      setup('/official/hotspots', null);
      await waitFor(() => {
        expect(screen.getByText('BHOOMI Portal')).toBeInTheDocument(); // Login Page Title
      });
    });

    it('prevents agronomist from accessing hotspot map', async () => {
      setup('/official/hotspots', mockAgronomistUser);
      await waitFor(() => {
        expect(screen.getByText('Access Restricted')).toBeInTheDocument();
      });
    });

    it('allows official to access hotspot map', async () => {
      setup('/official/hotspots', mockOfficialUser);
      await waitFor(() => {
        expect(screen.getByText('Confirmed Hotspots')).toBeInTheDocument();
      });
    });
  });

  describe('Hotspot Map API and Rendering', () => {
    it('uses correct hotspots endpoint', async () => {
      setup('/official/hotspots');
      await waitFor(() => {
        expect(officialApi.officialsApi.getHotspots).toHaveBeenCalled();
      });
    });

    it('renders the map container and markers for valid points', async () => {
      setup('/official/hotspots');
      await waitFor(() => {
        expect(screen.getByTestId('map-container')).toBeInTheDocument();
        expect(screen.getByTestId('tile-layer')).toBeInTheDocument();
      });

      // Markers should be rendered
      expect(screen.getByTestId('marker-18.5204,73.8567')).toBeInTheDocument();
      expect(screen.getByTestId('marker-19.076,72.8777')).toBeInTheDocument();

      // Check popup content rendered inside the mock
      expect(screen.getByText('Wheat Rust')).toBeInTheDocument();
      expect(screen.getByText('Paddy Blast')).toBeInTheDocument();
      expect(screen.getByText('12 records')).toBeInTheDocument();
    });

    it('displays loading state correctly', async () => {
      // Delay response to show loading
      vi.mocked(officialApi.officialsApi.getHotspots).mockImplementation(() => new Promise(resolve => setTimeout(() => resolve(mockHotspotsData), 100)));
      setup('/official/hotspots');
      
      expect(screen.getByText('Loading confirmed hotspot data...')).toBeInTheDocument();
      
      await waitFor(() => {
        expect(screen.queryByText('Loading confirmed hotspot data...')).not.toBeInTheDocument();
      });
    });

    it('displays empty state when there are no hotspots', async () => {
      vi.mocked(officialApi.officialsApi.getHotspots).mockResolvedValue({ points: [], totals_by_label: {} });
      setup('/official/hotspots');
      
      await waitFor(() => {
        expect(screen.getByText('No confirmed hotspots available.')).toBeInTheDocument();
      });
    });

    it('displays error state correctly', async () => {
      vi.mocked(officialApi.officialsApi.getHotspots).mockRejectedValue(new Error('Network error'));
      setup('/official/hotspots');
      
      await waitFor(() => {
        expect(screen.getByText('Unable to load confirmed hotspot data.')).toBeInTheDocument();
        expect(screen.getByText('Network error')).toBeInTheDocument();
      });
    });

    it('ignores invalid geographic coordinates', async () => {
      vi.mocked(officialApi.officialsApi.getHotspots).mockResolvedValue({
        points: [
          { lat: 999, lng: 73.8567, label: 'wheat_rust', confirmed_count: 5, first_seen: '', last_seen: '' },
          { lat: 18.5, lng: 73.8, label: 'valid_disease', confirmed_count: 2, first_seen: '', last_seen: '' },
        ],
        totals_by_label: {},
      });
      
      setup('/official/hotspots');
      
      await waitFor(() => {
        expect(screen.getByTestId('marker-18.5,73.8')).toBeInTheDocument();
        // The invalid marker should not be rendered
        expect(screen.queryByTestId('marker-999,73.8567')).not.toBeInTheDocument();
      });
    });

    it('refetches queries when refresh button is clicked', async () => {
      setup('/official/hotspots');
      
      await waitFor(() => {
        expect(officialApi.officialsApi.getHotspots).toHaveBeenCalledTimes(1);
      });
      
      const refreshBtn = screen.getByRole('button', { name: /refresh hotspot data/i });
      await userEvent.click(refreshBtn);
      
      await waitFor(() => {
        expect(officialApi.officialsApi.getHotspots).toHaveBeenCalledTimes(2);
      });
    });
  });
});
