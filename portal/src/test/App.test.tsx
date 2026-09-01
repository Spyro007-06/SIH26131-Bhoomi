import { render, screen } from '@testing-library/react';
import { describe, it, expect } from 'vitest';
import { createMemoryRouter, RouterProvider } from 'react-router-dom';
import { Button } from '@/components/ui/Button';
import { Badge } from '@/components/ui/Badge';
import { Card, CardHeader, CardTitle, CardContent } from '@/components/ui/Card';
import { Input } from '@/components/ui/Input';
import { AppProviders } from '@/app/providers';
import { routes } from '@/app/router';
import { ENDPOINTS } from '@/lib/api/endpoints';

describe('BHOOMI Phase 0 Foundation Tests', () => {
  it('renders application login screen for unauthenticated users', () => {
    const memoryRouter = createMemoryRouter(routes, {
      initialEntries: ['/login'],
    });

    render(
      <AppProviders>
        <RouterProvider router={memoryRouter} />
      </AppProviders>
    );

    expect(screen.getByText('BHOOMI Portal')).toBeInTheDocument();
    expect(
      screen.getByText('Agronomist Case Management & Officials Surveillance')
    ).toBeInTheDocument();
    expect(screen.getByRole('button', { name: /sign in to workspace/i })).toBeInTheDocument();
  });

  it('renders UI Button with correct variants and attributes', () => {
    render(
      <Button variant="primary" size="md">
        Confirm Diagnosis
      </Button>
    );
    const button = screen.getByRole('button', { name: /confirm diagnosis/i });
    expect(button).toBeInTheDocument();
    expect(button).toHaveClass('bg-bhoomi-green-700');
  });

  it('renders Badge with semantic agricultural styling', () => {
    render(<Badge variant="primary">Paddy Blast</Badge>);
    expect(screen.getByText('Paddy Blast')).toBeInTheDocument();
  });

  it('renders Card container with subtle borders and content', () => {
    render(
      <Card>
        <CardHeader>
          <CardTitle>Case Summary</CardTitle>
        </CardHeader>
        <CardContent>
          <p>Confidence: 87%</p>
        </CardContent>
      </Card>
    );
    expect(screen.getByText('Case Summary')).toBeInTheDocument();
    expect(screen.getByText('Confidence: 87%')).toBeInTheDocument();
  });

  it('renders accessible Input with label and error state', () => {
    render(
      <Input
        label="Crop Stage"
        error="Invalid stage"
        placeholder="Enter stage"
        defaultValue=""
      />
    );
    expect(screen.getByLabelText('Crop Stage')).toBeInTheDocument();
    expect(screen.getByText('Invalid stage')).toBeInTheDocument();
  });

  it('verifies frozen API contract endpoint inventory integrity', () => {
    expect(ENDPOINTS.AUTH.LOGIN).toBe('/auth/login');
    expect(ENDPOINTS.AGRONOMIST.CASE_QUEUE).toBe('/agronomist/case-queue');
    expect(ENDPOINTS.AGRONOMIST.CONFIRM('c_123')).toBe('/cases/c_123/confirm');
    expect(ENDPOINTS.OFFICIALS.HOTSPOTS).toBe('/officials/hotspots');
    expect(ENDPOINTS.OFFICIALS.ACCURACY).toBe('/officials/accuracy');
    expect(ENDPOINTS.OFFICIALS.QUEUE).toBe('/officials/queue');
  });
});
