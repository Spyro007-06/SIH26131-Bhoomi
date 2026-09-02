import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bhoomi/main.dart';
import 'package:bhoomi/core/storage/token_storage.dart';
import 'package:bhoomi/core/storage/secure_storage.dart';
import 'package:bhoomi/core/network/api_client.dart';
import 'package:bhoomi/core/network/api_config.dart';
import 'package:bhoomi/repositories/farm_repository.dart';
import 'package:bhoomi/providers/repository_providers.dart';
import 'package:bhoomi/providers/storage_providers.dart';
import 'package:bhoomi/features/onboarding/presentation/farm_setup_screen.dart';
import 'package:bhoomi/core/utils/location_service.dart';
import 'package:bhoomi/models/farm_models.dart';

class FakeLocationService extends LocationService {
  @override
  Future<LocationResult> getCurrentLocation({Duration timeout = const Duration(seconds: 10)}) async {
    return const LocationResult(
      location: GeoPoint(lat: 19.8765, lng: 73.1234),
      status: LocationServiceStatus.acquired,
    );
  }
}

class MockInMemoryStorage extends SecureStorage {
  final Map<String, String> _map = {};
  @override
  Future<void> write({required String key, required String value}) async => _map[key] = value;
  @override
  Future<String?> read({required String key}) async => _map[key];
  @override
  Future<void> delete({required String key}) async => _map.remove(key);
}

class FakeFarmApiClient extends ApiClient {
  FakeFarmApiClient({required TokenStorage tokenStorage})
      : super(config: const ApiConfig(), tokenStorage: tokenStorage);

  @override
  Future<dynamic> post(String path, {dynamic data, Map<String, dynamic>? queryParameters, dynamic options}) async {
    if (path == '/farms') {
      return {
        'id': 'f_new_101',
        'crop': data['crop'],
        'variety': data['variety'],
        'growth_stage': data['growth_stage'],
        'region': data['region'],
        'location': data['location'],
      };
    }
    return {};
  }
}

void main() {
  group('Farm Setup and Memory Routing Tests (Step 3)', () {
    late MockInMemoryStorage memoryStorage;
    late TokenStorage tokenStorage;
    late FakeFarmApiClient fakeClient;
    late FarmRepository farmRepository;

    setUp(() {
      memoryStorage = MockInMemoryStorage();
      tokenStorage = TokenStorage(storage: memoryStorage);
      fakeClient = FakeFarmApiClient(tokenStorage: tokenStorage);
      farmRepository = FarmRepositoryImpl(apiClient: fakeClient);
    });

    testWidgets('FarmSetupScreen renders all contract fields and saves farm profile',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            farmRepositoryProvider.overrideWithValue(farmRepository),
            tokenStorageProvider.overrideWithValue(tokenStorage),
          ],
          child: BhoomiApp(
            homeOverride: FarmSetupScreen(
              locationService: FakeLocationService(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify contract fields
      expect(find.text('शेताची माहिती नोंदवा'), findsOneWidget);
      expect(find.text('भात / धान (Paddy)'), findsOneWidget);
      expect(find.text('वाण / प्रकार (Variety)'), findsOneWidget);
      expect(find.text('पिकाची अवस्था (Growth Stage)'), findsOneWidget);
      expect(find.text('जिल्हा / तालुका (Region)'), findsOneWidget);
      expect(find.text('शेताचे स्थान (GPS Location)'), findsOneWidget);

      // Tap Save Farm Profile
      await tester.tap(find.text('शेत जतन करा'));
      await tester.pumpAndSettle();

      // Verify active farm ID is stored
      expect(await tokenStorage.getActiveFarmId(), 'f_new_101');
    });
  });
}
