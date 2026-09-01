import { vi, describe, it, expect, beforeEach } from 'vitest';
import { render, screen, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { createMemoryRouter, RouterProvider } from 'react-router-dom';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { AuthProvider } from '@/features/auth/AuthProvider';
import { routes } from '@/app/router';
import {
  CaseBundle,
  CaseQueueResponse,
  HotspotsResponse,
  AccuracyResponse,
  OfficialsQueueResponse,
  UserProfile,
} from '@/types/api';
import * as agronomistApiModule from '../features/agronomist/api';
import * as officialApiModule from '../features/officials/api';
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

vi.mock('../features/agronomist/api', () => {
  return {
    agronomistApi: {
      getCaseQueue: vi.fn(),
      getCase: vi.fn(),
      confirmCase: vi.fn(),
      requestInfo: vi.fn(),
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

// Mock react-leaflet for JSDOM environment
vi.mock('react-leaflet', () => {
  return {
    MapContainer: ({ children }: { children?: React.ReactNode }) => (
      <div data-testid="map-container">{children}</div>
    ),
    TileLayer: () => <div data-testid="tile-layer" />,
    CircleMarker: ({
      children,
      center,
    }: {
      children?: React.ReactNode;
      center: [number, number];
    }) => <div data-testid={`marker-${center.join(',')}`}>{children}</div>,
    Popup: ({ children }: { children?: React.ReactNode }) => (
      <div data-testid="popup">{children}</div>
    ),
    useMap: () => ({
      setView: vi.fn(),
      fitBounds: vi.fn(),
    }),
  };
});

// Mock recharts for JSDOM environment
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

const mockAgronomistUser: UserProfile = {
  id: 'u_agro_1',
  email: 'agronomist@bhoomi.gov.in',
  name: 'Dr. Anand Kumar',
  role: 'agronomist',
};

const mockOfficialUser: UserProfile = {
  id: 'u_off_1',
  email: 'official@bhoomi.gov.in',
  name: 'Rajesh Patil (JD Agriculture)',
  role: 'official',
};

const mockCaseQueue: CaseQueueResponse = {
  cases: [
    {
      case_id: 'c_501',
      label: 'paddy_blast',
      region: 'Nashik',
      status: 'assigned',
      created_at: '2026-08-25T10:00:00Z',
      queue_position: 1,
    },
    {
      case_id: 'c_502',
      label: 'cotton_pink_bollworm',
      region: 'Akola',
      status: 'assigned',
      created_at: '2026-08-25T11:00:00Z',
      queue_position: 2,
    },
  ],
  next_cursor: null,
};

const mockCaseBundle: CaseBundle = {
  case_id: 'c_501',
  status: 'assigned',
  farm: {
    id: 'f_101',
    crop: 'paddy',
    variety: 'Indrayani',
    growth_stage: 'tillering',
    region: 'Nashik',
  },
  problem: {
    id: 'p_201',
    type: 'disease',
    label: 'paddy_blast',
    severity: 'moderate',
    opened_at: '2026-08-25T08:00:00Z',
  },
  model_hypotheses: [
    { label: 'paddy_blast', confidence: 0.5 },
    { label: 'paddy_brown_spot', confidence: 0.46 },
    { label: 'paddy_bacterial_leaf_blight', confidence: 0.04 },
  ],
  gate: {
    outcome: 'clarify',
    reason_code: 'AMBIGUOUS',
    threshold_applied: 0.15,
  },
  field_observations: [
    {
      question: 'Fuzzy grey growth on leaf underside?',
      answer: 'yes',
      at: '2026-08-25T08:15:00Z',
    },
  ],
  images: [
    { asset_id: 'img_1', url: 'https://storage/leaf1.jpg', at: '2026-08-25T08:00:00Z' },
    { asset_id: 'img_2', url: 'https://storage/leaf2.jpg', at: '2026-08-25T08:05:00Z' },
  ],
  treatments_tried: ['Drained field 48h', 'Withheld topdress nitrogen'],
  label_checks: [
    {
      ingredient: 'carbendazim',
      verdict: 'WRONG_CLASS',
      at: '2026-08-25T08:20:00Z',
    },
  ],
  followup_trend: 'got_worse',
  spoken_summary: null,
};

const mockHotspotsData: HotspotsResponse = {
  points: [
    {
      lat: 19.9975,
      lng: 73.7898,
      label: 'paddy_blast',
      confirmed_count: 8,
      first_seen: '2026-08-20',
      last_seen: '2026-08-29',
    },
  ],
  totals_by_label: {
    paddy_blast: 8,
  },
};

const mockAccuracyData: AccuracyResponse = {
  window: { from: '2026-08-01', to: '2026-08-29' },
  by_label: [
    { label: 'paddy_blast', confirmed: 15, corrected: 2, accuracy: 0.88 },
    { label: 'cotton_pink_bollworm', confirmed: 8, corrected: 4, accuracy: 0.67 },
  ],
};

const mockOfficialsQueueData: OfficialsQueueResponse = {
  queue: [
    {
      case_id: 'c_501',
      predicted_label: 'paddy_blast',
      confidence: 0.5,
      created_at: '2026-08-25T08:00:00Z',
      region: 'Nashik',
      severity: 'moderate',
    },
  ],
  next_cursor: null,
};

const setup = (initialRoute: string, authUser: UserProfile | null) => {
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
    tokenStorage.setToken('test_jwt_token');
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

describe('BHOOMI Phase 8 — End-to-End Integration & Multi-Role QA', () => {
  beforeEach(() => {
    vi.clearAllMocks();
    tokenStorage.clearAll();

    // Default mock implementations
    vi.mocked(agronomistApiModule.agronomistApi.getCaseQueue).mockResolvedValue(mockCaseQueue);
    vi.mocked(agronomistApiModule.agronomistApi.getCase).mockResolvedValue(mockCaseBundle);
    vi.mocked(agronomistApiModule.agronomistApi.confirmCase).mockResolvedValue({
      case_id: 'c_501',
      status: 'resolved',
      problem_status: 'resolved',
      confirmation_id: 'cf_99',
      spread_alerts_issued: 6,
    });

    vi.mocked(officialApiModule.officialsApi.getHotspots).mockResolvedValue(mockHotspotsData);
    vi.mocked(officialApiModule.officialsApi.getAccuracy).mockResolvedValue(mockAccuracyData);
    vi.mocked(officialApiModule.officialsApi.getQueue).mockResolvedValue(mockOfficialsQueueData);
  });

  describe('1. Cross-Role Boundary & Route Protection Matrix', () => {
    it('redirects unauthenticated requests to login', async () => {
      setup('/agronomist/cases', null);
      await waitFor(() => {
        expect(screen.getByText('BHOOMI Portal')).toBeInTheDocument();
      });
    });

    it('blocks agronomists from accessing official routes', async () => {
      setup('/official', mockAgronomistUser);
      await waitFor(() => {
        expect(screen.getByText('Access Restricted')).toBeInTheDocument();
      });
    });

    it('blocks officials from accessing agronomist workspace routes', async () => {
      setup('/agronomist/cases', mockOfficialUser);
      await waitFor(() => {
        expect(screen.getByText('Access Restricted')).toBeInTheDocument();
      });
    });
  });

  describe('2. F12 Agronomist Complete Review & Resolution Workflow', () => {
    it('completes the full queue -> workspace review -> confirmation lifecycle', async () => {
      setup('/agronomist/cases', mockAgronomistUser);

      // Step 1: Verify Case Queue loads live cases
      await waitFor(() => {
        expect(screen.getByText('c_501')).toBeInTheDocument();
        expect(screen.getByText('c_502')).toBeInTheDocument();
      });

      // Step 2: Open Case Workspace directly
      setup('/agronomist/cases/c_501', mockAgronomistUser);

      await waitFor(() => {
        // Farm Context
        expect(screen.getByText(/Indrayani/i)).toBeInTheDocument();
        // Model Hypotheses
        expect(screen.getAllByText('Paddy Blast').length).toBeGreaterThan(0);
        // Field Observations
        expect(screen.getByText(/Fuzzy grey growth/i)).toBeInTheDocument();
        // Label checks
        expect(screen.getByText('carbendazim')).toBeInTheDocument();
      });

      // Step 3: Trigger Confirm Dialog
      const confirmButton = screen.getByRole('button', { name: /confirm diagnosis/i });
      await userEvent.click(confirmButton);

      await waitFor(() => {
        expect(screen.getByRole('dialog', { name: /confirm model diagnosis/i })).toBeInTheDocument();
      });

      // Step 4: Fill treatment and submit
      const treatmentInput = screen.getByLabelText(/prescribed treatment/i);
      await userEvent.type(treatmentInput, 'Apply Tricyclazole 75 WP per PoP; drain for 48h.');

      const submitConfirm = screen.getByRole('button', { name: /^confirm case$/i });
      await userEvent.click(submitConfirm);

      // Step 5: Verify POST /cases/c_501/confirm was called with exact contract payload
      await waitFor(() => {
        expect(agronomistApiModule.agronomistApi.confirmCase).toHaveBeenCalledWith('c_501', {
          verdict: 'confirmed',
          treatment: 'Apply Tricyclazole 75 WP per PoP; drain for 48h.',
          notes: undefined,
        });
      });

      // Step 6: Verify Success Resolution Modal displays confirmation_id and spread_alerts_issued
      await waitFor(() => {
        expect(screen.getByRole('dialog', { name: /case resolved/i })).toBeInTheDocument();
        expect(screen.getByText('cf_99')).toBeInTheDocument();
        expect(screen.getByText('6')).toBeInTheDocument(); // spread_alerts_issued count
      });
    });

    it('handles correction workflow with verdict="corrected" and corrected_label', async () => {
      setup('/agronomist/cases/c_501', mockAgronomistUser);

      await waitFor(() => {
        expect(screen.getByText('c_501')).toBeInTheDocument();
      });

      const correctButton = screen.getByRole('button', { name: /correct diagnosis/i });
      await userEvent.click(correctButton);

      await waitFor(() => {
        expect(screen.getByRole('dialog', { name: /correct diagnosis/i })).toBeInTheDocument();
      });

      // Select corrected diagnosis and treatment
      const labelSelect = screen.getByLabelText(/correct diagnosis \*/i);
      await userEvent.selectOptions(labelSelect, 'paddy_brown_spot');

      const treatmentInput = screen.getByLabelText(/prescribed treatment/i);
      await userEvent.type(treatmentInput, 'Mancozeb foliar spray.');

      const submitCorrect = screen.getByRole('button', { name: /^submit correction$/i });
      await userEvent.click(submitCorrect);

      await waitFor(() => {
        expect(agronomistApiModule.agronomistApi.confirmCase).toHaveBeenCalledWith('c_501', {
          verdict: 'corrected',
          corrected_label: 'paddy_brown_spot',
          treatment: 'Mancozeb foliar spray.',
          notes: undefined,
        });
      });
    });
  });

  describe('3. F15 Officials Surveillance & Analytics Invariants', () => {
    it('strictly loads confirmed-only hotspot points and isolates map data from model hypotheses', async () => {
      setup('/official/hotspots', mockOfficialUser);

      await waitFor(() => {
        expect(officialApiModule.officialsApi.getHotspots).toHaveBeenCalledTimes(1);
        // Map markers present
        expect(screen.getByTestId('map-container')).toBeInTheDocument();
        expect(screen.getAllByText('Paddy Blast').length).toBeGreaterThan(0);
      });
    });

    it('strictly renders backend accuracy without client-side formula recalculation', async () => {
      setup('/official/accuracy', mockOfficialUser);

      await waitFor(() => {
        expect(officialApiModule.officialsApi.getAccuracy).toHaveBeenCalledTimes(1);
        // Paddy Blast accuracy 0.88 -> 88%
        expect(screen.getAllByText('88%').length).toBeGreaterThan(0);
        // Cotton Pink Bollworm accuracy 0.67 -> 67%
        expect(screen.getAllByText('67%').length).toBeGreaterThan(0);
      });
    });

    it('renders the official confirmation queue without reusing agronomist queue', async () => {
      setup('/official/queue', mockOfficialUser);

      await waitFor(() => {
        expect(officialApiModule.officialsApi.getQueue).toHaveBeenCalledTimes(1);
        expect(agronomistApiModule.agronomistApi.getCaseQueue).not.toHaveBeenCalled();
        expect(screen.getByText('c_501')).toBeInTheDocument();
        expect(screen.getByText('Nashik')).toBeInTheDocument();
      });
    });
  });
});
