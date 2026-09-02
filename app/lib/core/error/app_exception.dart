/// Normalized application and API exceptions for Bhoomi.
/// Designed to provide calm, clear messages to farmers without exposing stack traces.
sealed class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic details;

  const AppException({
    required this.message,
    this.code,
    this.details,
  });

  @override
  String toString() => '$runtimeType: $message ${code != null ? "($code)" : ""}';
}

/// Network is completely unavailable or device is offline
class NetworkException extends AppException {
  const NetworkException({
    super.message = 'No internet connection. Please check your mobile data or Wi-Fi.',
    super.code = 'NETWORK_UNAVAILABLE',
    super.details,
  });
}

/// Request timed out in field conditions
class TimeoutException extends AppException {
  const TimeoutException({
    super.message = 'The server is taking too long to respond. Please try again.',
    super.code = 'REQUEST_TIMEOUT',
    super.details,
  });
}

/// Unauthenticated access (401)
class UnauthorizedException extends AppException {
  const UnauthorizedException({
    super.message = 'Session expired. Please log in again.',
    super.code = 'UNAUTHENTICATED',
    super.details,
  });
}

/// Forbidden access (403)
class ForbiddenException extends AppException {
  const ForbiddenException({
    super.message = 'You do not have permission to perform this action.',
    super.code = 'FORBIDDEN',
    super.details,
  });
}

/// Resource not found (404)
class NotFoundException extends AppException {
  const NotFoundException({
    super.message = 'The requested resource was not found.',
    super.code = 'NOT_FOUND',
    super.details,
  });
}

/// Conflict / State violation (409)
class ConflictException extends AppException {
  const ConflictException({
    super.message = 'A conflict occurred with the current state.',
    super.code = 'CONFLICT',
    super.details,
  });
}

/// Validation / Unprocessable Entity (422)
class ValidationException extends AppException {
  const ValidationException({
    super.message = 'Invalid information provided. Please check the entered data.',
    super.code = 'VALIDATION_FAILED',
    super.details,
  });
}

/// Internal Server Error (500)
class ServerException extends AppException {
  const ServerException({
    super.message = 'The agronomist server encountered an issue. Please try again shortly.',
    super.code = 'SERVER_ERROR',
    super.details,
  });
}

/// Presigned upload to storage failed
class PresignedUploadException extends AppException {
  const PresignedUploadException({
    super.message = 'Failed to upload photograph. Please check your connection and retry.',
    super.code = 'PRESIGNED_UPLOAD_FAILED',
    super.details,
  });
}

/// Device GPS or Location service exception
class LocationException extends AppException {
  const LocationException({
    super.message = 'Unable to acquire GPS location. Please ensure location services and permissions are enabled.',
    super.code = 'LOCATION_ERROR',
    super.details,
  });
}

/// Device Camera or Image capture exception
class CameraServiceException extends AppException {
  const CameraServiceException({
    super.message = 'Unable to capture photograph. Please ensure camera permissions are enabled.',
    super.code = 'CAMERA_ERROR',
    super.details,
  });
}

/// Device Microphone or Audio recording/playback exception
class AudioServiceException extends AppException {
  const AudioServiceException({
    super.message = 'Unable to record or play audio. Please ensure microphone permissions are enabled.',
    super.code = 'AUDIO_ERROR',
    super.details,
  });
}

/// Generic API error containing structured error envelope from backend (API_CONTRACT §0)
class ApiException extends AppException {
  final int? statusCode;

  const ApiException({
    required super.message,
    super.code,
    this.statusCode,
    super.details,
  });
}
