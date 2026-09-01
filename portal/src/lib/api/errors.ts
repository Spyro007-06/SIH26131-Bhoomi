import { ApiErrorDetails, ApiErrorEnvelope } from '@/types/api';
import { ErrorCode } from '@/types/enums';

export class BhoomiApiError extends Error {
  public readonly code: ErrorCode | string;
  public readonly details?: ApiErrorDetails;
  public readonly status: number;
  public readonly isNetwork: boolean;

  constructor(
    status: number,
    code: ErrorCode | string,
    message: string,
    details?: ApiErrorDetails,
    isNetwork = false
  ) {
    super(message);
    this.name = 'BhoomiApiError';
    this.status = status;
    this.code = code;
    this.details = details;
    this.isNetwork = isNetwork;
  }

  static fromEnvelope(status: number, envelope: ApiErrorEnvelope): BhoomiApiError {
    return new BhoomiApiError(
      status,
      envelope.error.code,
      envelope.error.message,
      envelope.error.details
    );
  }

  static fromHttpFallback(status: number, statusText: string): BhoomiApiError {
    const code: ErrorCode | string =
      status === 401
        ? 'UNAUTHENTICATED'
        : status === 403
        ? 'FORBIDDEN'
        : status === 404
        ? 'NOT_FOUND'
        : status === 422
        ? 'VALIDATION_FAILED'
        : `HTTP_${status}`;

    return new BhoomiApiError(
      status,
      code,
      statusText || `Request failed with status ${status}`
    );
  }

  static fromNetworkError(error: unknown): BhoomiApiError {
    const message = error instanceof Error ? error.message : 'Network connection failed';
    return new BhoomiApiError(0, 'NETWORK_ERROR', message, undefined, true);
  }

  public isUnauthorized(): boolean {
    return this.status === 401 || this.code === 'UNAUTHENTICATED';
  }

  public isForbidden(): boolean {
    return this.status === 403 || this.code === 'FORBIDDEN';
  }

  public isNotFound(): boolean {
    return this.status === 404 || this.code === 'NOT_FOUND';
  }

  public isValidationError(): boolean {
    return this.status === 422 || this.code === 'VALIDATION_FAILED';
  }

  public isNetworkError(): boolean {
    return this.isNetwork || this.code === 'NETWORK_ERROR';
  }
}

export function isBhoomiApiError(error: unknown): error is BhoomiApiError {
  return error instanceof BhoomiApiError;
}
