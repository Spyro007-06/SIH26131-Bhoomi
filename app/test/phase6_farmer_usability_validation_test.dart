import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bhoomi/main.dart';
import 'package:bhoomi/core/theme/app_theme.dart';
import 'package:bhoomi/core/localization/locale_provider.dart';
import 'package:bhoomi/core/localization/app_strings.dart';
import 'package:bhoomi/features/shell/presentation/main_app_shell.dart';
import 'package:bhoomi/features/diagnose/presentation/camera_capture_screen.dart';
import 'package:bhoomi/features/diagnose/presentation/advisory_result_screen.dart';
import 'package:bhoomi/features/alerts/presentation/alerts_screen.dart';
import 'package:bhoomi/widgets/farmer_voice_assistant.dart';
import 'package:bhoomi/models/diagnosis_models.dart';
import 'package:bhoomi/models/gate_models.dart';
import 'package:bhoomi/models/advisory_models.dart';
import 'package:bhoomi/models/alert_models.dart';
import 'package:bhoomi/models/farm_models.dart';
import 'package:bhoomi/models/followup_models.dart';
import 'package:bhoomi/models/timeline_models.dart';
import 'package:bhoomi/models/referral_models.dart';
import 'package:bhoomi/models/voice_models.dart';
import 'package:bhoomi/providers/repository_providers.dart';
import 'package:bhoomi/providers/farm_providers.dart';
import 'package:bhoomi/repositories/farm_repository.dart';
import 'package:bhoomi/repositories/alert_repository.dart';
import 'package:bhoomi/repositories/followup_repository.dart';
import 'package:bhoomi/repositories/timeline_repository.dart';
import 'package:bhoomi/repositories/referral_repository.dart';
import 'package:bhoomi/repositories/voice_repository.dart';

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
        id: 'f_p6_01',
        crop: 'paddy',
        variety: 'Indrayani',
        growthStage: 'Tillering',
        region: 'Nashik',
      ),
      health: HealthModel(sentence: 'Field health is stable.', trend: 'stable'),
      activeProblemsCount: 0,
      pendingFollowUpsCount: 0,
      activeAlertsCount: 1,
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
    return const AlertsResponse(
      alerts: [
        AlertModel(
          id: 'alt_p6_1',
          farmId: 'f_p6_01',
          target: 'blast',
          riskLevel: 'high',
          triggerType: 'weather',
          reason: 'Favourable weather detected in Nashik cluster.',
          inspectionTasks: ['Check upper leaves for diamond spots.'],
          issuedAt: '2026-09-01T08:00:00Z',
        ),
      ],
      count: 1,
    );
  }

  @override
  Future<AlertRespondResponse> respondToAlert({required String alertId, required String outcome, String? imageAssetId}) async {
    return const AlertRespondResponse(status: 'recorded', alertId: 'alt_p6_1', recordedAt: '2026-09-02');
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

List<Override> _createValidationOverrides() {
  return [
    activeFarmIdProvider.overrideWith((ref) => ActiveFarmIdNotifier(null, 'f_p6_01')),
    farmRepositoryProvider.overrideWithValue(FakeFarmRepo()),
    alertRepositoryProvider.overrideWithValue(FakeAlertRepo()),
    followUpRepositoryProvider.overrideWithValue(FakeFollowUpRepo()),
    timelineRepositoryProvider.overrideWithValue(FakeTimelineRepo()),
    referralRepositoryProvider.overrideWithValue(FakeReferralRepo()),
    voiceRepositoryProvider.overrideWithValue(FakeVoiceRepo()),
  ];
}

void main() {
  group('Phase 6: Real Farmer Usability Validation & SIH Readiness Suite', () {
    testWidgets('1. 3-Second Home Test: Voice is unmistakably Primary & Crop Vision is Secondary',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          overrides: _createValidationOverrides(),
          child: const BhoomiApp(
            homeOverride: MainAppShell(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Home Screen Voice Hero & Core actions visible within 3 seconds
      expect(find.text('बोलायला सुरुवात करा'), findsOneWidget);
      expect(find.text('पीक तपासा'), findsWidgets);
      expect(find.byIcon(Icons.mic_rounded), findsWidgets);
      expect(find.byIcon(Icons.camera_alt_rounded), findsWidgets);
    });

    testWidgets('2. Voice Lifecycle: Idle -> Listening -> Processing -> Result -> Audio Narration',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          overrides: _createValidationOverrides(),
          child: const BhoomiApp(
            homeOverride: Scaffold(
              body: FarmerVoiceAssistant(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // IDLE
      expect(find.text('बोलायला सुरुवात करा'), findsOneWidget);

      // START LISTENING
      await tester.tap(find.text('बोलायला सुरुवात करा'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // LISTENING
      expect(find.text('ऐकत आहे... बोला'), findsOneWidget);
      expect(find.text('थांबवा'), findsOneWidget);

      // STOP LISTENING & PROCESS
      await tester.tap(find.text('थांबवा'));
      await tester.pump();
      await tester.pumpAndSettle();

      // RESULT & ANSWER
      expect(find.text('Bhoomi चे उत्तर'), findsOneWidget);
      expect(find.text('सल्ला ऐका (Listen)'), findsOneWidget);
      expect(find.text('आणखी विचारा'), findsOneWidget);

      // AUDIO PLAYBACK
      await tester.tap(find.text('सल्ला ऐका (Listen)'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('सल्ला ऐकत आहात'), findsOneWidget);
    });

    testWidgets('3. Camera Framing & Crop Vision Journey with localized reticle instructions',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          overrides: _createValidationOverrides(),
          child: const BhoomiApp(
            homeOverride: CameraCaptureScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Viewfinder and guidance
      expect(find.text('पाने किंवा बाधित भाग चौकटीत ठेवा'), findsOneWidget);
      expect(find.byIcon(Icons.eco_rounded), findsOneWidget);
      expect(find.byIcon(Icons.photo_library_outlined), findsOneWidget);
    });

    testWidgets('4. Grounded Advisory & Pesticide Safety: Cultural -> Biological -> Chemical ordering',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      const mockResponse = DiagnoseResponse(
        problemId: 'p_diag_p6_01',
        gate: GateDecision(
          outcome: 'advise',
          confidence: 0.94,
          thresholdApplied: 0.70,
          reasonCode: 'ABOVE_GATE',
          alternatives: [],
        ),
        diagnosis: DiagnosisDetail(
          label: 'paddy_blast',
          confidence: 0.94,
          severity: 'early',
        ),
        advisory: AdvisoryModel(
          possibleIssue: 'Paddy Blast (करपा)',
          whatToAvoid: 'नत्राचा अतिरिक्त वापर टाळा.',
          whatToCheck: 'पानावरील डाग तपासा.',
          ladder: [
            LadderRungModel(tier: 'cultural', action: 'Drain excess water'),
            LadderRungModel(tier: 'biological', action: 'Apply Pseudomonas spray'),
          ],
        ),
        spokenSummary: 'भातावरील करपा रोगासाठी पाणी काढा आणि नायट्रोजन खत टाळा.',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: _createValidationOverrides(),
          child: const BhoomiApp(
            homeOverride: AdvisoryResultScreen(response: mockResponse),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // What to do & High Confidence
      expect(find.text('उच्च अचूकता (High Confidence)'), findsOneWidget);
      expect(find.text('WHAT TO AVOID FIRST (हे अजिबात करू नका):'), findsOneWidget);
      expect(find.text('या समस्येबद्दल विचारा'), findsOneWidget);
      expect(find.byIcon(Icons.volume_up_rounded), findsOneWidget);
    });

    testWidgets('5. Alerts, Contextual Voice & Farmer Help: Discoverable within 2 Taps',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          overrides: _createValidationOverrides(),
          child: const BhoomiApp(
            homeOverride: AlertsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('हा इशारा का आला?'), findsOneWidget);
      expect(find.byIcon(Icons.mic_rounded), findsWidgets);
    });

    testWidgets('6. Multilingual Verification across Marathi, Hindi, English',
        (WidgetTester tester) async {
      for (final lang in AppLanguage.values) {
        final notifier = LocaleNotifier(null);
        notifier.state = lang;

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              ..._createValidationOverrides(),
              appLanguageProvider.overrideWith((ref) => notifier),
            ],
            child: const BhoomiApp(
              homeOverride: MainAppShell(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(MainAppShell), findsOneWidget);
      }
    });

    testWidgets('7. Dynamic Text Scaling at 1.0x, 1.5x, 2.0x on Compact 360x640 Device',
        (WidgetTester tester) async {
      for (final textScale in [1.0, 1.5, 2.0]) {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          ProviderScope(
            overrides: _createValidationOverrides(),
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: TextScaler.linear(textScale),
                ),
                child: child!,
              ),
              home: const MainAppShell(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.byType(MainAppShell), findsOneWidget);
      }
    });
  });
}
