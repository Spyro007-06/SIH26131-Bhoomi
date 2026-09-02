import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bhoomi/main.dart';
import 'package:bhoomi/features/shell/presentation/main_app_shell.dart';
import 'package:bhoomi/features/more/presentation/more_screen.dart';
import 'package:bhoomi/features/alerts/presentation/alerts_screen.dart';
import 'package:bhoomi/features/referrals/presentation/referrals_screen.dart';
import 'package:bhoomi/core/localization/locale_provider.dart';
import 'package:bhoomi/core/localization/app_strings.dart';
import 'package:bhoomi/repositories/voice_repository.dart';
import 'package:bhoomi/repositories/farm_repository.dart';
import 'package:bhoomi/repositories/alert_repository.dart';
import 'package:bhoomi/repositories/followup_repository.dart';
import 'package:bhoomi/repositories/timeline_repository.dart';
import 'package:bhoomi/repositories/referral_repository.dart';
import 'package:bhoomi/models/voice_models.dart';
import 'package:bhoomi/models/farm_models.dart';
import 'package:bhoomi/models/alert_models.dart';
import 'package:bhoomi/models/followup_models.dart';
import 'package:bhoomi/models/timeline_models.dart';
import 'package:bhoomi/models/referral_models.dart';
import 'package:bhoomi/providers/repository_providers.dart';
import 'package:bhoomi/providers/farm_providers.dart';

class FakeVoiceRepo extends VoiceRepository {
  @override
  Future<VoiceTranscribeResult> transcribe({
    required String assetId,
    String lang = 'mr-IN',
    String? context,
  }) async {
    return const VoiceTranscribeResult(
      text: 'उपाययोजना काय करावी?',
      confidence: 0.95,
      lang: 'mr-IN',
    );
  }

  @override
  Future<VoiceSynthesizeResult> synthesize({
    required String text,
    String lang = 'mr-IN',
  }) async {
    return const VoiceSynthesizeResult(
      audioUrl: 'https://bhoomi-s3.gov.in/voice/test.mp3',
      expiresIn: 600,
    );
  }
}

class FakeFarmRepo extends FarmRepository {
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

class FakeAlertRepo extends AlertRepository {
  @override
  Future<AlertsResponse> getAlerts({required String farmId, int limit = 20, String? cursor}) async {
    return const AlertsResponse(alerts: []);
  }

  @override
  Future<AlertRespondResponse> respondToAlert({required String alertId, required String outcome, String? imageAssetId}) async {
    return const AlertRespondResponse(status: 'recorded', alertId: 'alt_1', recordedAt: '2026-08-31');
  }
}

class FakeFollowUpRepo extends FollowUpRepository {
  @override
  Future<PendingFollowUpsResponse> getPendingFollowUps(String farmId) async {
    return const PendingFollowUpsResponse(followUps: []);
  }

  @override
  Future<FollowUpResultModel> respondToFollowUp({required String followUpId, required String response, String? imageAssetId}) async {
    return const FollowUpResultModel(status: 'success');
  }
}

class FakeTimelineRepo extends TimelineRepository {
  @override
  Future<TimelineResponse> getTimeline({required String farmId, int limit = 20, String? cursor}) async {
    return const TimelineResponse(events: []);
  }
}

class FakeReferralRepo extends ReferralRepository {
  @override
  Future<ReferralsResponse> getReferrals(String farmId) async {
    return ReferralsResponse(referrals: []);
  }
}

List<Override> _getTestOverrides() {
  return [
    activeFarmIdProvider.overrideWith((ref) => ActiveFarmIdNotifier(null, 'f_shell_01')),
    farmRepositoryProvider.overrideWithValue(FakeFarmRepo()),
    alertRepositoryProvider.overrideWithValue(FakeAlertRepo()),
    followUpRepositoryProvider.overrideWithValue(FakeFollowUpRepo()),
    timelineRepositoryProvider.overrideWithValue(FakeTimelineRepo()),
    referralRepositoryProvider.overrideWithValue(FakeReferralRepo()),
    voiceRepositoryProvider.overrideWithValue(FakeVoiceRepo()),
  ];
}

void main() {
  group('Phase 4: Navigation Simplification & Farmer Journey Optimization Tests', () {
    testWidgets('Bottom Navigation switches tabs and PopScope returns to Home',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          overrides: _getTestOverrides(),
          child: const BhoomiApp(
            homeOverride: MainAppShell(initialIndex: 0),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Starts on Home
      expect(find.text('बोलून विचारा'), findsWidgets);

      // Tap Alerts tab
      await tester.tap(find.byIcon(Icons.shield_outlined).last);
      await tester.pumpAndSettle();
      expect(find.byType(AlertsScreen), findsOneWidget);

      // Trigger back button (PopScope intercepts and switches back to tab 0)
      final dynamic widgetsAppState = tester.state(find.byType(WidgetsApp));
      await widgetsAppState.didPopRoute();
      await tester.pumpAndSettle();

      // Successfully back on Home
      expect(find.text('बोलून विचारा'), findsWidgets);
    });

    testWidgets('More Screen renders clean secondary options and navigates without clutter',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          overrides: _getTestOverrides(),
          child: const BhoomiApp(
            homeOverride: MoreScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check secondary options
      expect(find.text('माझे शेत व पीक माहिती'), findsOneWidget);
      expect(find.text('कृषी विज्ञान केंद्र (KVK) व मदत केंद्र'), findsOneWidget);
      expect(find.text('तपासणी व सल्ला इतिहास'), findsOneWidget);
      expect(find.text('भाषा बदला (Change Language)'), findsOneWidget);
      expect(find.text('भूमीबद्दल माहिती'), findsOneWidget);
      expect(find.text('बाहेर पडा (Log Out)'), findsOneWidget);

      // Tap KVK & Helpline
      await tester.tap(find.text('कृषी विज्ञान केंद्र (KVK) व मदत केंद्र'));
      await tester.pumpAndSettle();
      expect(find.byType(ReferralsScreen), findsOneWidget);

      // Go back to More
      await tester.tap(find.byIcon(Icons.arrow_back_rounded));
      await tester.pumpAndSettle();
      expect(find.byType(MoreScreen), findsOneWidget);
    });

    testWidgets('Multilingual Navigation Verification (Marathi, Hindi, English)',
        (WidgetTester tester) async {
      for (final lang in AppLanguage.values) {
        final notifier = LocaleNotifier(null);
        notifier.state = lang;

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              ..._getTestOverrides(),
              appLanguageProvider.overrideWith((ref) => notifier),
            ],
            child: const BhoomiApp(
              homeOverride: MainAppShell(initialIndex: 0),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(MainAppShell), findsOneWidget);
      }
    });

    testWidgets('Dynamic Text Scaling at 1.0x, 1.5x, 2.0x in Main Shell and More Screen',
        (WidgetTester tester) async {
      for (final textScale in [1.0, 1.5, 2.0]) {
        tester.view.physicalSize = const Size(360, 640) * 2.0;
        tester.view.devicePixelRatio = 2.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          ProviderScope(
            overrides: _getTestOverrides(),
            child: MediaQuery(
              data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
              child: const BhoomiApp(
                homeOverride: MainAppShell(initialIndex: 4),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.byType(MoreScreen), findsOneWidget);
      }
    });
  });
}
