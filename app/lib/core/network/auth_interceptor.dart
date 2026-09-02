import 'package:dio/dio.dart';
import '../storage/token_storage.dart';
import '../constants/api_endpoints.dart';

/// Dio interceptor that injects Bearer JWT authentication tokens for protected endpoints.
/// Skips authentication on public onboarding/auth endpoints.
class AuthInterceptor extends Interceptor {
  final TokenStorage _tokenStorage;

  AuthInterceptor({required TokenStorage tokenStorage})
      : _tokenStorage = tokenStorage;

  static const List<String> _publicEndpoints = [
    ApiEndpoints.authOtpRequest,
    ApiEndpoints.authOtpVerify,
    ApiEndpoints.health,
  ];

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final path = options.path;

    // Check if endpoint is public
    final isPublic = _publicEndpoints.any((endpoint) => path.endsWith(endpoint));

    if (!isPublic) {
      final token = await _tokenStorage.getAccessToken();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }

    // Always set JSON content headers for standard API calls
    options.headers['Accept'] = 'application/json';
    if (options.data != null && options.headers['Content-Type'] == null) {
      options.headers['Content-Type'] = 'application/json';
    }

    return handler.next(options);
  }
}
