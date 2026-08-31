import 'dart:convert';
import 'secure_storage.dart';

/// Storage manager for authentication tokens and active user session.
/// Enforces security: never stores tokens in plain SharedPreferences and never logs them.
class TokenStorage {
  final SecureStorage _storage;

  static const String _keyAccessToken = 'bhoomi_access_token';
  static const String _keyRefreshToken = 'bhoomi_refresh_token';
  static const String _keyUserData = 'bhoomi_user_data';
  static const String _keyCurrentFarmId = 'bhoomi_active_farm_id';

  TokenStorage({SecureStorage? storage})
      : _storage = storage ?? const SecureStorage();

  /// Save access and refresh tokens securely
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _storage.write(key: _keyAccessToken, value: accessToken);
    await _storage.write(key: _keyRefreshToken, value: refreshToken);
  }

  /// Retrieve the active access token
  Future<String?> getAccessToken() async {
    return await _storage.read(key: _keyAccessToken);
  }

  /// Retrieve the active refresh token
  Future<String?> getRefreshToken() async {
    return await _storage.read(key: _keyRefreshToken);
  }

  /// Store serialized user profile
  Future<void> saveUserData(Map<String, dynamic> userData) async {
    final encoded = jsonEncode(userData);
    await _storage.write(key: _keyUserData, value: encoded);
  }

  /// Retrieve cached user profile
  Future<Map<String, dynamic>?> getUserData() async {
    final raw = await _storage.read(key: _keyUserData);
    if (raw == null || raw.isEmpty) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  /// Store the active farm ID for persistent context (Principle: Farm = Case File)
  Future<void> saveActiveFarmId(String farmId) async {
    await _storage.write(key: _keyCurrentFarmId, value: farmId);
  }

  /// Retrieve active farm ID
  Future<String?> getActiveFarmId() async {
    return await _storage.read(key: _keyCurrentFarmId);
  }

  /// Check if an active session exists
  Future<bool> hasValidSession() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }

  /// Clear all credentials and session data on logout
  Future<void> clearSession() async {
    await _storage.delete(key: _keyAccessToken);
    await _storage.delete(key: _keyRefreshToken);
    await _storage.delete(key: _keyUserData);
    await _storage.delete(key: _keyCurrentFarmId);
  }
}
