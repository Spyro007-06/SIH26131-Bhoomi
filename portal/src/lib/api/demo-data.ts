import {
  AccuracyResponse,
  CaseBundle,
  CaseConfirmResponse,
  CaseQueueResponse,
  CaseRequestInfoResponse,
  HotspotsResponse,
  OfficialsQueueResponse,
} from '@/types/api';

export const DEMO_HOTSPOTS: HotspotsResponse = {
  points: [
    {
      lat: 18.5204,
      lng: 73.8567,
      label: 'paddy_blast',
      confirmed_count: 14,
      first_seen: '2026-08-20T08:00:00Z',
      last_seen: '2026-08-31T14:30:00Z',
    },
    {
      lat: 19.9975,
      lng: 73.7898,
      label: 'cotton_pink_bollworm',
      confirmed_count: 8,
      first_seen: '2026-08-22T09:15:00Z',
      last_seen: '2026-08-30T16:45:00Z',
    },
    {
      lat: 16.705,
      lng: 74.2433,
      label: 'soybean_yellow_mosaic_virus',
      confirmed_count: 11,
      first_seen: '2026-08-18T10:00:00Z',
      last_seen: '2026-08-31T11:20:00Z',
    },
    {
      lat: 19.8762,
      lng: 75.3433,
      label: 'jowar_stem_borer',
      confirmed_count: 6,
      first_seen: '2026-08-25T07:30:00Z',
      last_seen: '2026-08-29T18:00:00Z',
    },
    {
      lat: 20.9042,
      lng: 74.7749,
      label: 'paddy_blast',
      confirmed_count: 9,
      first_seen: '2026-08-24T11:00:00Z',
      last_seen: '2026-08-31T15:10:00Z',
    },
  ],
  totals_by_label: {
    paddy_blast: 23,
    cotton_pink_bollworm: 8,
    soybean_yellow_mosaic_virus: 11,
    jowar_stem_borer: 6,
  },
};

export const DEMO_ACCURACY: AccuracyResponse = {
  by_label: [
    {
      label: 'paddy_blast',
      confirmed: 42,
      corrected: 3,
      accuracy: 0.9333,
    },
    {
      label: 'cotton_pink_bollworm',
      confirmed: 28,
      corrected: 2,
      accuracy: 0.9333,
    },
    {
      label: 'soybean_yellow_mosaic_virus',
      confirmed: 19,
      corrected: 4,
      accuracy: 0.8261,
    },
    {
      label: 'jowar_stem_borer',
      confirmed: 31,
      corrected: 1,
      accuracy: 0.9688,
    },
    {
      label: 'paddy_brown_spot',
      confirmed: 15,
      corrected: 2,
      accuracy: 0.8824,
    },
  ],
  window: {
    from: '2026-08-01',
    to: '2026-08-31',
  },
};

export const DEMO_OFFICIAL_QUEUE: OfficialsQueueResponse = {
  queue: [
    {
      case_id: 'case_off_001',
      predicted_label: 'paddy_blast',
      confidence: 0.88,
      severity: 'severe',
      region: 'Pune (Baramati)',
      created_at: '2026-08-31T09:30:00Z',
    },
    {
      case_id: 'case_off_002',
      predicted_label: 'cotton_pink_bollworm',
      confidence: 0.92,
      severity: 'severe',
      region: 'Nashik (Dindori)',
      created_at: '2026-08-31T10:15:00Z',
    },
    {
      case_id: 'case_off_003',
      predicted_label: 'soybean_yellow_mosaic_virus',
      confidence: 0.79,
      severity: 'moderate',
      region: 'Kolhapur (Karveer)',
      created_at: '2026-08-31T11:00:00Z',
    },
    {
      case_id: 'case_off_004',
      predicted_label: 'jowar_stem_borer',
      confidence: 0.85,
      severity: 'severe',
      region: 'Sangli (Miraj)',
      created_at: '2026-08-31T11:45:00Z',
    },
    {
      case_id: 'case_off_005',
      predicted_label: 'cotton_whitefly',
      confidence: 0.91,
      severity: 'severe',
      region: 'Aurangabad (Paithan)',
      created_at: '2026-08-31T12:20:00Z',
    },
  ],
  next_cursor: null,
};

export const DEMO_CASE_QUEUE: CaseQueueResponse = {
  cases: [
    {
      case_id: 'case_demo_001',
      problem_id: 'prob_demo_001',
      farm_id: 'farm_demo_001',
      region: 'Pune (Baramati)',
      label: 'paddy_blast',
      status: 'assigned',
      queue_position: 1,
      eta_minutes: 15,
      created_at: '2026-08-31T09:30:00Z',
    },
    {
      case_id: 'case_demo_002',
      problem_id: 'prob_demo_002',
      farm_id: 'farm_demo_002',
      region: 'Nashik (Dindori)',
      label: 'cotton_pink_bollworm',
      status: 'assigned',
      queue_position: 2,
      eta_minutes: 30,
      created_at: '2026-08-31T10:15:00Z',
    },
    {
      case_id: 'case_demo_003',
      problem_id: 'prob_demo_003',
      farm_id: 'farm_demo_003',
      region: 'Kolhapur (Karveer)',
      label: 'soybean_yellow_mosaic_virus',
      status: 'assigned',
      queue_position: 3,
      eta_minutes: 45,
      created_at: '2026-08-31T11:00:00Z',
    },
    {
      case_id: 'case_demo_004',
      problem_id: 'prob_demo_004',
      farm_id: 'farm_demo_004',
      region: 'Sangli (Miraj)',
      label: 'jowar_stem_borer',
      status: 'assigned',
      queue_position: 4,
      eta_minutes: 60,
      created_at: '2026-08-31T11:30:00Z',
    },
  ],
  next_cursor: null,
};

export function getDemoCaseBundle(caseId: string): CaseBundle {
  return {
    case_id: caseId || 'case_demo_001',
    status: 'assigned',
    farm: {
      id: 'farm_demo_001',
      crop: 'paddy',
      variety: 'Indrayani',
      growth_stage: 'panicle_initiation',
      region: 'Pune (Baramati)',
      location: {
        lat: 18.1512,
        lng: 74.5771,
      },
    },
    problem: {
      id: 'prob_demo_001',
      type: 'disease',
      label: 'paddy_blast',
      severity: 'severe',
      opened_at: '2026-08-31T09:30:00Z',
    },
    images: [
      {
        asset_id: 'asset_001',
        url: 'https://images.unsplash.com/photo-1599940824399-b87987ceb72a?auto=format&fit=crop&w=800&q=80',
        at: '2026-08-31T09:20:00Z',
      },
      {
        asset_id: 'asset_002',
        url: 'https://images.unsplash.com/photo-1586771107445-d3ca888129ff?auto=format&fit=crop&w=800&q=80',
        at: '2026-08-31T09:22:00Z',
      },
    ],
    model_hypotheses: [
      {
        label: 'paddy_blast',
        confidence: 0.884,
      },
      {
        label: 'paddy_bacterial_leaf_blight',
        confidence: 0.082,
      },
      {
        label: 'paddy_brown_spot',
        confidence: 0.034,
      },
    ],
    gate: {
      outcome: 'escalate',
      reason_code: 'AMBIGUOUS',
      confidence: 0.884,
      threshold_applied: 0.85,
    },
    field_observations: [
      {
        question: 'Are the lesions diamond/spindle shaped with dark borders and grey centers?',
        answer: 'yes',
        at: '2026-08-31T09:25:00Z',
      },
    ],
    treatments_tried: [
      'Neem Oil 1500ppm (5 ml/L) on 2026-08-28 — No reduction in lesion spread',
    ],
    label_checks: [
      {
        ingredient: 'Tricyclazole 75% WP',
        verdict: 'NO_OBJECTION_FOUND',
        at: '2026-08-31T09:26:00Z',
      },
    ],
    followup_trend: 'WORSENING: Affected foliage expanded by ~20% over past 72 hours',
    spoken_summary: 'Spindle-shaped lesions on upper canopy paddy leaves requiring expert validation',
  };
}

export function handleDemoMockResponse<T>(endpoint: string, method = 'GET'): T | null {
  const cleanEndpoint = endpoint.startsWith('/') ? endpoint : `/${endpoint}`;

  if (method === 'GET') {
    if (cleanEndpoint.includes('/officials/hotspots')) {
      return DEMO_HOTSPOTS as unknown as T;
    }
    if (cleanEndpoint.includes('/officials/accuracy')) {
      return DEMO_ACCURACY as unknown as T;
    }
    if (cleanEndpoint.includes('/officials/queue')) {
      return DEMO_OFFICIAL_QUEUE as unknown as T;
    }
    if (cleanEndpoint.includes('/agronomist/case-queue')) {
      return DEMO_CASE_QUEUE as unknown as T;
    }
    if (
      cleanEndpoint.startsWith('/cases/') &&
      !cleanEndpoint.includes('/confirm') &&
      !cleanEndpoint.includes('/request-info')
    ) {
      const parts = cleanEndpoint.split('/');
      const caseId = parts[2] || 'case_demo_001';
      return getDemoCaseBundle(caseId) as unknown as T;
    }
  }

  if (method === 'POST') {
    if (cleanEndpoint.includes('/confirm')) {
      const parts = cleanEndpoint.split('/');
      const caseId = parts[2] || 'case_demo_001';
      const confirmResponse: CaseConfirmResponse = {
        case_id: caseId,
        status: 'resolved',
        problem_status: 'resolved',
        confirmation_id: `conf_demo_${Date.now()}`,
        spread_alerts_issued: 18,
      };
      return confirmResponse as unknown as T;
    }
    if (cleanEndpoint.includes('/request-info')) {
      const parts = cleanEndpoint.split('/');
      const caseId = parts[2] || 'case_demo_001';
      const requestInfoResponse: CaseRequestInfoResponse = {
        case_id: caseId,
        status: 'assigned',
        info_requested_at: new Date().toISOString(),
      };
      return requestInfoResponse as unknown as T;
    }
  }

  return null;
}
