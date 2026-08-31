import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bhoomi/main.dart';
import 'package:bhoomi/models/farm_models.dart';
import 'package:bhoomi/models/alert_models.dart';
import 'package:bhoomi/models/followup_models.dart';
import 'package:bhoomi/models/timeline_models.dart';
import 'package:bhoomi/repositories/farm_repository.dart';
import 'package:bhoomi/repositories/alert_repository.dart';
import 'package:bhoomi/repositories/followup_repository.dart';
import 'package:bhoomi/repositories/timeline_repository.dart';
import 'package:bhoomi/providers/repository_providers.dart';
import 'package:bhoomi/providers/farm_providers.dart';
import 'package:bhoomi/features/home/presentation/home_screen.dart';
import 'package:bhoomi/widgets/farm_health_card.dart';
import 'package:bhoomi/widgets/risk_card.dart';
import 'package:bhoomi/widgets/followup_card.dart';

class FakeHomeFarmRepo extends FarmRepository {
  @override
  Future<FarmSummaryModel> getFarmSummary(String farmId) async {
    return const FarmSummaryModel(
      farm: FarmModel(
        id: 'f_dash_01',
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

class FakeHomeAlertRepo extends AlertRepository {
  @override
  Future<AlertsResponse> getAlerts({required String farmId, int limit = 20, String? cursor}) async {
    return const AlertsResponse(
      alerts: [
        AlertModel(
          id: 'alt_home_1',
          farmId: 'f_dash_01',
          target: 'blast',
          riskLevel: 'high',
          triggerType: 'weather',
          reason: 'Rainfall and humidity spike.',
          inspectionTasks: ['Check upper leaves for spindle lesions.'],
          createdAt: '2026-08-31T08:00:00Z',
        ),
      ],
      count: 1,
    );
  }

  @override
  Future<AlertRespondResponse> respondToAlert({required String alertId, required String outcome, String? imageAssetId}) async {
    return const AlertRespondResponse(status: 'recorded', alertId: 'alt_home_1', recordedAt: '2026-08-31T09:00:00Z');
  }
}

class FakeHomeFollowUpRepo extends FollowUpRepository {
  @override
  Future<PendingFollowUpsResponse> getPendingFollowUps(String farmId) async {
    return const PendingFollowUpsResponse(
      followUps: [
        FollowUpItemModel(
          id: 'fu_home_1',
          problemId: 'p_dash_101',
          farmId: 'f_dash_01',
          target: 'blast_treatment',
          question: 'Are lesions drying up?',
          dueAt: '2026-08-31T10:00:00Z',
        ),
      ],
      count: 1,
    );
  }

  @override
  Future<FollowUpResultModel> respondToFollowUp({required String followUpId, required String response, String? imageAssetId}) async {
    return const FollowUpResultModel(status: 'recorded', escalated: false);
  }
}

class FakeHomeTimelineRepo extends TimelineRepository {
  @override
  Future<TimelineResponse> getTimeline({required String farmId, int limit = 20, String? cursor}) async {
    return const TimelineResponse(
      events: [
        TimelineEventModel(
          id: 'ev_home_1',
          farmId: 'f_dash_01',
          eventType: 'diagnosis',
          title: 'Blast Diagnosed',
          timestamp: '2026-08-31T08:00:00Z',
        ),
      ],
      count: 1,
    );
  }
}

void main() {
  group('Home Dashboard Integration Tests (Step 5)', () {
    testWidgets('Renders health card, active alert, pending follow-up, and timeline activity',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      bool checkCropTapped = false;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            farmRepositoryProvider.overrideWithValue(FakeHomeFarmRepo()),
            alertRepositoryProvider.overrideWithValue(FakeHomeAlertRepo()),
            followUpRepositoryProvider.overrideWithValue(FakeHomeFollowUpRepo()),
            timelineRepositoryProvider.overrideWithValue(FakeHomeTimelineRepo()),
            activeFarmIdProvider.overrideWith((ref) => ActiveFarmIdNotifier(null, 'f_dash_01')),
          ],
          child: BhoomiApp(
            homeOverride: HomeScreen(
              onCheckCropPressed: () => checkCropTapped = true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Verify Farm Health Card
      expect(find.byType(FarmHealthCard), findsOneWidget);
      expect(find.text('Field health is stable.'), findsOneWidget);

      // 2. Verify Hero Check Crop Action and tap
      expect(find.text('पिकावर काही रोग किंवा कीड दिसतेय?'), findsOneWidget);
      await tester.tap(find.text('पिकावर काही रोग किंवा कीड दिसतेय?'));
      expect(checkCropTapped, isTrue);

      // 3. Verify Active Risk Alert is rendered live
      expect(find.byType(RiskCard), findsOneWidget);
      expect(find.text('BLAST'), findsOneWidget);

      // 4. Verify Pending Follow-up is rendered live
      expect(find.byType(FollowUpCard), findsOneWidget);
      expect(find.text('BLAST TREATMENT'), findsOneWidget);

      // 5. Verify Recent Activity is rendered
      expect(find.text('Blast Diagnosed'), findsOneWidget);
    });
  });
}
