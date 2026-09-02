import 'package:flutter_test/flutter_test.dart';
import 'package:bhoomi/core/storage/secure_storage.dart';
import 'package:bhoomi/core/storage/token_storage.dart';

class InMemorySecureStorage extends SecureStorage {
  final Map<String, String> _data = {};

  @override
  Future<void> write({required String key, required String value}) async {
    _data[key] = value;
  }

  @override
  Future<String?> read({required String key}) async {
    return _data[key];
  }

  @override
  Future<void> delete({required String key}) async {
    _data.remove(key);
  }

  @override
  Future<void> deleteAll() async {
    _data.clear();
  }

  @override
  Future<bool> containsKey({required String key}) async {
    return _data.containsKey(key);
  }
}

void main() {
  group('TokenStorage & Session Management Tests', () {
    late TokenStorage tokenStorage;
    late InMemorySecureStorage memoryStorage;

    setUp(() {
      memoryStorage = InMemorySecureStorage();
      tokenStorage = TokenStorage(storage: memoryStorage);
    });

    test('Saves and retrieves access and refresh tokens securely', () async {
      expect(await tokenStorage.hasValidSession(), isFalse);
      expect(await tokenStorage.getAccessToken(), isNull);
      expect(await tokenStorage.getRefreshToken(), isNull);

      await tokenStorage.saveTokens(
        accessToken: 'test_access_jwt_123',
        refreshToken: 'test_refresh_jwt_456',
      );

      expect(await tokenStorage.hasValidSession(), isTrue);
      expect(await tokenStorage.getAccessToken(), 'test_access_jwt_123');
      expect(await tokenStorage.getRefreshToken(), 'test_refresh_jwt_456');
    });

    test('Saves and retrieves user data payload', () async {
      final user = {
        'id': 'u_farmer_99',
        'phone': '+919988776655',
        'role': 'farmer',
      };

      await tokenStorage.saveUserData(user);
      final retrieved = await tokenStorage.getUserData();

      expect(retrieved, isNotNull);
      expect(retrieved?['id'], 'u_farmer_99');
      expect(retrieved?['phone'], '+919988776655');
      expect(retrieved?['role'], 'farmer');
    });

    test('Saves and retrieves active farm ID', () async {
      expect(await tokenStorage.getActiveFarmId(), isNull);

      await tokenStorage.saveActiveFarmId('f_nashik_01');
      expect(await tokenStorage.getActiveFarmId(), 'f_nashik_01');
    });

    test('Clears session completely on logout', () async {
      await tokenStorage.saveTokens(
        accessToken: 'access_abc',
        refreshToken: 'refresh_def',
      );
      await tokenStorage.saveUserData({'id': 'u_1'});
      await tokenStorage.saveActiveFarmId('f_1');

      expect(await tokenStorage.hasValidSession(), isTrue);

      await tokenStorage.clearSession();

      expect(await tokenStorage.hasValidSession(), isFalse);
      expect(await tokenStorage.getAccessToken(), isNull);
      expect(await tokenStorage.getRefreshToken(), isNull);
      expect(await tokenStorage.getUserData(), isNull);
      expect(await tokenStorage.getActiveFarmId(), isNull);
    });
  });
}
