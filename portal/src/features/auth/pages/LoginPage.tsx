import { useState, FormEvent } from 'react';
import { useNavigate, useLocation } from 'react-router-dom';
import { useAuth } from '@/features/auth/hooks';
import { Button } from '@/components/ui/Button';
import { Input } from '@/components/ui/Input';
import { Card, CardHeader, CardTitle, CardDescription, CardContent, CardFooter } from '@/components/ui/Card';
import { Sprout, AlertCircle, WifiOff } from 'lucide-react';
import { isBhoomiApiError } from '@/lib/api/errors';
import { loginRequestSchema } from '../validation';
import { ZodError } from 'zod';
import { UserProfile } from '@/types/api';

export function LoginPage() {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [fieldErrors, setFieldErrors] = useState<{ email?: string; password?: string }>({});
  const [generalError, setGeneralError] = useState<{ message: string; isNetwork?: boolean } | null>(
    null
  );
  const [isSubmitting, setIsSubmitting] = useState(false);

  const { login } = useAuth();
  const navigate = useNavigate();
  const location = useLocation();

  const getSafeRedirectPath = (fromPath: string | undefined, user: UserProfile): string => {
    const defaultPath = user.role === 'agronomist' ? '/agronomist' : '/official';
    if (!fromPath) return defaultPath;

    // Open redirect protection: ensure internal relative path only
    if (!fromPath.startsWith('/') || fromPath.startsWith('//') || fromPath.includes('\\')) {
      return defaultPath;
    }

    // Role-boundary check for destination
    if (user.role === 'agronomist' && fromPath.startsWith('/agronomist')) {
      return fromPath;
    }
    if (user.role === 'official' && fromPath.startsWith('/official')) {
      return fromPath;
    }

    return defaultPath;
  };

  const handleSubmit = async (e: FormEvent) => {
    e.preventDefault();
    setFieldErrors({});
    setGeneralError(null);

    // Client-side schema validation
    try {
      loginRequestSchema.parse({ email, password });
    } catch (err: unknown) {
      if (err instanceof ZodError) {
        const errors: { email?: string; password?: string } = {};
        err.errors.forEach((issue) => {
          if (issue.path[0] === 'email') errors.email = issue.message;
          if (issue.path[0] === 'password') errors.password = issue.message;
        });
        setFieldErrors(errors);
        return;
      }
    }

    setIsSubmitting(true);

    try {
      const response = await login({ email, password });
      const from = (location.state as { from?: { pathname: string } })?.from?.pathname;
      const targetPath = getSafeRedirectPath(from, response.user);
      navigate(targetPath, { replace: true });
    } catch (err: unknown) {
      if (isBhoomiApiError(err)) {
        if (err.isNetworkError()) {
          setGeneralError({
            message: 'Unable to reach the BHOOMI API server. Please verify your network connection.',
            isNetwork: true,
          });
        } else if (err.isUnauthorized()) {
          setGeneralError({
            message: 'Invalid official credentials. Please verify your email and password.',
          });
        } else if (err.isForbidden()) {
          setGeneralError({
            message: 'Your account is not authorized to access this portal.',
          });
        } else {
          setGeneralError({
            message: err.message || 'Authentication failed. Please try again.',
          });
        }
      } else if (err instanceof Error) {
        setGeneralError({ message: err.message });
      } else {
        setGeneralError({ message: 'An unexpected authentication error occurred.' });
      }
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <div className="min-h-screen flex items-center justify-center bg-bhoomi-background p-4">
      <div className="w-full max-w-md space-y-6">
        <div className="text-center space-y-2">
          <div className="inline-flex h-12 w-12 items-center justify-center rounded-xl bg-bhoomi-green-800 text-bhoomi-cream shadow-sm">
            <Sprout className="h-7 w-7" />
          </div>
          <h1 className="text-2xl font-bold tracking-tight text-bhoomi-green-900">BHOOMI Portal</h1>
          <p className="text-sm text-bhoomi-text-secondary">
            Agronomist Case Management & Officials Surveillance
          </p>
        </div>

        <Card>
          <CardHeader>
            <CardTitle>Sign In</CardTitle>
            <CardDescription>
              Enter your official credentials to access your portal workspace.
            </CardDescription>
          </CardHeader>

          <form onSubmit={handleSubmit} noValidate>
            <CardContent className="space-y-4">
              {generalError && (
                <div
                  role="alert"
                  className="rounded-lg bg-red-50 p-3.5 text-sm text-bhoomi-danger border border-red-200 flex items-start gap-2.5"
                >
                  {generalError.isNetwork ? (
                    <WifiOff className="h-5 w-5 shrink-0 text-bhoomi-danger mt-0.5" />
                  ) : (
                    <AlertCircle className="h-5 w-5 shrink-0 text-bhoomi-danger mt-0.5" />
                  )}
                  <div className="leading-snug">{generalError.message}</div>
                </div>
              )}

              <Input
                label="Official Email"
                type="email"
                placeholder="name@kvk.gov.in"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                autoComplete="email"
                error={fieldErrors.email}
                required
                disabled={isSubmitting}
              />

              <Input
                label="Password"
                type="password"
                placeholder="••••••••"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                autoComplete="current-password"
                error={fieldErrors.password}
                required
                disabled={isSubmitting}
              />
            </CardContent>

            <CardFooter className="pt-2">
              <Button type="submit" className="w-full" isLoading={isSubmitting}>
                Sign In to Workspace
              </Button>
            </CardFooter>
          </form>
        </Card>

        <div className="text-center">
          <p className="text-xs text-bhoomi-text-secondary">
            Government of Maharashtra · SIH26131
          </p>
        </div>
      </div>
    </div>
  );
}
