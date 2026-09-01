import { render, screen, waitFor, act } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { describe, it, expect, beforeEach, vi } from 'vitest';
import { createMemoryRouter, RouterProvider } from 'react-router-dom';
import { AppProviders } from '@/app/providers';
import { routes } from '@/app/router';
import { tokenStorage } from '@/lib/auth/token-storage';
import { apiClient } from '@/lib/api/client';
import { BhoomiApiError } from '@/lib/api/errors';
import { authApi } from '@/features/auth/api';
import { UserProfile } from '@/types/api';

describe('BHOOMI Phase 1 — Complete Auth Matrix & Routing Tests', () => {
  beforeEach(() => {
    tokenStorage.clearAll();
    vi.restoreAllMocks();
  });

  const renderWithRouter = (initialPath: string) => {
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
  // CASE 1: No token → protected route → redirect to login
  // -------------------------------------------------------------------------
  it('CASE 1: Redirects unauthenticated user from protected route to /login', async () => {
    renderWithRouter('/agronomist');

    await waitFor(() => {
      expect(screen.getByText('BHOOMI Portal')).toBeInTheDocument();
      expect(screen.getByRole('button', { name: /sign in to workspace/i })).toBeInTheDocument();
    });
  });

  // -------------------------------------------------------------------------
  // CASE 2: Valid agronomist session → /agronomist → allowed
  // -------------------------------------------------------------------------
  it('CASE 2: Allows authenticated agronomist access to /agronomist workspace', async () => {
    const agronomistUser: UserProfile = {
      id: 'usr_agro_1',
      name: 'Dr. Suresh Patil',
      role: 'agronomist',
      email: 'spatil@kvk.gov.in',
    };
    tokenStorage.setToken('valid_jwt_token_agronomist');
    tokenStorage.setUser(agronomistUser);

    renderWithRouter('/agronomist');

    await waitFor(() => {
      expect(screen.getByRole('heading', { name: 'Case Queue' })).toBeInTheDocument();
      expect(screen.getByText('Dr. Suresh Patil')).toBeInTheDocument();
      expect(screen.getByText('Agronomist Portal')).toBeInTheDocument();
    });
  });

  // -------------------------------------------------------------------------
  // CASE 3: Valid official session → /official → allowed
  // -------------------------------------------------------------------------
  it('CASE 3: Allows authenticated agriculture official access to /official workspace', async () => {
    const officialUser: UserProfile = {
      id: 'usr_off_1',
      name: 'Officer A. Deshmukh',
      role: 'official',
      email: 'deshmukh@maha.gov.in',
    };
    tokenStorage.setToken('valid_jwt_token_official');
    tokenStorage.setUser(officialUser);

    renderWithRouter('/official');

    await waitFor(() => {
      expect(screen.getByText('Agriculture Officials Dashboard')).toBeInTheDocument();
      expect(screen.getByText('Officer A. Deshmukh')).toBeInTheDocument();
      expect(screen.getByText('Officials Dashboard')).toBeInTheDocument();
    });
  });

  // -------------------------------------------------------------------------
  // CASE 4: Agronomist → /official → forbidden screen
  // -------------------------------------------------------------------------
  it('CASE 4: Displays 403 Forbidden when agronomist attempts to access /official', async () => {
    const agronomistUser: UserProfile = {
      id: 'usr_agro_1',
      name: 'Dr. Suresh Patil',
      role: 'agronomist',
      email: 'spatil@kvk.gov.in',
    };
    tokenStorage.setToken('valid_jwt_token_agronomist');
    tokenStorage.setUser(agronomistUser);

    renderWithRouter('/official');

    await waitFor(() => {
      expect(screen.getByText('Access Restricted')).toBeInTheDocument();
      expect(
        screen.getByText(/your account does not have permission to access this workspace/i)
      ).toBeInTheDocument();
      expect(screen.getByRole('button', { name: /return to your workspace/i })).toBeInTheDocument();
    });
  });

  // -------------------------------------------------------------------------
  // CASE 5: Official → /agronomist → forbidden screen
  // -------------------------------------------------------------------------
  it('CASE 5: Displays 403 Forbidden when official attempts to access /agronomist', async () => {
    const officialUser: UserProfile = {
      id: 'usr_off_1',
      name: 'Officer A. Deshmukh',
      role: 'official',
      email: 'deshmukh@maha.gov.in',
    };
    tokenStorage.setToken('valid_jwt_token_official');
    tokenStorage.setUser(officialUser);

    renderWithRouter('/agronomist');

    await waitFor(() => {
      expect(screen.getByText('Access Restricted')).toBeInTheDocument();
      expect(
        screen.getByText(/your account does not have permission to access this workspace/i)
      ).toBeInTheDocument();
      expect(screen.getByRole('button', { name: /return to your workspace/i })).toBeInTheDocument();
    });
  });

  // -------------------------------------------------------------------------
  // CASE 6: Invalid token → API 401 → clear auth
  // -------------------------------------------------------------------------
  it('CASE 6: Handles 401 UNAUTHENTICATED by purging stored token and session', async () => {
    const agronomistUser: UserProfile = {
      id: 'usr_agro_1',
      name: 'Dr. Suresh Patil',
      role: 'agronomist',
      email: 'spatil@kvk.gov.in',
    };
    tokenStorage.setToken('stale_expired_token');
    tokenStorage.setUser(agronomistUser);

    // Mock an endpoint returning 401
    vi.spyOn(globalThis, 'fetch').mockResolvedValueOnce(
      new Response(
        JSON.stringify({
          error: {
            code: 'UNAUTHENTICATED',
            message: 'Session expired or token invalid',
            details: {},
          },
        }),
        {
          status: 401,
          headers: { 'Content-Type': 'application/json' },
        }
      )
    );

    renderWithRouter('/agronomist');

    // Trigger an API request that receives 401 wrapped in act()
    await act(async () => {
      try {
        await apiClient.get('/agronomist/case-queue');
      } catch (err) {
        expect(err).toBeInstanceOf(BhoomiApiError);
      }
    });

    // Assert that auth storage was wiped clean
    expect(tokenStorage.getToken()).toBeNull();
    expect(tokenStorage.getUser()).toBeNull();
  });

  // -------------------------------------------------------------------------
  // CASE 7: Valid auth → logout → token cleared → query cache cleared → login
  // -------------------------------------------------------------------------
  it('CASE 7: Logs out user, purges token and cache, and redirects to /login', async () => {
    const user = userEvent.setup();
    const agronomistUser: UserProfile = {
      id: 'usr_agro_1',
      name: 'Dr. Suresh Patil',
      role: 'agronomist',
      email: 'spatil@kvk.gov.in',
    };
    tokenStorage.setToken('valid_jwt_token');
    tokenStorage.setUser(agronomistUser);

    renderWithRouter('/agronomist');

    await waitFor(() => {
      expect(screen.getByText('Sign Out')).toBeInTheDocument();
    });

    const signOutBtn = screen.getByRole('button', { name: /sign out/i });
    await user.click(signOutBtn);

    expect(tokenStorage.getToken()).toBeNull();
    expect(tokenStorage.getUser()).toBeNull();

    await waitFor(() => {
      expect(screen.getByText('BHOOMI Portal')).toBeInTheDocument();
      expect(screen.getByRole('button', { name: /sign in to workspace/i })).toBeInTheDocument();
    });
  });

  // -------------------------------------------------------------------------
  // CASE 8: Login API failure → error displayed → remains unauthenticated
  // -------------------------------------------------------------------------
  it('CASE 8: Displays authentication error banner on invalid credentials and keeps user unauthenticated', async () => {
    const user = userEvent.setup();

    vi.spyOn(authApi, 'login').mockRejectedValueOnce(
      new BhoomiApiError(401, 'UNAUTHENTICATED', 'Invalid official credentials.')
    );

    renderWithRouter('/login');

    const emailInput = screen.getByLabelText(/official email/i);
    const passwordInput = screen.getByLabelText(/password/i);
    const submitBtn = screen.getByRole('button', { name: /sign in to workspace/i });

    await user.type(emailInput, 'wrong@kvk.gov.in');
    await user.type(passwordInput, 'wrongpassword');
    await user.click(submitBtn);

    await waitFor(() => {
      expect(
        screen.getByText(/invalid official credentials\. please verify your email and password\./i)
      ).toBeInTheDocument();
    });

    expect(tokenStorage.getToken()).toBeNull();
    expect(tokenStorage.getUser()).toBeNull();
  });
});
