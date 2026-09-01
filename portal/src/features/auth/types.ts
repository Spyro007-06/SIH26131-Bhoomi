import { LoginRequest, LoginResponse, UserProfile } from '@/types/api';

export type { LoginRequest, LoginResponse, UserProfile };

export interface AuthState {
  user: UserProfile | null;
  token: string | null;
  isAuthenticated: boolean;
  isLoading: boolean;
}

export interface AuthContextType extends AuthState {
  login: (credentials: LoginRequest) => Promise<LoginResponse>;
  logout: () => void;
}
