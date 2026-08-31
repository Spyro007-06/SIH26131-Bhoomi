import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bhoomi/core/storage/token_storage.dart';
import 'package:bhoomi/core/storage/secure_storage.dart';
import 'package:bhoomi/models/auth_models.dart';
import 'package:bhoomi/models/farm_models.dart';
import 'package:bhoomi/repositories/auth_repository.dart';
import 'package:bhoomi/repositories/farm_repository.dart';
import 'package:bhoomi/providers/auth_providers.dart';
import 'package:bhoomi/providers/farm_providers.dart';
import 'package:bhoomi/providers/storage_providers.dart';
import 'package:bhoomi/providers/repository_providers.dart';

class MockInMemoryStorage extends SecureStorage {
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
}

class FakeBoundaryAuthRepo extends AuthRepository {
  final TokenStorage tokenStorage;
  bool _isAuthed = true;

  FakeBoundaryAuthRepo({required this.tokenStorage});

  @override
  Future<bool> isAuthenticated() async => _isAuthed;

  @override
  Future<UserModel?> getCurrentUser() async {
    if (!_isAuthed) return null;
    return const UserModel(
      id: 'u_farmer_A',
      phone: '+919876543210',
      role: 'farmer',
    );
  }

  @override
  Future<void> logout() async {
    _isAuthed = false;
    await tokenStorage.clearSession();
  }

  @override
  Future<OtpRequestResponse> requestOtp({required String phone}) => throw UnimplementedError();

  @override
  Future<OtpVerifyResponse> verifyOtp({required String requestId, required String otp}) =>
      throw UnimplementedError();
}

class FakeBoundaryFarmRepo extends FarmRepository {
  @override
  Future<FarmSummaryModel> getFarmSummary(String farmId) async {
    return FarmSummaryModel(
      farm: FarmModel(
        id: farmId,
        crop: 'paddy',
        variety: 'Indrayani',
        growthStage: 'Tillering',
        region: 'Nashik',
      ),
      health: const HealthModel(sentence: 'Crop health stable', trend: 'stable'),
      activeProblemsCount: 1,
      pendingFollowUpsCount: 1,
      activeAlertsCount: 1,
    );
  }

  @override
  Future<FarmModel> createFarm({
    required String crop,
    String? variety,
    required String growthStage,
    required String region,
    required GeoPoint location,
  }) => throw UnimplementedError();

  @override
  Future<FarmModel> getFarm(String farmId) => throw UnimplementedError();

  @override
  Future<FarmModel> updateFarm(String farmId, Map<String, dynamic> updates) =>
      throw UnimplementedError();
}

void main() {
  group('Session Boundary & Data Isolation Tests (Step 6)', () {
    late MockInMemoryStorage mockStorage;
    late TokenStorage tokenStorage;
    late FakeBoundaryAuthRepo fakeAuthRepo;
    late FakeBoundaryFarmRepo fakeFarmRepo;

    setUp(() {
      mockStorage = MockInMemoryStorage();
      tokenStorage = TokenStorage(storage: mockStorage);
      fakeAuthRepo = FakeBoundaryAuthRepo(tokenStorage: tokenStorage);
      fakeFarmRepo = FakeBoundaryFarmRepo();
    });

    test('Logout clears local tokens and purges active farm session', () async {
      final container = ProviderContainer(
        overrides: [
          tokenStorageProvider.overrideWithValue(tokenStorage),
          authRepositoryProvider.overrideWithValue(fakeAuthRepo),
          farmRepositoryProvider.overrideWithValue(fakeFarmRepo),
        ],
      );
      addTearDown(container.dispose);

      // Save initial tokens and active farm for Farmer A
      await tokenStorage.saveTokens(
        accessToken: 'access_farmer_A',
        refreshToken: 'refresh_farmer_A',
      );
      await tokenStorage.saveActiveFarmId('f_farmer_A_01');

      // Initialize notifier and verify Farmer A state
      container.read(activeFarmIdProvider.notifier).setActiveFarmId('f_farmer_A_01');
      await container.read(authStateProvider.notifier).checkAuthStatus();

      expect(container.read(authStateProvider).isAuthenticated, isTrue);
      expect(container.read(authStateProvider).user?.id, 'u_farmer_A');
      expect(container.read(activeFarmIdProvider), 'f_farmer_A_01');

      // Perform local logout
      await container.read(authStateProvider.notifier).logout();

      // Verify session is unauthenticated
      expect(container.read(authStateProvider).isUnauthenticated, isTrue);
      expect(container.read(authStateProvider).user, isNull);

      // Verify tokens and active farm ID are completely purged
      expect(await tokenStorage.getAccessToken(), isNull);
      expect(await tokenStorage.getRefreshToken(), isNull);
      expect(await tokenStorage.getActiveFarmId(), isEmpty);
      expect(container.read(activeFarmIdProvider), isNull);
    });
  });
}
