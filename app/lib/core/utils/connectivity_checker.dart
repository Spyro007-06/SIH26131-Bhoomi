import 'dart:io';

/// Lightweight network connectivity checker.
/// Designed for low-connectivity agricultural field conditions.
class ConnectivityChecker {
  static Future<bool> hasInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 4));
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    } catch (_) {
      return false;
    }
  }
}
