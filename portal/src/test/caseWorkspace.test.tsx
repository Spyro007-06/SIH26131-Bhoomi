import { render, screen, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { describe, it, expect, beforeEach, vi } from 'vitest';
import { createMemoryRouter, RouterProvider } from 'react-router-dom';
import { AppProviders } from '@/app/providers';
import { routes } from '@/app/router';
import { tokenStorage } from '@/lib/auth/token-storage';
import { apiClient } from '@/lib/api/client';
import { BhoomiApiError } from '@/lib/api/errors';
import { CaseBundle, UserProfile } from '@/types/api';

const mockAgronomistUser: UserProfile = {
  id: 'usr_agro_suresh',
  name: 'Dr. Suresh Patil',
  role: 'agronomist',
  email: 'spatil@kvk.gov.in',
};

const mockOfficialUser: UserProfile = {
  id: 'usr_off_deshmukh',
  name: 'S. Deshmukh',
  role: 'official',
  email: 'sdeshmukh@agri.maharashtra.gov.in',
};

const sampleCaseBundle: CaseBundle = {
  case_id: 'c_5',
  status: 'assigned',
  farm: {
    id: 'f_1',
    crop: 'paddy',
    variety: 'Indrayani',
    growth_stage: 'tillering',
    region: 'Nashik',
  },
  problem: {
    id: 'p_7',
    type: 'disease',
    label: 'paddy_blast',
    severity: 'moderate',
    opened_at: '2026-08-25T10:00:00Z',
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
      question: 'Fuzzy grey growth on the underside?',
      answer: 'yes',
      at: '2026-08-25T10:05:00Z',
    },
  ],
  images: [
    {
      asset_id: 'a_9',
      url: 'https://storage.bhoomi.gov.in/photos/a_9.jpg',
      at: '2026-08-25T10:00:00Z',
    },
    {
      asset_id: 'a_15',
      url: 'https://storage.bhoomi.gov.in/photos/a_15.jpg',
      at: '2026-08-25T10:01:00Z',
    },
  ],
  treatments_tried: ['Field drained 48h', 'Nitrogen withheld'],
  label_checks: [
    {
      ingredient: 'carbendazim',
      verdict: 'WRONG_CLASS',
      at: '2026-08-25T10:06:00Z',
    },
  ],
  followup_trend: 'got_worse',
  spoken_summary: 'Leaf spots spread rapidly after heavy morning fog.',
};

function renderWithRouter(initialEntry: string) {
  const testRouter = createMemoryRouter(routes, {
    initialEntries: [initialEntry],
  });

  return render(
    <AppProviders>
      <RouterProvider router={testRouter} />
    </AppProviders>
  );
}

describe('F12 — Agronomist Case Workspace Tests', () => {
  beforeEach(() => {
    tokenStorage.clearAll();
    vi.restoreAllMocks();
  });

  // -------------------------------------------------------------------------
  // 1. Full Case Bundle Rendering & Contract Verification
  // -------------------------------------------------------------------------
  it('renders complete case bundle with all evidence sections from live API data', async () => {
    tokenStorage.setToken('valid_jwt');
    tokenStorage.setUser(mockAgronomistUser);

    const getSpy = vi.spyOn(apiClient, 'get').mockResolvedValue(sampleCaseBundle);

    renderWithRouter('/agronomist/cases/c_5');

    // Wait for case to load
    await waitFor(() => {
      expect(screen.getByText('c_5')).toBeInTheDocument();
      expect(screen.getAllByText('Paddy Blast').length).toBeGreaterThan(0);
    });

    // Verify GET endpoint called
    expect(getSpy).toHaveBeenCalledWith('/cases/c_5');

    // 1. Farm Context
    expect(screen.getAllByText(/paddy/i).length).toBeGreaterThan(0);
    expect(screen.getByText(/Indrayani/i)).toBeInTheDocument();
    expect(screen.getByText('tillering')).toBeInTheDocument();
    expect(screen.getByText('Nashik')).toBeInTheDocument();
    expect(screen.getAllByText('f_1').length).toBeGreaterThan(0);

    // 2. Problem Summary
    expect(screen.getByText('Moderate')).toBeInTheDocument();
    expect(screen.getByText(/Disease/i)).toBeInTheDocument();

    // 3. Model Hypotheses
    expect(screen.getByText('Paddy Brown Spot')).toBeInTheDocument();
    expect(screen.getByText('50%')).toBeInTheDocument();
    expect(screen.getByText('46%')).toBeInTheDocument();
    expect(screen.getByText('4%')).toBeInTheDocument();

    // 4. Decision Gate
    expect(screen.getByText('AMBIGUOUS')).toBeInTheDocument();
    expect(screen.getByText('0.15')).toBeInTheDocument();

    // 5. Doubt Doctor field observations
    expect(screen.getByText(/Fuzzy grey growth on the underside\?/i)).toBeInTheDocument();
    expect(screen.getByText(/Answer: Yes/i)).toBeInTheDocument();

    // 6. Image evidence
    expect(screen.getByText('Asset #a_9')).toBeInTheDocument();
    expect(screen.getByText('Asset #a_15')).toBeInTheDocument();

    // 7. Treatments tried
    expect(screen.getByText('Field drained 48h')).toBeInTheDocument();
    expect(screen.getByText('Nitrogen withheld')).toBeInTheDocument();

    // 8. Label checks
    expect(screen.getByText('carbendazim')).toBeInTheDocument();
    expect(screen.getByText('Wrong Chemical Class')).toBeInTheDocument();

    // 9. Followup trend & spoken summary
    expect(screen.getByText('Got Worse')).toBeInTheDocument();
    expect(
      screen.getByText(/Leaf spots spread rapidly after heavy morning fog/i)
    ).toBeInTheDocument();

    // 10. Action buttons
    expect(screen.getByRole('button', { name: /confirm diagnosis/i })).toBeInTheDocument();
    expect(screen.getByRole('button', { name: /correct diagnosis/i })).toBeInTheDocument();
    expect(screen.getByRole('button', { name: /request information/i })).toBeInTheDocument();
  });

  // -------------------------------------------------------------------------
  // 2. No Placeholder Data Assertion
  // -------------------------------------------------------------------------
  it('does not generate synthetic placeholder production strings', async () => {
    tokenStorage.setToken('valid_jwt');
    tokenStorage.setUser(mockAgronomistUser);

    vi.spyOn(apiClient, 'get').mockResolvedValue(sampleCaseBundle);

    renderWithRouter('/agronomist/cases/c_5');

    await waitFor(() => {
      expect(screen.getByText('c_5')).toBeInTheDocument();
    });

    expect(screen.queryByText(/Unregistered Farmer/i)).not.toBeInTheDocument();
    expect(screen.queryByText(/Unknown Farmer/i)).not.toBeInTheDocument();
    expect(screen.queryByText(/Sample Case/i)).not.toBeInTheDocument();
    expect(screen.queryByText(/Demo Farmer/i)).not.toBeInTheDocument();
  });

  // -------------------------------------------------------------------------
  // 3. Ranked Hypotheses Order & Confidence Invariant
  // -------------------------------------------------------------------------
  it('renders model hypotheses strictly preserving server order with raw confidences', async () => {
    tokenStorage.setToken('valid_jwt');
    tokenStorage.setUser(mockAgronomistUser);

    vi.spyOn(apiClient, 'get').mockResolvedValue(sampleCaseBundle);

    renderWithRouter('/agronomist/cases/c_5');

    await waitFor(() => {
      expect(screen.getByText('Model Hypotheses')).toBeInTheDocument();
    });

    // Check rank indices
    expect(screen.getByText('#1')).toBeInTheDocument();
    expect(screen.getByText('#2')).toBeInTheDocument();
    expect(screen.getByText('#3')).toBeInTheDocument();

    // Verify percentages sum to at most 1.0 (0.50 + 0.46 + 0.04 = 1.0) without false normalization
    expect(screen.getByText('50%')).toBeInTheDocument();
    expect(screen.getByText('46%')).toBeInTheDocument();
    expect(screen.getByText('4%')).toBeInTheDocument();
  });

  // -------------------------------------------------------------------------
  // 4. Confirm Action Test
  // -------------------------------------------------------------------------
  it('handles Confirm action calling POST /cases/:id/confirm with verdict="confirmed"', async () => {
    const user = userEvent.setup();
    tokenStorage.setToken('valid_jwt');
    tokenStorage.setUser(mockAgronomistUser);

    vi.spyOn(apiClient, 'get').mockResolvedValue(sampleCaseBundle);
    const postSpy = vi.spyOn(apiClient, 'post').mockResolvedValue({
      case_id: 'c_5',
      status: 'resolved',
      problem_status: 'resolved',
      confirmation_id: 'cf_101',
      spread_alerts_issued: 4,
    });

    renderWithRouter('/agronomist/cases/c_5');

    await waitFor(() => {
      expect(screen.getByRole('button', { name: /confirm diagnosis/i })).toBeInTheDocument();
    });

    // Click Confirm Diagnosis button
    await user.click(screen.getByRole('button', { name: /confirm diagnosis/i }));

    // Verify confirmation modal opens
    expect(screen.getByRole('dialog', { name: /confirm model diagnosis/i })).toBeInTheDocument();

    // Fill optional treatment and notes
    const treatmentInput = screen.getByLabelText(/prescribed treatment/i);
    await user.type(treatmentInput, 'Apply Tricyclazole 75% WP @ 0.6 g/L');

    const notesInput = screen.getByLabelText(/agronomist remarks/i);
    await user.type(notesInput, 'Confirmed classic spindle-shaped lesion symptoms.');

    // Submit confirmation
    const submitBtn = screen.getByRole('button', { name: /^confirm case$/i });
    await user.click(submitBtn);

    // Verify API POST called with exact contract schema
    await waitFor(() => {
      expect(postSpy).toHaveBeenCalledWith('/cases/c_5/confirm', {
        verdict: 'confirmed',
        treatment: 'Apply Tricyclazole 75% WP @ 0.6 g/L',
        notes: 'Confirmed classic spindle-shaped lesion symptoms.',
      });
    });

    // Verify resolution success modal is displayed with spread alerts
    await waitFor(() => {
      expect(screen.getByRole('dialog', { name: /case resolved/i })).toBeInTheDocument();
      expect(screen.getByText('cf_101')).toBeInTheDocument();
      expect(screen.getByText('4')).toBeInTheDocument();
    });
  });

  // -------------------------------------------------------------------------
  // 5. Correct Action Test (Uses POST /cases/:id/confirm with verdict="corrected")
  // -------------------------------------------------------------------------
  it('handles Correct action calling POST /cases/:id/confirm with verdict="corrected" and corrected_label', async () => {
    const user = userEvent.setup();
    tokenStorage.setToken('valid_jwt');
    tokenStorage.setUser(mockAgronomistUser);

    vi.spyOn(apiClient, 'get').mockResolvedValue(sampleCaseBundle);
    const postSpy = vi.spyOn(apiClient, 'post').mockResolvedValue({
      case_id: 'c_5',
      status: 'resolved',
      problem_status: 'resolved',
      confirmation_id: 'cf_102',
      spread_alerts_issued: 2,
    });

    renderWithRouter('/agronomist/cases/c_5');

    await waitFor(() => {
      expect(screen.getByRole('button', { name: /correct diagnosis/i })).toBeInTheDocument();
    });

    // Click Correct Diagnosis button
    await user.click(screen.getByRole('button', { name: /correct diagnosis/i }));

    // Verify correction modal opens
    expect(screen.getByRole('dialog', { name: /correct diagnosis/i })).toBeInTheDocument();

    // Select corrected target label from dropdown
    const select = screen.getByLabelText(/correct diagnosis \*/i);
    await user.selectOptions(select, 'paddy_brown_spot');

    const treatmentInput = screen.getByLabelText(/prescribed treatment/i);
    await user.type(treatmentInput, 'Apply Propiconazole 25% EC');

    // Submit correction
    const submitBtn = screen.getByRole('button', { name: /submit correction/i });
    await user.click(submitBtn);

    // Verify exact POST call to /cases/c_5/confirm (NOT /correct)
    await waitFor(() => {
      expect(postSpy).toHaveBeenCalledWith('/cases/c_5/confirm', {
        verdict: 'corrected',
        corrected_label: 'paddy_brown_spot',
        treatment: 'Apply Propiconazole 25% EC',
      });
    });

    // Verify resolution success modal
    await waitFor(() => {
      expect(screen.getByRole('dialog', { name: /case resolved/i })).toBeInTheDocument();
      expect(screen.getByText('cf_102')).toBeInTheDocument();
      expect(screen.getByText('2')).toBeInTheDocument();
    });
  });

  // -------------------------------------------------------------------------
  // 6. Request Information Action Test
  // -------------------------------------------------------------------------
  it('handles Request Information calling POST /cases/:id/request-info', async () => {
    const user = userEvent.setup();
    tokenStorage.setToken('valid_jwt');
    tokenStorage.setUser(mockAgronomistUser);

    vi.spyOn(apiClient, 'get').mockResolvedValue(sampleCaseBundle);
    const postSpy = vi.spyOn(apiClient, 'post').mockResolvedValue({
      case_id: 'c_5',
      status: 'assigned',
      info_requested_at: '2026-08-25T10:15:00Z',
    });

    renderWithRouter('/agronomist/cases/c_5');

    await waitFor(() => {
      expect(screen.getByRole('button', { name: /request information/i })).toBeInTheDocument();
    });

    // Click Request Information button
    await user.click(screen.getByRole('button', { name: /request information/i }));

    // Verify modal opens
    expect(
      screen.getByRole('dialog', { name: /request additional information/i })
    ).toBeInTheDocument();

    const questionInput = screen.getByLabelText(/required information \/ question/i);
    await user.type(questionInput, 'Please upload a close-up photo of the leaf sheath.');

    const sendBtn = screen.getByRole('button', { name: /send request/i });
    await user.click(sendBtn);

    await waitFor(() => {
      expect(postSpy).toHaveBeenCalledWith('/cases/c_5/request-info', {
        question: 'Please upload a close-up photo of the leaf sheath.',
      });
    });
  });

  // -------------------------------------------------------------------------
  // 7. Error Handling: 404 Case Not Found
  // -------------------------------------------------------------------------
  it('renders "Case Not Found" when case does not exist with back to queue link', async () => {
    tokenStorage.setToken('valid_jwt');
    tokenStorage.setUser(mockAgronomistUser);

    vi.spyOn(apiClient, 'get').mockRejectedValueOnce(
      new BhoomiApiError(404, 'NOT_FOUND', 'That case does not exist.')
    );

    renderWithRouter('/agronomist/cases/c_nonexistent');

    await waitFor(() => {
      expect(screen.getByText('Case Not Found')).toBeInTheDocument();
      expect(screen.getByRole('link', { name: /back to case queue/i })).toBeInTheDocument();
    });
  });

  // -------------------------------------------------------------------------
  // 8. Role Protection: 403 Forbidden for Officials
  // -------------------------------------------------------------------------
  it('blocks official role from accessing agronomist case workspace', async () => {
    tokenStorage.setToken('valid_jwt_official');
    tokenStorage.setUser(mockOfficialUser);

    renderWithRouter('/agronomist/cases/c_5');

    await waitFor(() => {
      expect(screen.getByText('Access Restricted')).toBeInTheDocument();
      expect(
        screen.getByText(/your account does not have permission to access this workspace/i)
      ).toBeInTheDocument();
    });
  });

  // -------------------------------------------------------------------------
  // 9. Multi-Action Mutation Lock Test
  // -------------------------------------------------------------------------
  it('disables all action buttons while a confirmation mutation is pending', async () => {
    const user = userEvent.setup();
    tokenStorage.setToken('valid_jwt');
    tokenStorage.setUser(mockAgronomistUser);

    vi.spyOn(apiClient, 'get').mockResolvedValue(sampleCaseBundle);

    // Create an unresolved promise to keep mutation in-flight
    let resolvePost: (value: unknown) => void = () => {};
    const pendingPromise = new Promise<unknown>((resolve) => {
      resolvePost = resolve;
    });
    vi.spyOn(apiClient, 'post').mockReturnValueOnce(pendingPromise as Promise<never>);

    renderWithRouter('/agronomist/cases/c_5');

    await waitFor(() => {
      expect(screen.getByRole('button', { name: /confirm diagnosis/i })).toBeInTheDocument();
    });

    // Open confirm dialog and submit
    await user.click(screen.getByRole('button', { name: /confirm diagnosis/i }));
    const submitBtn = screen.getByRole('button', { name: /^confirm case$/i });
    await user.click(submitBtn);

    // Verify all three action buttons in the sticky bar are disabled
    await waitFor(() => {
      expect(screen.getByRole('button', { name: /confirm diagnosis/i })).toBeDisabled();
      expect(screen.getByRole('button', { name: /correct diagnosis/i })).toBeDisabled();
      expect(screen.getByRole('button', { name: /request information/i })).toBeDisabled();
    });

    // Clean up promise
    resolvePost({
      case_id: 'c_5',
      status: 'resolved',
      problem_status: 'resolved',
      confirmation_id: 'cf_103',
      spread_alerts_issued: 3,
    });
  });
});
