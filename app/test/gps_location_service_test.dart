import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
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

/// Controllable mock wrapper for Geolocator native calls.
class MockGeolocatorWrapper implements GeolocatorWrapper {
  bool serviceEnabled = true;
  LocationPermission currentPermission = LocationPermission.whileInUse;
  LocationPermission requestedPermissionResult = LocationPermission.whileInUse;
  Position? positionToReturn;
  Exception? exceptionToThrow;
  bool appSettingsOpened = false;
  bool locationSettingsOpened = false;
  int requestPermissionCallCount = 0;

  @override
  Future<bool> isLocationServiceEnabled() async => serviceEnabled;

  @override
  Future<LocationPermission> checkPermission() async => currentPermission;

  @override
  Future<LocationPermission> requestPermission() async {
    requestPermissionCallCount++;
    currentPermission = requestedPermissionResult;
    return requestedPermissionResult;
  }

  @override
  Future<Position> getCurrentPosition({
    LocationAccuracy desiredAccuracy = LocationAccuracy.medium,
    Duration? timeLimit,
  }) async {
    if (exceptionToThrow != null) {
      throw exceptionToThrow!;
    }
    return positionToReturn ??
        Position(
          latitude: 18.5204,
          longitude: 73.8567, // Pune Coordinates (different from Nashik mock)
          timestamp: DateTime.now(),
          accuracy: 10.0,
          altitude: 560.0,
          altitudeAccuracy: 5.0,
          heading: 0.0,
          headingAccuracy: 0.0,
          speed: 0.0,
          speedAccuracy: 0.0,
        );
  }

  @override
  Future<bool> openAppSettings() async {
    appSettingsOpened = true;
    return true;
  }

  @override
  Future<bool> openLocationSettings() async {
    locationSettingsOpened = true;
    return true;
  }
}

void main() {
  group('Real Device GPS LocationService Unit Tests', () {
    late MockGeolocatorWrapper mockGeolocator;
    late LocationService locationService;

    setUp(() {
      mockGeolocator = MockGeolocatorWrapper();
      locationService = LocationService(geolocatorWrapper: mockGeolocator);
    });

    test('Acquires real device coordinates when GPS and permissions are enabled', () async {
      mockGeolocator.positionToReturn = Position(
        latitude: 19.8765,
        longitude: 73.1234,
        timestamp: DateTime.now(),
        accuracy: 8.0,
        altitude: 600.0,
        altitudeAccuracy: 2.0,
        heading: 0.0,
        headingAccuracy: 0.0,
        speed: 0.0,
        speedAccuracy: 0.0,
      );

      final result = await locationService.getCurrentLocation();
      expect(result.isSuccess, isTrue);
      expect(result.status, LocationServiceStatus.acquired);
      expect(result.location?.lat, 19.8765);
      expect(result.location?.lng, 73.1234);
    });

    test('Returns disabled status when device location services (GPS) are off', () async {
      mockGeolocator.serviceEnabled = false;

      final result = await locationService.getCurrentLocation();
      expect(result.isSuccess, isFalse);
      expect(result.status, LocationServiceStatus.disabled);
      expect(result.isDisabled, isTrue);
      expect(result.errorMessage, contains('Location services are disabled'));
    });

    test('Requests permission when initially denied and returns coordinates if granted', () async {
      mockGeolocator.currentPermission = LocationPermission.denied;
      mockGeolocator.requestedPermissionResult = LocationPermission.whileInUse;

      final result = await locationService.getCurrentLocation();
      expect(mockGeolocator.requestPermissionCallCount, 1);
      expect(result.isSuccess, isTrue);
      expect(result.status, LocationServiceStatus.acquired);
      expect(result.location?.lat, 18.5204);
    });

    test('Returns denied status when user rejects location permission', () async {
      mockGeolocator.currentPermission = LocationPermission.denied;
      mockGeolocator.requestedPermissionResult = LocationPermission.denied;

      final result = await locationService.getCurrentLocation();
      expect(result.isSuccess, isFalse);
      expect(result.status, LocationServiceStatus.denied);
      expect(result.isDenied, isTrue);
      expect(result.isDeniedForever, isFalse);
    });

    test('Returns deniedForever status when location permission is permanently denied', () async {
      mockGeolocator.currentPermission = LocationPermission.deniedForever;

      final result = await locationService.getCurrentLocation();
      expect(result.isSuccess, isFalse);
      expect(result.status, LocationServiceStatus.deniedForever);
      expect(result.isDeniedForever, isTrue);
      expect(result.isDenied, isTrue);
    });

    test('Handles timeout when GPS satellite acquisition exceeds duration limit', () async {
      mockGeolocator.exceptionToThrow = TimeoutException('GPS signal search timed out');

      final result = await locationService.getCurrentLocation();
      expect(result.isSuccess, isFalse);
      expect(result.status, LocationServiceStatus.timeout);
      expect(result.isTimeout, isTrue);
      expect(result.errorMessage, contains('timed out'));
    });

    test('Handles unexpected platform exceptions and maps to error status', () async {
      mockGeolocator.exceptionToThrow = Exception('Hardware sensor unavailable');

      final result = await locationService.getCurrentLocation();
      expect(result.isSuccess, isFalse);
      expect(result.status, LocationServiceStatus.error);
      expect(result.errorMessage, contains('Hardware sensor unavailable'));
    });

    test('Delegates openAppSettings and openLocationSettings to wrapper', () async {
      await locationService.openAppSettings();
      expect(mockGeolocator.appSettingsOpened, isTrue);

      await locationService.openLocationSettings();
      expect(mockGeolocator.locationSettingsOpened, isTrue);
    });
  });

  group('FarmSetupScreen GPS UI Integration Tests', () {
    late MockInMemoryStorage memoryStorage;
    late TokenStorage tokenStorage;
    late FakeFarmRepo fakeFarmRepo;
    late MockGeolocatorWrapper mockGeolocator;

    setUp(() {
      memoryStorage = MockInMemoryStorage();
      tokenStorage = TokenStorage(storage: memoryStorage);
      fakeFarmRepo = FakeFarmRepo();
      mockGeolocator = MockGeolocatorWrapper();
    });

    testWidgets('Acquires real device coordinates and displays them in FarmSetupScreen',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      mockGeolocator.positionToReturn = Position(
        latitude: 19.8765,
        longitude: 73.1234,
        timestamp: DateTime.now(),
        accuracy: 5.0,
        altitude: 500.0,
        altitudeAccuracy: 1.0,
        heading: 0.0,
        headingAccuracy: 0.0,
        speed: 0.0,
        speedAccuracy: 0.0,
      );

      final realLocationService = LocationService(geolocatorWrapper: mockGeolocator);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            farmRepositoryProvider.overrideWithValue(fakeFarmRepo),
            tokenStorageProvider.overrideWithValue(tokenStorage),
          ],
          child: BhoomiApp(
            homeOverride: FarmSetupScreen(
              locationService: realLocationService,
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

    testWidgets('Handles denied location permission and provides retry option',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      mockGeolocator.currentPermission = LocationPermission.denied;
      mockGeolocator.requestedPermissionResult = LocationPermission.denied;

      final realLocationService = LocationService(geolocatorWrapper: mockGeolocator);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            farmRepositoryProvider.overrideWithValue(fakeFarmRepo),
            tokenStorageProvider.overrideWithValue(tokenStorage),
          ],
          child: BhoomiApp(
            homeOverride: FarmSetupScreen(
              locationService: realLocationService,
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

    testWidgets('Handles permanently denied permission and shows settings recovery button',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      mockGeolocator.currentPermission = LocationPermission.deniedForever;

      final realLocationService = LocationService(geolocatorWrapper: mockGeolocator);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            farmRepositoryProvider.overrideWithValue(fakeFarmRepo),
            tokenStorageProvider.overrideWithValue(tokenStorage),
          ],
          child: BhoomiApp(
            homeOverride: FarmSetupScreen(
              locationService: realLocationService,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify permanently denied message and Open Settings button
      expect(find.text('स्थान परवानगी कायमची नाकारली आहे. कृपया ॲप सेटिंग्जमधून परवानगी द्या.'), findsOneWidget);
      expect(find.text('सेटिंग्ज उघडा'), findsOneWidget);

      // Tap settings button and verify service calls wrapper
      await tester.tap(find.text('सेटिंग्ज उघडा'));
      await tester.pumpAndSettle();
      expect(mockGeolocator.appSettingsOpened, isTrue);
    });

    testWidgets('Handles disabled location services and shows enable settings button',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      mockGeolocator.serviceEnabled = false;

      final realLocationService = LocationService(geolocatorWrapper: mockGeolocator);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            farmRepositoryProvider.overrideWithValue(fakeFarmRepo),
            tokenStorageProvider.overrideWithValue(tokenStorage),
          ],
          child: BhoomiApp(
            homeOverride: FarmSetupScreen(
              locationService: realLocationService,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify disabled GPS message and Open Settings button
      expect(find.text('फोनचे GPS / स्थान बंद आहे. कृपया डिव्हाइस सेटिंग्जमधून लोकेशन चालू करा.'), findsOneWidget);
      expect(find.text('सेटिंग्ज उघडा'), findsOneWidget);

      // Tap settings button and verify service calls location settings
      await tester.tap(find.text('सेटिंग्ज उघडा'));
      await tester.pumpAndSettle();
      expect(mockGeolocator.locationSettingsOpened, isTrue);
    });
  });
}
