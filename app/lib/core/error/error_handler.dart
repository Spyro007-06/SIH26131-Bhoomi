import 'dart:io';
import 'package:dio/dio.dart';
import 'app_exception.dart';

/// Centralized error transformer that converts raw DioExceptions and network errors
/// into domain-level AppExceptions.
abstract final class ErrorHandler {
  static AppException handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const TimeoutException();

      case DioExceptionType.connectionError:
        return const NetworkException();

      case DioExceptionType.badResponse:
        final response = error.response;
        if (response == null) {
          return const ServerException();
        }

        final statusCode = response.statusCode ?? 500;
        final data = response.data;

        // Parse backend error envelope: { "error": { "code": "...", "message": "...", "details": ... } }
        String? backendCode;
        String? backendMessage;
        dynamic backendDetails;

        if (data is Map<String, dynamic>) {
          if (data.containsKey('error') && data['error'] is Map<String, dynamic>) {
            final errMap = data['error'] as Map<String, dynamic>;
            backendCode = errMap['code'] as String?;
            backendMessage = errMap['message'] as String?;
            backendDetails = errMap['details'];
          } else {
            backendMessage = data['message'] as String? ?? data['detail'] as String?;
          }
        }

        switch (statusCode) {
          case 400:
            return ApiException(
              message: backendMessage ?? 'Bad request. Please verify your input.',
              code: backendCode ?? 'BAD_REQUEST',
              statusCode: 400,
              details: backendDetails,
            );
          case 401:
            return UnauthorizedException(
              message: backendMessage ?? 'Session expired. Please log in again.',
              code: backendCode ?? 'UNAUTHENTICATED',
              details: backendDetails,
            );
          case 403:
            return ForbiddenException(
              message: backendMessage ?? 'Access forbidden.',
              code: backendCode ?? 'FORBIDDEN',
              details: backendDetails,
            );
          case 404:
            return NotFoundException(
              message: backendMessage ?? 'Requested item not found.',
              code: backendCode ?? 'NOT_FOUND',
              details: backendDetails,
            );
          case 409:
            return ConflictException(
              message: backendMessage ?? 'A conflict occurred with the existing data.',
              code: backendCode ?? 'CONFLICT',
              details: backendDetails,
            );
          case 422:
            return ValidationException(
              message: backendMessage ?? 'Validation failed for the submitted data.',
              code: backendCode ?? 'VALIDATION_FAILED',
              details: backendDetails,
            );
          case 500:
          case 502:
          case 503:
          case 504:
            return ServerException(
              message: backendMessage ?? 'The server encountered an error. Please try again later.',
              code: backendCode ?? 'SERVER_ERROR',
              details: backendDetails,
            );
          default:
            return ApiException(
              message: backendMessage ?? 'An unexpected error occurred ($statusCode).',
              code: backendCode ?? 'HTTP_$statusCode',
              statusCode: statusCode,
              details: backendDetails,
            );
        }

      case DioExceptionType.cancel:
        return const ApiException(
          message: 'Request was cancelled.',
          code: 'REQUEST_CANCELLED',
        );

      case DioExceptionType.badCertificate:
        return const ApiException(
          message: 'Secure connection error (certificate invalid).',
          code: 'BAD_CERTIFICATE',
        );

      case DioExceptionType.unknown:
      default:
        if (error.error is SocketException) {
          return const NetworkException();
        }
        return ApiException(
          message: error.message ?? 'An unknown network error occurred.',
          code: 'UNKNOWN_NETWORK_ERROR',
        );
    }
  }

  /// Wraps any error into an AppException
  static AppException handleGenericError(Object error) {
    if (error is AppException) {
      return error;
    }
    if (error is DioException) {
      return handleDioError(error);
    }
    if (error is SocketException) {
      return const NetworkException();
    }
    return ApiException(
      message: error.toString(),
      code: 'UNEXPECTED_ERROR',
    );
  }
}
