import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bhoomi/main.dart';
import 'package:bhoomi/models/farm_models.dart';
import 'package:bhoomi/models/alert_models.dart';
import 'package:bhoomi/models/followup_models.dart';
import 'package:bhoomi/models/timeline_models.dart';
import 'package:bhoomi/models/diagnosis_models.dart';
import 'package:bhoomi/models/advisory_models.dart';
import 'package:bhoomi/models/gate_models.dart';
import 'package:bhoomi/repositories/farm_repository.dart';
import 'package:bhoomi/repositories/alert_repository.dart';
import 'package:bhoomi/repositories/followup_repository.dart';
import 'package:bhoomi/repositories/timeline_repository.dart';
import 'package:bhoomi/providers/repository_providers.dart';
import 'package:bhoomi/providers/farm_providers.dart';
import 'package:bhoomi/features/home/presentation/home_screen.dart';
import 'package:bhoomi/features/diagnose/presentation/advisory_result_screen.dart';
import 'package:bhoomi/widgets/farm_health_card.dart';
import 'package:bhoomi/widgets/followup_card.dart';
import 'package:bhoomi/widgets/language_selector_button.dart';

class FakeLowLiteracyFarmRepo extends FarmRepository {
  @override
  Future<FarmSummaryModel> getFarmSummary(String farmId) async {
    return const FarmSummaryModel(
      farm: FarmModel(
        id: 'f_lit_01',
        crop: 'paddy',
        variety: 'Indrayani',
        growthStage: 'Tillering',
        region: 'Nashik',
      ),
      health: HealthModel(sentence: 'Field health is stable.', trend: 'stable'),
      activeProblemsCount: 1,
      pendingFollowUpsCount: 1,
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

class FakeLowLiteracyAlertRepo extends AlertRepository {
  @override
  Future<AlertsResponse> getAlerts({required String farmId, int limit = 20, String? cursor}) async {
    return const AlertsResponse(
      alerts: [
        AlertModel(
          id: 'alt_lit_1',
          farmId: 'f_lit_01',
          target: 'blast',
          riskLevel: 'moderate',
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
    return const AlertRespondResponse(status: 'recorded', alertId: 'alt_lit_1', recordedAt: '2026-09-02');
  }
}

class FakeLowLiteracyFollowUpRepo extends FollowUpRepository {
  @override
  Future<PendingFollowUpsResponse> getPendingFollowUps(String farmId) async {
    return const PendingFollowUpsResponse(
      followups: [
        FollowUpModel(
          id: 'fu_lit_1',
          problemId: 'p_lit_101',
          farmId: 'f_lit_01',
          target: 'blast_treatment',
          question: 'Are lesions drying up after cultural aeration?',
          dueAt: '2026-09-02T10:00:00Z',
        ),
      ],
    );
  }

  @override
  Future<FollowUpResultModel> respondToFollowUp({required String followUpId, required String response, String? imageAssetId}) async {
    return const FollowUpResultModel(status: 'recorded', problemId: 'p_lit_101');
  }
}

class FakeLowLiteracyTimelineRepo extends TimelineRepository {
  @override
  Future<TimelineResponse> getTimeline({required String farmId, int limit = 20, String? cursor}) async {
    return const TimelineResponse(
      events: [
        TimelineEventModel(
          id: 'ev_lit_1',
          farmId: 'f_lit_01',
          type: 'diagnosis',
          title: 'Paddy Blast Diagnosed',
          timestamp: '2026-09-01T08:00:00Z',
        ),
      ],
      count: 1,
    );
  }
}

List<Override> _getOverrides() {
  return [
    farmRepositoryProvider.overrideWithValue(FakeLowLiteracyFarmRepo()),
    alertRepositoryProvider.overrideWithValue(FakeLowLiteracyAlertRepo()),
    followUpRepositoryProvider.overrideWithValue(FakeLowLiteracyFollowUpRepo()),
    timelineRepositoryProvider.overrideWithValue(FakeLowLiteracyTimelineRepo()),
    activeFarmIdProvider.overrideWith((ref) => ActiveFarmIdNotifier(null, 'f_lit_01')),
  ];
}

void main() {
  group('Low-Literacy Farmer UI/UX & Accessibility Tests', () {
    testWidgets('Home Screen provides dominant Check Crop action and voice quick-action',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      bool checkCropTapped = false;

      await tester.pumpWidget(
        ProviderScope(
          overrides: _getOverrides(),
          child: BhoomiApp(
            homeOverride: HomeScreen(
              onCheckCropPressed: () => checkCropTapped = true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Verify Farm Health Card is present
      expect(find.byType(FarmHealthCard), findsOneWidget);

      // 2. Verify Hero Check Crop action is dominant and interactive
      expect(find.byIcon(Icons.camera_alt_rounded), findsWidgets);
      await tester.tap(find.text('पिकावर काही रोग किंवा कीड दिसतेय?'));
      expect(checkCropTapped, isTrue);

      // 3. Verify Voice Assistant shortcut is present
      expect(find.byIcon(Icons.mic_rounded), findsWidgets);
    });

    testWidgets('Advisory Result Screen renders prominent spoken audio button and IPM ladder',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      const mockResponse = DiagnoseResponse(
        problemId: 'p_diag_01',
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
          possibleIssue: 'Early Paddy Blast',
          whatToAvoid: 'Do not spray chemical insecticide for fungal blast.',
          whatToCheck: 'Check diamond lesions with grey center.',
          ladder: [
            LadderRungModel(tier: 'cultural', action: 'Drain excess water'),
            LadderRungModel(tier: 'biological', action: 'Apply Pseudomonas spray'),
          ],
        ),
        spokenSummary: 'भातावरील करपा रोगासाठी पाणी काढा आणि नायट्रोजन खत टाळा.',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: _getOverrides(),
          child: const BhoomiApp(
            homeOverride: AdvisoryResultScreen(response: mockResponse),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Verify High Confidence label
      expect(find.text('उच्च अचूकता (High Confidence)'), findsOneWidget);

      // 2. Verify Prominent Spoken Audio Button
      expect(find.byIcon(Icons.volume_up_rounded), findsOneWidget);

      // Tap spoken audio button
      await tester.tap(find.byIcon(Icons.volume_up_rounded));
      await tester.pump();

      // 3. Verify IPM Ladder content
      expect(find.text('Early Paddy Blast'), findsOneWidget);
      expect(find.textContaining('Drain excess water'), findsOneWidget);
    });

    testWidgets('FollowUpCard renders 3 large visual choice buttons',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      String? recordedOutcome;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FollowUpCard(
              question: 'How is the crop doing?',
              questionLocalized: 'उपचारानंतर पिकाची स्थिती कशी आहे?',
              target: 'PADDY BLAST',
              onResponse: (resp) => recordedOutcome = resp,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify 3 choices: Improved, No change, Got worse
      expect(find.text('Improved\n(सुधारणा)'), findsOneWidget);
      expect(find.text('No change\n(बदल नाही)'), findsOneWidget);
      expect(find.text('Got worse\n(बिघडले)'), findsOneWidget);

      // Tap 'Improved'
      await tester.tap(find.text('Improved\n(सुधारणा)'));
      expect(recordedOutcome, 'improved');
    });

    testWidgets('Responsive & Text Scaling Audit at 1.0x, 1.5x, 2.0x font scaling',
        (WidgetTester tester) async {
      for (final textScale in [1.0, 1.5, 2.0]) {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          ProviderScope(
            overrides: _getOverrides(),
            child: MediaQuery(
              data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
              child: const BhoomiApp(homeOverride: HomeScreen()),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Verifies no RenderFlex overflow occurs at any scaling level
        expect(tester.takeException(), isNull);
        expect(find.byType(HomeScreen), findsOneWidget);
        expect(find.byType(LanguageSelectorButton), findsOneWidget);
      }
    });
  });
}
