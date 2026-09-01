import { useState, useEffect, ReactNode, useCallback } from 'react';
import { useQueryClient } from '@tanstack/react-query';
import { tokenStorage } from '@/lib/auth/token-storage';
import { apiClient } from '@/lib/api/client';
import { LoginRequest, LoginResponse, UserProfile } from '@/types/api';
import { authApi } from './api';
import { AuthContext } from './context';

export function AuthProvider({ children }: { children: ReactNode }) {
  const [user, setUser] = useState<UserProfile | null>(null);
  const [token, setToken] = useState<string | null>(null);
  const [isLoading, setIsLoading] = useState<boolean>(true);

  const queryClient = useQueryClient();

  const logout = useCallback(() => {
    tokenStorage.clearAll();
    setToken(null);
    setUser(null);
    queryClient.clear();
  }, [queryClient]);

  useEffect(() => {
    const storedToken = tokenStorage.getToken();
    const storedUser = tokenStorage.getUser();

    if (storedToken && storedUser) {
      setToken(storedToken);
      setUser(storedUser);
    }
    setIsLoading(false);

    // Register 401 unauthorized listener to trigger automatic auth purge
    const unregister = apiClient.onUnauthorized(() => {
      logout();
    });

    return () => {
      unregister();
    };
  }, [logout]);

  const login = async (credentials: LoginRequest): Promise<LoginResponse> => {
    const response = await authApi.login(credentials);
    tokenStorage.setToken(response.access_token);
    tokenStorage.setUser(response.user);
    setToken(response.access_token);
    setUser(response.user);
    return response;
  };

  const loginDemo = useCallback((role: 'official' | 'agronomist' = 'official'): UserProfile => {
    const demoUser: UserProfile = {
      id: role === 'official' ? 'demo-official-001' : 'demo-agronomist-001',
      role,
      name: role === 'official' ? 'Official Demo Officer' : 'Dr. Suresh Patil (Demo)',
      email: role === 'official' ? 'official.demo@bhoomi.gov.in' : 'spatil.demo@kvk.gov.in',
    };
    const demoToken = `demo_jwt_token_${role}_${Date.now()}`;
    tokenStorage.setToken(demoToken);
    tokenStorage.setUser(demoUser);
    setToken(demoToken);
    setUser(demoUser);
    return demoUser;
  }, []);

  return (
    <AuthContext.Provider
      value={{
        user,
        token,
        isAuthenticated: !!token && !!user,
        isLoading,
        login,
        loginDemo,
        logout,
      }}
    >
      {children}
    </AuthContext.Provider>
  );
}
