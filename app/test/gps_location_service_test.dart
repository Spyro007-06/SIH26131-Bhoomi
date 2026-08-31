import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bhoomi/main.dart';
import 'package:bhoomi/models/farm_models.dart';
import 'package:bhoomi/core/utils/location_service.dart';
import 'package:bhoomi/core/storage/token_storage.dart';
import 'package:bhoomi/core/storage/secure_storage.dart';
import 'package:bhoomi/repositories/farm_repository.dart';
import 'package:bhoomi/providers/repository_providers.dart';
import 'package:bhoomi/providers/storage_providers.dart';
import 'package:bhoomi/features/onboarding/presentation/farm_setup_screen.dart';
import 'package:bhoomi/widgets/app_button.dart';

class MockInMemoryStorage extends SecureStorage {
  final Map<String, String> _map = {};
  @override
  Future<void> write({required String key, required String value}) async => _map[key] = value;
  @override
  Future<String?> read({required String key}) async => _map[key];
  @override
  Future<void> delete({required String key}) async => _map.remove(key);
}

class FakeSuccessLocationService extends LocationService {
  @override
  Future<LocationResult> getCurrentLocation({Duration timeout = const Duration(seconds: 8)}) async {
    return const LocationResult(
      location: GeoPoint(lat: 19.8765, lng: 73.1234),
      status: LocationServiceStatus.acquired,
    );
  }
}

class FakeDeniedLocationService extends LocationService {
  @override
  Future<LocationResult> getCurrentLocation({Duration timeout = const Duration(seconds: 8)}) async {
    return const LocationResult(
      location: null,
      status: LocationServiceStatus.denied,
      errorMessage: 'Location permission denied by user',
    );
  }
}

class FakeFarmRepo extends FarmRepository {
  FarmModel? lastCreatedFarm;

  @override
  Future<FarmModel> createFarm({
    required String crop,
    String? variety,
    required String growthStage,
    required String region,
    required GeoPoint location,
  }) async {
    lastCreatedFarm = FarmModel(
      id: 'f_gps_123',
      crop: crop,
      variety: variety,
      growthStage: growthStage,
      region: region,
      location: location,
    );
    return lastCreatedFarm!;
  }

  @override
  Future<FarmModel> getFarm(String farmId) async => lastCreatedFarm!;

  @override
  Future<FarmSummaryModel> getFarmSummary(String farmId) async => throw UnimplementedError();

  @override
  Future<FarmModel> updateFarm(String farmId, Map<String, dynamic> updates) async => throw UnimplementedError();
}

void main() {
  group('GPS Location Acquisition & Farm Setup Tests (Step 4)', () {
    late MockInMemoryStorage memoryStorage;
    late TokenStorage tokenStorage;
    late FakeFarmRepo fakeFarmRepo;

    setUp(() {
      memoryStorage = MockInMemoryStorage();
      tokenStorage = TokenStorage(storage: memoryStorage);
      fakeFarmRepo = FakeFarmRepo();
    });

    testWidgets('Acquires real device coordinates and displays them in FarmSetupScreen',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            farmRepositoryProvider.overrideWithValue(fakeFarmRepo),
            tokenStorageProvider.overrideWithValue(tokenStorage),
          ],
          child: BhoomiApp(
            homeOverride: FarmSetupScreen(
              locationService: FakeSuccessLocationService(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify acquired location coordinates are rendered
      expect(find.textContaining('स्थान निश्चित केले: Lat 19.8765, Lng 73.1234'), findsOneWidget);

      // Save Farm button is enabled
      final saveBtn = tester.widget<AppButton>(find.byType(AppButton));
      expect(saveBtn.onPressed, isNotNull);

      // Tap Save Farm
      await tester.tap(find.text('शेत जतन करा'));
      await tester.pumpAndSettle();

      // Verify real GPS location was passed to backend repository
      expect(fakeFarmRepo.lastCreatedFarm?.location?.lat, 19.8765);
      expect(fakeFarmRepo.lastCreatedFarm?.location?.lng, 73.1234);
      expect(await tokenStorage.getActiveFarmId(), 'f_gps_123');
    });

    testWidgets('Handles denied location permission and blocks farm creation',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            farmRepositoryProvider.overrideWithValue(fakeFarmRepo),
            tokenStorageProvider.overrideWithValue(tokenStorage),
          ],
          child: BhoomiApp(
            homeOverride: FarmSetupScreen(
              locationService: FakeDeniedLocationService(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify warning and retry option are rendered
      expect(find.text('शेताच्या हवामान अलर्ट आणि रोगांच्या अचूक निदानासाठी GPS स्थान आवश्यक आहे.'), findsOneWidget);
      expect(find.text('स्थान पुन्हा शोधा'), findsOneWidget);

      // Save Farm button is disabled without location
      final saveBtn = tester.widget<AppButton>(find.byType(AppButton));
      expect(saveBtn.onPressed, isNull);
    });
  });
}
