import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bhoomi/core/error/app_exception.dart';
import 'package:bhoomi/core/error/error_handler.dart';

void main() {
  group('ErrorHandler and AppException Mapping Tests', () {
    test('Maps connection timeout to TimeoutException', () {
      final dioError = DioException(
        requestOptions: RequestOptions(path: '/api/v1/farms'),
        type: DioExceptionType.connectionTimeout,
      );

      final result = ErrorHandler.handleDioError(dioError);
      expect(result, isA<TimeoutException>());
      expect(result.code, 'REQUEST_TIMEOUT');
    });

    test('Maps connection error to NetworkException', () {
      final dioError = DioException(
        requestOptions: RequestOptions(path: '/api/v1/farms'),
        type: DioExceptionType.connectionError,
      );

      final result = ErrorHandler.handleDioError(dioError);
      expect(result, isA<NetworkException>());
      expect(result.code, 'NETWORK_UNAVAILABLE');
    });

    test('Maps 401 Unauthorized to UnauthorizedException', () {
      final dioError = DioException(
        requestOptions: RequestOptions(path: '/api/v1/farms'),
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: RequestOptions(path: '/api/v1/farms'),
          statusCode: 401,
          data: {
            'error': {
              'code': 'UNAUTHENTICATED',
              'message': 'Session expired.',
            }
          },
        ),
      );

      final result = ErrorHandler.handleDioError(dioError);
      expect(result, isA<UnauthorizedException>());
      expect(result.code, 'UNAUTHENTICATED');
      expect(result.message, 'Session expired.');
    });

    test('Maps 403 Forbidden to ForbiddenException', () {
      final dioError = DioException(
        requestOptions: RequestOptions(path: '/api/v1/officials'),
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: RequestOptions(path: '/api/v1/officials'),
          statusCode: 403,
          data: {
            'error': {
              'code': 'FORBIDDEN',
              'message': 'Official role required.',
            }
          },
        ),
      );

      final result = ErrorHandler.handleDioError(dioError);
      expect(result, isA<ForbiddenException>());
      expect(result.code, 'FORBIDDEN');
    });

    test('Maps 404 Not Found to NotFoundException', () {
      final dioError = DioException(
        requestOptions: RequestOptions(path: '/api/v1/farms/f_999'),
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: RequestOptions(path: '/api/v1/farms/f_999'),
          statusCode: 404,
          data: {
            'error': {
              'code': 'NOT_FOUND',
              'message': 'Farm f_999 not found.',
            }
          },
        ),
      );

      final result = ErrorHandler.handleDioError(dioError);
      expect(result, isA<NotFoundException>());
      expect(result.code, 'NOT_FOUND');
    });

    test('Maps 422 Validation Error to ValidationException', () {
      final dioError = DioException(
        requestOptions: RequestOptions(path: '/api/v1/farms'),
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: RequestOptions(path: '/api/v1/farms'),
          statusCode: 422,
          data: {
            'error': {
              'code': 'VALIDATION_FAILED',
              'message': 'Geolocation is required at farm creation.',
            }
          },
        ),
      );

      final result = ErrorHandler.handleDioError(dioError);
      expect(result, isA<ValidationException>());
      expect(result.code, 'VALIDATION_FAILED');
    });

    test('Maps 500 Server Error to ServerException', () {
      final dioError = DioException(
        requestOptions: RequestOptions(path: '/api/v1/diagnose'),
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: RequestOptions(path: '/api/v1/diagnose'),
          statusCode: 500,
        ),
      );

      final result = ErrorHandler.handleDioError(dioError);
      expect(result, isA<ServerException>());
      expect(result.code, 'SERVER_ERROR');
    });

    test('Correctly extracts details from API_CONTRACT §0 error envelope', () {
      final dioError = DioException(
        requestOptions: RequestOptions(path: '/api/v1/advisory/query'),
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: RequestOptions(path: '/api/v1/advisory/query'),
          statusCode: 400,
          data: {
            'error': {
              'code': 'NO_RELEVANT_SOURCE',
              'message':
                  'No trusted source covers this. Sending to an expert.',
              'details': {'best_relevance': 0.31, 'threshold': 0.60}
            }
          },
        ),
      );

      final result = ErrorHandler.handleDioError(dioError);
      expect(result, isA<ApiException>());
      expect(result.code, 'NO_RELEVANT_SOURCE');
      expect(result.message,
          'No trusted source covers this. Sending to an expert.');
      expect(result.details, isA<Map>());
      expect(result.details['best_relevance'], 0.31);
    });
  });
}
