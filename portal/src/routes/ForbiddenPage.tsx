import { useNavigate } from 'react-router-dom';
import { useAuth } from '@/features/auth/hooks';
import { Button } from '@/components/ui/Button';
import { Card, CardHeader, CardTitle, CardDescription, CardContent, CardFooter } from '@/components/ui/Card';
import { ShieldAlert, ArrowLeft } from 'lucide-react';

export function ForbiddenPage() {
  const { user } = useAuth();
  const navigate = useNavigate();

  const handleReturn = () => {
    if (user?.role === 'agronomist') {
      navigate('/agronomist', { replace: true });
    } else if (user?.role === 'official') {
      navigate('/official', { replace: true });
    } else {
      navigate('/login', { replace: true });
    }
  };

  return (
    <div className="min-h-screen flex items-center justify-center bg-bhoomi-background p-4">
      <div className="w-full max-w-md space-y-6">
        <Card className="border-amber-200 shadow-sm">
          <CardHeader className="text-center">
            <div className="mx-auto flex h-12 w-12 items-center justify-center rounded-full bg-amber-100 text-amber-800 mb-2">
              <ShieldAlert className="h-6 w-6" />
            </div>
            <CardTitle className="text-xl text-bhoomi-text">Access Restricted</CardTitle>
            <CardDescription>
              403 Forbidden · Role Authorization Boundary
            </CardDescription>
          </CardHeader>

          <CardContent className="space-y-4 text-center">
            <p className="text-sm text-bhoomi-text-secondary">
              Your account does not have permission to access this workspace.
            </p>

            {user && (
              <div className="rounded-lg bg-bhoomi-surface-soft p-3 text-xs text-left border border-bhoomi-border space-y-1">
                <p>
                  <strong className="text-bhoomi-text">User:</strong> {user.name}
                </p>
                <p>
                  <strong className="text-bhoomi-text">Role:</strong>{' '}
                  <span className="capitalize font-medium text-bhoomi-green-800">{user.role}</span>
                </p>
                {user.email && (
                  <p>
                    <strong className="text-bhoomi-text">Email:</strong> {user.email}
                  </p>
                )}
              </div>
            )}
          </CardContent>

          <CardFooter className="flex justify-center">
            <Button variant="primary" onClick={handleReturn} className="gap-2">
              <ArrowLeft className="h-4 w-4" />
              Return to Your Workspace
            </Button>
          </CardFooter>
        </Card>
      </div>
    </div>
  );
}
