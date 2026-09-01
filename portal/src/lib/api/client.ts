import { tokenStorage } from '@/lib/auth/token-storage';
import { ApiErrorEnvelope } from '@/types/api';
import { BhoomiApiError } from './errors';

export interface RequestOptions extends Omit<RequestInit, 'body'> {
  body?: unknown;
  params?: Record<string, string | number | boolean | undefined | null>;
  skipAuth?: boolean;
}

export type UnauthorizedHandler = () => void;

const DEFAULT_BASE_URL = '/api/v1';

export class ApiClient {
  private unauthorizedHandlers: Set<UnauthorizedHandler> = new Set();

  public getBaseUrl(): string {
    const envUrl = import.meta.env?.VITE_API_BASE_URL;
    if (envUrl && typeof envUrl === 'string' && envUrl.trim().length > 0) {
      return envUrl.replace(/\/+$/, '');
    }
    return DEFAULT_BASE_URL;
  }

  public onUnauthorized(handler: UnauthorizedHandler): () => void {
    this.unauthorizedHandlers.add(handler);
    return () => {
      this.unauthorizedHandlers.delete(handler);
    };
  }

  private notifyUnauthorized(): void {
    this.unauthorizedHandlers.forEach((handler) => {
      try {
        handler();
      } catch {
        // Ignore errors in handler
      }
    });
  }

  private buildUrl(
    endpoint: string,
    params?: Record<string, string | number | boolean | undefined | null>
  ): string {
    const base = this.getBaseUrl();
    const cleanEndpoint = endpoint.startsWith('/') ? endpoint : `/${endpoint}`;
    const origin = typeof window !== 'undefined' ? window.location.origin : 'http://localhost';
    const url = new URL(`${base}${cleanEndpoint}`, origin);

    if (params) {
      Object.entries(params).forEach(([key, value]) => {
        if (value !== undefined && value !== null && value !== '') {
          url.searchParams.append(key, String(value));
        }
      });
    }

    return url.pathname + url.search;
  }

  public async request<T>(endpoint: string, options: RequestOptions = {}): Promise<T> {
    const { body, params, headers = {}, skipAuth = false, signal, ...restOptions } = options;

    const requestHeaders: Record<string, string> = {
      Accept: 'application/json',
      ...((headers as Record<string, string>) || {}),
    };

    if (body !== undefined) {
      requestHeaders['Content-Type'] = 'application/json';
    }

    if (!skipAuth) {
      const token = tokenStorage.getToken();
      if (token && token.trim().length > 0) {
        requestHeaders['Authorization'] = `Bearer ${token.trim()}`;
      }
    }

    const url = this.buildUrl(endpoint, params);

    let response: Response;
    try {
      response = await fetch(url, {
        ...restOptions,
        signal,
        headers: requestHeaders,
        body: body !== undefined ? JSON.stringify(body) : undefined,
      });
    } catch (err: unknown) {
      if (err instanceof Error && err.name === 'AbortError') {
        throw err; // Re-throw standard AbortError
      }
      throw BhoomiApiError.fromNetworkError(err);
    }

    if (!response.ok) {
      let errorEnvelope: ApiErrorEnvelope | null = null;
      try {
        const data = await response.json();
        if (data && typeof data === 'object' && 'error' in data) {
          errorEnvelope = data as ApiErrorEnvelope;
        }
      } catch {
        // Non-JSON response
      }

      const apiError = errorEnvelope
        ? BhoomiApiError.fromEnvelope(response.status, errorEnvelope)
        : BhoomiApiError.fromHttpFallback(response.status, response.statusText);

      if (apiError.status === 401) {
        this.notifyUnauthorized();
      }

      throw apiError;
    }

    // 204 No Content
    if (response.status === 204) {
      return {} as T;
    }

    return (await response.json()) as T;
  }

  public get<T>(endpoint: string, options?: Omit<RequestOptions, 'method' | 'body'>): Promise<T> {
    return this.request<T>(endpoint, { ...options, method: 'GET' });
  }

  public post<T>(
    endpoint: string,
    body?: unknown,
    options?: Omit<RequestOptions, 'method' | 'body'>
  ): Promise<T> {
    return this.request<T>(endpoint, { ...options, method: 'POST', body });
  }

  public patch<T>(
    endpoint: string,
    body?: unknown,
    options?: Omit<RequestOptions, 'method' | 'body'>
  ): Promise<T> {
    return this.request<T>(endpoint, { ...options, method: 'PATCH', body });
  }

  public put<T>(
    endpoint: string,
    body?: unknown,
    options?: Omit<RequestOptions, 'method' | 'body'>
  ): Promise<T> {
    return this.request<T>(endpoint, { ...options, method: 'PUT', body });
  }

  public delete<T>(
    endpoint: string,
    options?: Omit<RequestOptions, 'method' | 'body'>
  ): Promise<T> {
    return this.request<T>(endpoint, { ...options, method: 'DELETE' });
  }
}

export const apiClient = new ApiClient();
