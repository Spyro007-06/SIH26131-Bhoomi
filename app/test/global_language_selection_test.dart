import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bhoomi/main.dart';
import 'package:bhoomi/core/localization/locale_provider.dart';
import 'package:bhoomi/core/storage/secure_storage.dart';
import 'package:bhoomi/providers/storage_providers.dart';
import 'package:bhoomi/widgets/language_selector_button.dart';
import 'package:bhoomi/features/onboarding/presentation/phone_auth_screen.dart';
import 'package:bhoomi/features/onboarding/presentation/otp_verify_screen.dart';
import 'package:bhoomi/features/onboarding/presentation/farm_setup_screen.dart';
import 'package:bhoomi/features/home/presentation/home_screen.dart';
import 'package:bhoomi/features/alerts/presentation/alerts_screen.dart';
import 'package:bhoomi/features/timeline/presentation/history_screen.dart';
import 'package:bhoomi/features/more/presentation/more_screen.dart';
import 'package:bhoomi/features/referrals/presentation/referrals_screen.dart';
import 'package:bhoomi/models/farm_models.dart';
import 'package:bhoomi/models/alert_models.dart';
import 'package:bhoomi/models/timeline_models.dart';
import 'package:bhoomi/models/referral_models.dart';
import 'package:bhoomi/repositories/farm_repository.dart';
import 'package:bhoomi/repositories/alert_repository.dart';
import 'package:bhoomi/repositories/timeline_repository.dart';
import 'package:bhoomi/repositories/referral_repository.dart';
import 'package:bhoomi/providers/repository_providers.dart';
import 'package:bhoomi/providers/farm_providers.dart';

class MockTestSecureStorage extends SecureStorage {
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
}

class FakeTestFarmRepo extends FarmRepository {
  @override
  Future<FarmSummaryModel> getFarmSummary(String farmId) async {
    return const FarmSummaryModel(
      farm: FarmModel(
        id: 'f_test_01',
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

class FakeTestAlertRepo extends AlertRepository {
  @override
  Future<AlertsResponse> getAlerts({required String farmId, int limit = 20, String? cursor}) async {
    return const AlertsResponse(alerts: []);
  }

  @override
  Future<AlertRespondResponse> respondToAlert({required String alertId, required String outcome, String? imageAssetId}) async {
    return const AlertRespondResponse(status: 'recorded', alertId: 'alt_1', recordedAt: '2026-08-31');
  }
}

class FakeTestTimelineRepo extends TimelineRepository {
  @override
  Future<TimelineResponse> getTimeline({required String farmId, int limit = 20, String? cursor}) async {
    return const TimelineResponse(events: []);
  }
}

class FakeTestReferralRepo extends ReferralRepository {
  @override
  Future<ReferralsResponse> getReferrals(String farmId) async {
    return ReferralsResponse(referrals: []);
  }
}

List<Override> _getTestOverrides(MockTestSecureStorage storage) {
  return [
    secureStorageProvider.overrideWithValue(storage),
    activeFarmIdProvider.overrideWith((ref) => ActiveFarmIdNotifier(null, 'f_test_01')),
    farmRepositoryProvider.overrideWithValue(FakeTestFarmRepo()),
    alertRepositoryProvider.overrideWithValue(FakeTestAlertRepo()),
    timelineRepositoryProvider.overrideWithValue(FakeTestTimelineRepo()),
    referralRepositoryProvider.overrideWithValue(FakeTestReferralRepo()),
  ];
}

void main() {
  group('Global Language Selection & Multilingual Support Tests', () {
    late MockTestSecureStorage storage;

    setUp(() {
      storage = MockTestSecureStorage();
    });

    testWidgets('Default language is Marathi (Primary - mr-IN)', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: _getTestOverrides(storage),
          child: const BhoomiApp(homeOverride: PhoneAuthScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Language button shows Marathi by default
      expect(find.byType(LanguageSelectorButton), findsOneWidget);
      expect(find.text('मराठी'), findsOneWidget);
      expect(find.text('भूमीमध्ये आपले स्वागत आहे'), findsOneWidget);
    });

    testWidgets('Global Language Selector modal opens and switches language to Hindi & English dynamically',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: _getTestOverrides(storage),
          child: const BhoomiApp(homeOverride: PhoneAuthScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Language Button
      await tester.tap(find.byType(LanguageSelectorButton));
      await tester.pumpAndSettle();

      // Modal options visible
      expect(find.text('भाषा निवडा / Select Language'), findsOneWidget);
      expect(find.text('मराठी'), findsWidgets);
      expect(find.text('हिंदी'), findsOneWidget);
      expect(find.text('English'), findsOneWidget);

      // Select Hindi
      await tester.tap(find.text('हिंदी'));
      await tester.pumpAndSettle();

      // Verify immediate UI update to Hindi
      expect(find.text('भूमी में आपका स्वागत है'), findsOneWidget);
      expect(find.text('हिंदी'), findsOneWidget);

      // Verify saved to local storage
      expect(await storage.read(key: LocaleNotifier.languageStorageKey), 'hi');

      // Tap again to switch to English
      await tester.tap(find.byType(LanguageSelectorButton));
      await tester.pumpAndSettle();
      await tester.tap(find.text('English'));
      await tester.pumpAndSettle();

      // Verify immediate UI update to English
      expect(find.text('Welcome to Bhoomi'), findsOneWidget);
      expect(find.text('English'), findsOneWidget);
      expect(await storage.read(key: LocaleNotifier.languageStorageKey), 'en');
    });

    testWidgets('Language selection persists and restores on next app launch', (WidgetTester tester) async {
      // Pre-populate storage with Hindi
      await storage.write(key: LocaleNotifier.languageStorageKey, value: 'hi');

      await tester.pumpWidget(
        ProviderScope(
          overrides: _getTestOverrides(storage),
          child: const BhoomiApp(homeOverride: PhoneAuthScreen()),
        ),
      );
      // Let async storage read resolve
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      expect(find.text('भूमी में आपका स्वागत है'), findsOneWidget);
      expect(find.text('हिंदी'), findsOneWidget);
    });

    testWidgets('LanguageSelectorButton is present on all key application screens',
        (WidgetTester tester) async {
      final screens = <Widget>[
        const PhoneAuthScreen(),
        const OtpVerifyScreen(phoneNumber: '+919876543210', requestId: 'req_1'),
        const FarmSetupScreen(),
        const HomeScreen(),
        const AlertsScreen(),
        const HistoryScreen(),
        const ReferralsScreen(),
        const MoreScreen(),
      ];

      for (final screen in screens) {
        await tester.pumpWidget(
          ProviderScope(
            overrides: _getTestOverrides(storage),
            child: BhoomiApp(homeOverride: screen),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          find.byType(LanguageSelectorButton),
          findsAtLeastNWidgets(1),
          reason: 'LanguageSelectorButton must be present on ${screen.runtimeType}',
        );
      }
    });

    testWidgets('LanguageSelectorButton responds safely across multiple screen viewports without overflow',
        (WidgetTester tester) async {
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      final viewports = [
        const Size(360, 640),
        const Size(390, 844),
        const Size(412, 915),
        const Size(540, 1200),
        const Size(1080, 2400),
      ];

      for (final vp in viewports) {
        tester.view.physicalSize = vp * 2.0;

        await tester.pumpWidget(
          ProviderScope(
            overrides: _getTestOverrides(storage),
            child: const BhoomiApp(homeOverride: PhoneAuthScreen()),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(LanguageSelectorButton), findsOneWidget);
        expect(tester.takeException(), isNull, reason: 'No layout overflow on viewport $vp');
      }
    });

    testWidgets('LanguageSelectorButton supports accessibility text scaling (1.0x, 1.5x, 2.0x)',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      final scales = [1.0, 1.5, 2.0];

      for (final scale in scales) {
        await tester.pumpWidget(
          ProviderScope(
            overrides: _getTestOverrides(storage),
            child: MediaQuery(
              data: MediaQueryData(textScaler: TextScaler.linear(scale)),
              child: const BhoomiApp(homeOverride: PhoneAuthScreen()),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(LanguageSelectorButton), findsOneWidget);
        expect(tester.takeException(), isNull, reason: 'No overflow at text scale ${scale}x');
      }
    });
  });
}
