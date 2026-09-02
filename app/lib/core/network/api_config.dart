/// Centralized API configuration for Bhoomi.
/// Allows seamless switching between development, local emulator, staging, and demo backends.
class ApiConfig {
  /// Base URL environment override support (via --dart-define=BHOOMI_API_URL=...)
  static const String _envBaseUrl = String.fromEnvironment(
    'BHOOMI_API_URL',
    defaultValue: '',
  );

  /// Default local backend port 8000 with /api/v1 prefix (API_CONTRACT §0)
  static const String defaultLocalHost = 'http://10.0.2.2:8000/api/v1'; // Android emulator localhost alias
  static const String defaultDesktopHost = 'http://localhost:8000/api/v1';

  final String baseUrl;
  final Duration connectTimeout;
  final Duration receiveTimeout;
  final Duration sendTimeout;

  const ApiConfig({
    this.baseUrl = _envBaseUrl != '' ? _envBaseUrl : defaultLocalHost,
    this.connectTimeout = const Duration(seconds: 15),
    this.receiveTimeout = const Duration(seconds: 15),
    this.sendTimeout = const Duration(seconds: 15),
  });

  /// Factory for desktop / unit testing environment
  factory ApiConfig.desktop({String host = defaultDesktopHost}) {
    return ApiConfig(baseUrl: host);
  }

  /// Factory for custom server host
  factory ApiConfig.custom(String customBaseUrl) {
    return ApiConfig(baseUrl: customBaseUrl);
  }
}
