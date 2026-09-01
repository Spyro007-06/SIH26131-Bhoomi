import { UserProfile } from '@/types/api';

const TOKEN_KEY = 'bhoomi_portal_token';
const USER_KEY = 'bhoomi_portal_user';

export const tokenStorage = {
  getToken(): string | null {
    try {
      return localStorage.getItem(TOKEN_KEY);
    } catch {
      return null;
    }
  },

  setToken(token: string): void {
    try {
      localStorage.setItem(TOKEN_KEY, token);
    } catch {
      // Ignore storage errors in restricted contexts
    }
  },

  clearToken(): void {
    try {
      localStorage.removeItem(TOKEN_KEY);
    } catch {
      // Ignore
    }
  },

  getUser(): UserProfile | null {
    try {
      const data = localStorage.getItem(USER_KEY);
      return data ? (JSON.parse(data) as UserProfile) : null;
    } catch {
      return null;
    }
  },

  setUser(user: UserProfile): void {
    try {
      localStorage.setItem(USER_KEY, JSON.stringify(user));
    } catch {
      // Ignore
    }
  },

  clearUser(): void {
    try {
      localStorage.removeItem(USER_KEY);
    } catch {
      // Ignore
    }
  },

  clearAll(): void {
    this.clearToken();
    this.clearUser();
  },
};
