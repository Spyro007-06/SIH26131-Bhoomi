import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bhoomi/main.dart';
import 'package:bhoomi/core/storage/token_storage.dart';
import 'package:bhoomi/core/storage/secure_storage.dart';
import 'package:bhoomi/core/network/api_client.dart';
import 'package:bhoomi/core/network/api_config.dart';
import 'package:bhoomi/repositories/auth_repository.dart';
import 'package:bhoomi/repositories/farm_repository.dart';
import 'package:bhoomi/repositories/alert_repository.dart';
import 'package:bhoomi/repositories/followup_repository.dart';
import 'package:bhoomi/repositories/timeline_repository.dart';
import 'package:bhoomi/repositories/referral_repository.dart';
import 'package:bhoomi/providers/repository_providers.dart';
import 'package:bhoomi/providers/farm_providers.dart';
import 'package:bhoomi/models/farm_models.dart';
import 'package:bhoomi/models/alert_models.dart';
import 'package:bhoomi/models/followup_models.dart';
import 'package:bhoomi/models/timeline_models.dart';
import 'package:bhoomi/models/referral_models.dart';
import 'package:bhoomi/features/more/presentation/more_screen.dart';
import 'package:bhoomi/features/onboarding/presentation/phone_auth_screen.dart';

class MockSecureStorage extends SecureStorage {
  final Map<String, String> _map = {};
  @override
  Future<void> write({required String key, required String value}) async => _map[key] = value;
  @override
  Future<String?> read({required String key}) async => _map[key];
  @override
  Future<void> delete({required String key}) async => _map.remove(key);
}

class CountingApiClient extends ApiClient {
  int totalRequests = 0;
  CountingApiClient({required TokenStorage tokenStorage})
      : super(config: const ApiConfig(), tokenStorage: tokenStorage);

  @override
  Future<dynamic> post(String path, {dynamic data, Map<String, dynamic>? queryParameters, dynamic options}) async {
    totalRequests++;
    return {};
  }
}

class FakeShellFarmRepo extends FarmRepository {
  @override
  Future<FarmSummaryModel> getFarmSummary(String farmId) async {
    return const FarmSummaryModel(
      farm: FarmModel(
        id: 'f_shell_01',
        crop: 'paddy',
        variety: 'Indrayani',
        growthStage: 'Tillering',
        region: 'Nashik',
      ),
      health: HealthModel(sentence: 'Field health is stable.', trend: 'stable'),
      activeProblemsCount: 0,
      pendingFollowUpsCount: 0,
      activeAlertsCount: 0,
    );
  }

  @override
  Future<FarmModel> createFarm({required String crop, String? variety, required String growthStage, required String region, required GeoPoint location}) =>
      throw UnimplementedError();

  @override
  Future<FarmModel> getFarm(String farmId) => throw UnimplementedError();

  @override
  Future<FarmModel> updateFarm(String farmId, Map<String, dynamic> updates) => throw UnimplementedError();
}

class FakeShellAlertRepo extends AlertRepository {
  @override
  Future<AlertsResponse> getAlerts({required String farmId, int limit = 20, String? cursor}) async {
    return const AlertsResponse(alerts: []);
  }

  @override
  Future<AlertRespondResponse> respondToAlert({required String alertId, required String outcome, String? imageAssetId}) async {
    return const AlertRespondResponse(status: 'recorded', alertId: 'alt_1', recordedAt: '2026-08-31');
  }
}

class FakeShellFollowUpRepo extends FollowUpRepository {
  @override
  Future<PendingFollowUpsResponse> getPendingFollowUps(String farmId) async {
    return const PendingFollowUpsResponse(followUps: []);
  }

  @override
  Future<FollowUpResultModel> respondToFollowUp({required String followUpId, required String response, String? imageAssetId}) async {
    return const FollowUpResultModel(status: 'success');
  }
}

class FakeShellTimelineRepo extends TimelineRepository {
  @override
  Future<TimelineResponse> getTimeline({required String farmId, int limit = 20, String? cursor}) async {
    return const TimelineResponse(events: []);
  }
}

class FakeShellReferralRepo extends ReferralRepository {
  @override
  Future<ReferralsResponse> getReferrals(String farmId) async {
    return ReferralsResponse(referrals: []);
  }
}

List<Override> _getShellOverrides() {
  return [
    activeFarmIdProvider.overrideWith((ref) => ActiveFarmIdNotifier(null, 'f_shell_01')),
    farmRepositoryProvider.overrideWithValue(FakeShellFarmRepo()),
    alertRepositoryProvider.overrideWithValue(FakeShellAlertRepo()),
    followUpRepositoryProvider.overrideWithValue(FakeShellFollowUpRepo()),
    timelineRepositoryProvider.overrideWithValue(FakeShellTimelineRepo()),
    referralRepositoryProvider.overrideWithValue(FakeShellReferralRepo()),
  ];
}

void main() {
  group('Logout and Language Selection Tests (Step 3)', () {
    late MockSecureStorage memoryStorage;
    late TokenStorage tokenStorage;
    late CountingApiClient countingClient;
    late AuthRepository authRepository;

    setUp(() {
      memoryStorage = MockSecureStorage();
      tokenStorage = TokenStorage(storage: memoryStorage);
      countingClient = CountingApiClient(tokenStorage: tokenStorage);
      authRepository = AuthRepositoryImpl(
        apiClient: countingClient,
        tokenStorage: tokenStorage,
      );
    });

    testWidgets('Language selection dialog dynamically switches app language',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(authRepository),
            ..._getShellOverrides(),
          ],
          child: const BhoomiApp(homeOverride: MoreScreen()),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Open Language Dialog
      await tester.tap(find.text('भाषा बदला (Change Language)'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Select Hindi
      expect(find.text('हिंदी'), findsOneWidget);
      await tester.tap(find.text('हिंदी'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verify UI updated to Hindi
      expect(find.text('किसान प्रोफ़ाइल'), findsOneWidget);
      expect(find.text('भाषा बदलें (Change Language)'), findsOneWidget);
      expect(find.text('लॉग आउट करें (Log Out)'), findsOneWidget);
    });

    testWidgets('Logout confirms and clears session with zero HTTP calls',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      // Prepopulate active session
      await tokenStorage.saveTokens(
        accessToken: 'active_token',
        refreshToken: 'active_refresh',
      );
      await tokenStorage.saveUserData({'id': 'u_1', 'phone': '+919876543210', 'role': 'farmer'});

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(authRepository),
            ..._getShellOverrides(),
          ],
          child: const BhoomiApp(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Navigate to More Tab
      await tester.tap(find.byIcon(Icons.more_horiz_rounded));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(MoreScreen), findsOneWidget);

      // Tap Logout
      await tester.tap(find.text('बाहेर पडा (Log Out)'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verify Confirmation Dialog
      expect(find.text('तुम्हाला बाहेर पडायचे आहे का?'), findsOneWidget);

      // Tap Confirm Logout
      await tester.tap(find.text('हो, बाहेर पडा'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Verify session cleared
      expect(await tokenStorage.hasValidSession(), isFalse);
      expect(countingClient.totalRequests, 0, reason: 'Logout must make 0 HTTP network calls');

      // Verify redirected back to PhoneAuthScreen
      expect(find.byType(PhoneAuthScreen), findsOneWidget);
    });
  });
}
