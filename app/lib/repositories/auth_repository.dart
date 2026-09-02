import '../core/constants/api_endpoints.dart';
import '../core/network/api_client.dart';
import '../core/storage/token_storage.dart';
import '../models/auth_models.dart';

abstract class AuthRepository {
  Future<OtpRequestResponse> requestOtp({required String phone});
  Future<OtpVerifyResponse> verifyOtp({
    required String requestId,
    required String otp,
  });
  /// Local-only operation: deletes tokens and session data from secure storage.
  /// Does not make an HTTP request (API_CONTRACT has no logout endpoint).
  Future<void> logout();
  Future<bool> isAuthenticated();
  Future<UserModel?> getCurrentUser();
}

class AuthRepositoryImpl implements AuthRepository {
  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;

  AuthRepositoryImpl({
    required ApiClient apiClient,
    required TokenStorage tokenStorage,
  })  : _apiClient = apiClient,
        _tokenStorage = tokenStorage;

  @override
  Future<OtpRequestResponse> requestOtp({required String phone}) async {
    final response = await _apiClient.post(
      ApiEndpoints.authOtpRequest,
      data: {'phone': phone},
    );
    return OtpRequestResponse.fromJson(response as Map<String, dynamic>);
  }

  @override
  Future<OtpVerifyResponse> verifyOtp({
    required String requestId,
    required String otp,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.authOtpVerify,
      data: {
        'request_id': requestId,
        'otp': otp,
      },
    );
    final result = OtpVerifyResponse.fromJson(response as Map<String, dynamic>);
    await _tokenStorage.saveTokens(
      accessToken: result.accessToken,
      refreshToken: result.refreshToken,
    );
    await _tokenStorage.saveUserData(result.user.toJson());
    return result;
  }

  /// Local session clearing only: resets secure tokens, cached user, and active farm context.
  @override
  Future<void> logout() async {
    await _tokenStorage.clearSession();
  }

  @override
  Future<bool> isAuthenticated() async {
    return await _tokenStorage.hasValidSession();
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    final data = await _tokenStorage.getUserData();
    if (data == null) return null;
    return UserModel.fromJson(data);
  }
}
