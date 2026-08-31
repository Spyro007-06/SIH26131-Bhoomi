import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'api_config.dart';
import 'auth_interceptor.dart';
import '../error/error_handler.dart';
import '../storage/token_storage.dart';

/// Central HTTP Client for Bhoomi API communication.
/// Handles request execution, error mapping, timeout configuration, and presigned uploads.
class ApiClient {
  late final Dio _dio;
  late final Dio _uploadDio; // Dedicated Dio instance for raw presigned uploads without API interceptors
  final ApiConfig config;

  ApiClient({
    required this.config,
    required TokenStorage tokenStorage,
    Dio? customDio,
  }) {
    _dio = customDio ??
        Dio(
          BaseOptions(
            baseUrl: config.baseUrl,
            connectTimeout: config.connectTimeout,
            receiveTimeout: config.receiveTimeout,
            sendTimeout: config.sendTimeout,
          ),
        );

    // Attach authentication interceptor if not already present
    if (!_dio.interceptors.any((i) => i is AuthInterceptor)) {
      _dio.interceptors.add(AuthInterceptor(tokenStorage: tokenStorage));
    }

    _uploadDio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 60),
      ),
    );
  }

  /// Exposed internal Dio instance for testing/mocking
  Dio get dio => _dio;

  /// HTTP GET request
  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.get(
        path,
        queryParameters: queryParameters,
        options: options,
      );
      return response.data;
    } on DioException catch (e) {
      throw ErrorHandler.handleDioError(e);
    } catch (e) {
      throw ErrorHandler.handleGenericError(e);
    }
  }

  /// HTTP POST request
  Future<dynamic> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response.data;
    } on DioException catch (e) {
      throw ErrorHandler.handleDioError(e);
    } catch (e) {
      throw ErrorHandler.handleGenericError(e);
    }
  }

  /// HTTP PATCH request
  Future<dynamic> patch(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.patch(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response.data;
    } on DioException catch (e) {
      throw ErrorHandler.handleDioError(e);
    } catch (e) {
      throw ErrorHandler.handleGenericError(e);
    }
  }

  /// HTTP PUT request
  Future<dynamic> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response.data;
    } on DioException catch (e) {
      throw ErrorHandler.handleDioError(e);
    } catch (e) {
      throw ErrorHandler.handleGenericError(e);
    }
  }

  /// HTTP DELETE request
  Future<dynamic> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.delete(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response.data;
    } on DioException catch (e) {
      throw ErrorHandler.handleDioError(e);
    } catch (e) {
      throw ErrorHandler.handleGenericError(e);
    }
  }

  /// Direct binary PUT upload for presigned media URLs (S3 / MinIO).
  /// Sends raw bytes with exact content-type directly to upload_url without bearer auth.
  Future<void> uploadBinary({
    required String uploadUrl,
    required Uint8List bytes,
    required String contentType,
    ProgressCallback? onProgress,
  }) async {
    try {
      await _uploadDio.put(
        uploadUrl,
        data: Stream.fromIterable([bytes]),
        options: Options(
          headers: {
            'Content-Type': contentType,
            'Content-Length': bytes.length,
          },
        ),
        onSendProgress: onProgress,
      );
    } on DioException catch (e) {
      throw ErrorHandler.handleDioError(e);
    } catch (e) {
      throw ErrorHandler.handleGenericError(e);
    }
  }
}
