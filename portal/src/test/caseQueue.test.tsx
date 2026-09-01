import { render, screen, waitFor, within } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { describe, it, expect, beforeEach, vi } from 'vitest';
import { createMemoryRouter, RouterProvider } from 'react-router-dom';
import { AppProviders } from '@/app/providers';
import { routes } from '@/app/router';
import { tokenStorage } from '@/lib/auth/token-storage';
import { apiClient } from '@/lib/api/client';
import { BhoomiApiError } from '@/lib/api/errors';
import { agronomistApi } from '@/features/agronomist/api';
import { CaseQueueResponse, UserProfile } from '@/types/api';

const mockAgronomistUser: UserProfile = {
  id: 'usr_agro_suresh',
  name: 'Dr. Suresh Patil',
  role: 'agronomist',
  email: 'spatil@kvk.gov.in',
};

const mockOfficialUser: UserProfile = {
  id: 'usr_off_deshmukh',
  name: 'Officer Deshmukh',
  role: 'official',
  email: 'deshmukh@maha.gov.in',
};

const sampleQueueResponse: CaseQueueResponse = {
  cases: [
    {
      case_id: 'c_001_paddy',
      problem_id: 'p_101',
      farm_id: 'f_501',
      region: 'Nashik',
      label: 'paddy_blast',
      status: 'assigned',
      queue_position: 1,
      eta_minutes: 30,
      created_at: '2026-08-25T10:00:00Z',
    },
    {
      case_id: 'c_002_cotton',
      problem_id: 'p_102',
      farm_id: 'f_502',
      region: 'Amravati',
      label: 'cotton_pink_bollworm',
      status: 'assigned',
      queue_position: 2,
      eta_minutes: 45,
      created_at: '2026-08-25T11:00:00Z',
    },
    {
      case_id: 'c_003_soybean',
      problem_id: 'p_103',
      farm_id: 'f_503',
      region: 'Latur',
      label: 'soybean_stem_fly',
      status: 'assigned',
      queue_position: 3,
      eta_minutes: 60,
      created_at: '2026-08-25T12:00:00Z',
    },
  ],
  next_cursor: 'cursor_page_2',
};

describe('F12 — Agronomist Case Queue Tests', () => {
  beforeEach(() => {
    tokenStorage.clearAll();
    vi.restoreAllMocks();
  });

  const renderWithRouter = (initialPath = '/agronomist/cases') => {
    const memoryRouter = createMemoryRouter(routes, {
      initialEntries: [initialPath],
    });

    return render(
      <AppProviders>
        <RouterProvider router={memoryRouter} />
      </AppProviders>
    );
  };

  // -------------------------------------------------------------------------
  // 1. API Call & Contract Parameters Test
  // -------------------------------------------------------------------------
  it('calls exact GET /agronomist/case-queue?status=assigned endpoint with pagination params', async () => {
    const getSpy = vi.spyOn(apiClient, 'get').mockResolvedValueOnce({
      cases: [],
      next_cursor: null,
    });

    await agronomistApi.getCaseQueue({ status: 'assigned', limit: 20, cursor: 'cursor_123' });

    expect(getSpy).toHaveBeenCalledWith('/agronomist/case-queue', {
      params: {
        status: 'assigned',
        limit: 20,
        cursor: 'cursor_123',
      },
    });
  });

  // -------------------------------------------------------------------------
  // 2. Server Ordering & Live Queue Position
  // -------------------------------------------------------------------------
  it('renders cases strictly preserving server order and live queue_position', async () => {
    tokenStorage.setToken('valid_jwt');
    tokenStorage.setUser(mockAgronomistUser);

    vi.spyOn(agronomistApi, 'getCaseQueue').mockResolvedValueOnce(sampleQueueResponse);

    renderWithRouter('/agronomist/cases');

    await waitFor(() => {
      expect(screen.getByText('Paddy Blast')).toBeInTheDocument();
      expect(screen.getByText('Cotton Pink Bollworm')).toBeInTheDocument();
      expect(screen.getByText('Soybean Stem Fly')).toBeInTheDocument();
    });

    // Check live queue positions
    expect(screen.getByText('#1')).toBeInTheDocument();
    expect(screen.getByText('#2')).toBeInTheDocument();
    expect(screen.getByText('#3')).toBeInTheDocument();

    // Verify row ordering
    const rows = screen.getAllByRole('row');
    // Row 0 is the table header
    expect(within(rows[1]!).getByText('Paddy Blast')).toBeInTheDocument();
    expect(within(rows[1]!).getByText('#1')).toBeInTheDocument();

    expect(within(rows[2]!).getByText('Cotton Pink Bollworm')).toBeInTheDocument();
    expect(within(rows[2]!).getByText('#2')).toBeInTheDocument();

    expect(within(rows[3]!).getByText('Soybean Stem Fly')).toBeInTheDocument();
    expect(within(rows[3]!).getByText('#3')).toBeInTheDocument();
  });

  // -------------------------------------------------------------------------
  // 3. Empty State Test
  // -------------------------------------------------------------------------
  it('renders "All caught up" empty state when zero cases are assigned', async () => {
    tokenStorage.setToken('valid_jwt');
    tokenStorage.setUser(mockAgronomistUser);

    vi.spyOn(agronomistApi, 'getCaseQueue').mockResolvedValueOnce({
      cases: [],
      next_cursor: null,
    });

    renderWithRouter('/agronomist/cases');

    await waitFor(() => {
      expect(screen.getByText('All caught up')).toBeInTheDocument();
      expect(
        screen.getByText('No assigned cases require review right now.')
      ).toBeInTheDocument();
      expect(screen.getByRole('button', { name: /check again/i })).toBeInTheDocument();
    });
  });

  // -------------------------------------------------------------------------
  // 4. Pagination / Load More Test
  // -------------------------------------------------------------------------
  it('handles "Load More Cases" using opaque next_cursor without modifying it', async () => {
    const user = userEvent.setup();
    tokenStorage.setToken('valid_jwt');
    tokenStorage.setUser(mockAgronomistUser);

    // Initial page with next_cursor
    const apiSpy = vi
      .spyOn(agronomistApi, 'getCaseQueue')
      .mockResolvedValueOnce({
        cases: [
          {
            case_id: 'c_page_1',
            region: 'Nashik',
            label: 'paddy_blast',
            status: 'assigned',
            queue_position: 1,
            created_at: '2026-08-25T10:00:00Z',
          },
        ],
        next_cursor: 'opaque_cursor_xyz_123',
      })
      .mockResolvedValueOnce({
        cases: [
          {
            case_id: 'c_page_2',
            region: 'Pune',
            label: 'jowar_shoot_fly',
            status: 'assigned',
            queue_position: 2,
            created_at: '2026-08-25T11:00:00Z',
          },
        ],
        next_cursor: null, // End of pages
      });

    renderWithRouter('/agronomist/cases');

    await waitFor(() => {
      expect(screen.getByText('Paddy Blast')).toBeInTheDocument();
      expect(screen.getByRole('button', { name: /load more cases/i })).toBeInTheDocument();
    });

    // Click Load More
    const loadMoreBtn = screen.getByRole('button', { name: /load more cases/i });
    await user.click(loadMoreBtn);

    await waitFor(() => {
      expect(screen.getByText('Jowar Shoot Fly')).toBeInTheDocument();
    });

    // Verify the second call passed the exact opaque cursor
    expect(apiSpy).toHaveBeenLastCalledWith(
      expect.objectContaining({
        status: 'assigned',
        cursor: 'opaque_cursor_xyz_123',
      })
    );

    // Verify button is removed once next_cursor is null
    expect(screen.queryByRole('button', { name: /load more cases/i })).not.toBeInTheDocument();
  });

  // -------------------------------------------------------------------------
  // 5. Case Navigation Test
  // -------------------------------------------------------------------------
  it('navigates to /agronomist/cases/:caseId when a case row or review button is activated', async () => {
    const user = userEvent.setup();
    tokenStorage.setToken('valid_jwt');
    tokenStorage.setUser(mockAgronomistUser);

    vi.spyOn(agronomistApi, 'getCaseQueue').mockResolvedValueOnce(sampleQueueResponse);
    vi.spyOn(agronomistApi, 'getCase').mockResolvedValueOnce({
      case_id: 'c_001_paddy',
      status: 'assigned',
      farm: {
        id: 'f_001',
        crop: 'paddy',
        variety: 'Indrayani',
        growth_stage: 'tillering',
        region: 'Nashik',
      },
      problem: {
        id: 'p_001',
        type: 'disease',
        label: 'paddy_blast',
        severity: 'moderate',
        opened_at: '2026-08-25T08:30:00Z',
      },
      model_hypotheses: [{ label: 'paddy_blast', confidence: 0.88 }],
      gate: { outcome: 'escalate', reason_code: 'AMBIGUOUS' },
      field_observations: [],
      images: [],
      treatments_tried: [],
      label_checks: [],
      followup_trend: null,
      spoken_summary: null,
    });

    renderWithRouter('/agronomist/cases');

    await waitFor(() => {
      expect(screen.getByText('Paddy Blast')).toBeInTheDocument();
    });

    const reviewBtn = screen.getByRole('button', { name: /review case c_001_paddy/i });
    await user.click(reviewBtn);

    await waitFor(() => {
      expect(screen.getByText('Case Workspace')).toBeInTheDocument();
      expect(screen.getByText('c_001_paddy')).toBeInTheDocument();
    });
  });

  // -------------------------------------------------------------------------
  // 6. Role Protection Test
  // -------------------------------------------------------------------------
  it('blocks official role from accessing /agronomist/cases and displays 403 Forbidden', async () => {
    tokenStorage.setToken('valid_jwt_official');
    tokenStorage.setUser(mockOfficialUser);

    renderWithRouter('/agronomist/cases');

    await waitFor(() => {
      expect(screen.getByText('Access Restricted')).toBeInTheDocument();
      expect(
        screen.getByText(/your account does not have permission to access this workspace/i)
      ).toBeInTheDocument();
    });
  });

  // -------------------------------------------------------------------------
  // 7. Error Handling & Retry Test
  // -------------------------------------------------------------------------
  it('renders ErrorState with retry capability when API fails', async () => {
    const user = userEvent.setup();
    tokenStorage.setToken('valid_jwt');
    tokenStorage.setUser(mockAgronomistUser);

    const apiSpy = vi
      .spyOn(apiClient, 'get')
      .mockRejectedValueOnce(
        new BhoomiApiError(0, 'NETWORK_ERROR', 'Network connection failed', undefined, true)
      )
      .mockResolvedValueOnce(sampleQueueResponse);

    renderWithRouter('/agronomist/cases');

    await waitFor(() => {
      expect(screen.getByText('Error Loading Queue')).toBeInTheDocument();
      expect(screen.getByText('Network connection failed')).toBeInTheDocument();
    });

    const retryBtn = screen.getByRole('button', { name: /retry request/i });
    await user.click(retryBtn);

    await waitFor(() => {
      expect(screen.getByText('Paddy Blast')).toBeInTheDocument();
    });

    expect(apiSpy).toHaveBeenCalledTimes(2);
  });
});
