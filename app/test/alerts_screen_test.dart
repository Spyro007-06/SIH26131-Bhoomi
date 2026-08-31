import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bhoomi/main.dart';
import 'package:bhoomi/models/alert_models.dart';
import 'package:bhoomi/repositories/alert_repository.dart';
import 'package:bhoomi/providers/repository_providers.dart';
import 'package:bhoomi/providers/farm_providers.dart';
import 'package:bhoomi/features/alerts/presentation/alerts_screen.dart';
import 'package:bhoomi/widgets/risk_card.dart';

class FakeAlertRepository extends AlertRepository {
  bool returnEmpty = false;
  String? lastRespondedAlertId;
  String? lastRespondedOutcome;

  @override
  Future<AlertsResponse> getAlerts({required String farmId, int limit = 20, String? cursor}) async {
    if (returnEmpty) {
      return const AlertsResponse(alerts: [], count: 0);
    }
    return const AlertsResponse(
      alerts: [
        AlertModel(
          id: 'alert_weather_99',
          farmId: 'f_nashik_01',
          target: 'blast',
          riskLevel: 'high',
          triggerType: 'weather',
          reason: 'Continuous rainfall with high humidity.',
          inspectionTasks: [
            'Inspect upper leaf surfaces for spindle lesions.',
            'Check field borders near shaded areas.',
          ],
          createdAt: '2026-08-31T08:00:00Z',
        ),
      ],
      count: 1,
    );
  }

  @override
  Future<AlertRespondResponse> respondToAlert({
    required String alertId,
    required String outcome,
    String? imageAssetId,
  }) async {
    lastRespondedAlertId = alertId;
    lastRespondedOutcome = outcome;
    return const AlertRespondResponse(
      status: 'recorded',
      alertId: 'alert_weather_99',
      recordedAt: '2026-08-31T09:00:00Z',
    );
  }
}

void main() {
  group('Risk Alerts Surveillance Tests (Step 5)', () {
    late FakeAlertRepository fakeAlertRepo;

    setUp(() {
      fakeAlertRepo = FakeAlertRepository();
    });

    testWidgets('Renders active alerts with RiskCard, mandatory tasks, and responds to alert',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            alertRepositoryProvider.overrideWithValue(fakeAlertRepo),
            activeFarmIdProvider.overrideWith((ref) => ActiveFarmIdNotifier(null, 'f_nashik_01')),
          ],
          child: const BhoomiApp(homeOverride: AlertsScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Verify Header and Alert Title
      expect(find.text('कीड व रोग सतर्कता'), findsOneWidget);
      expect(find.byType(RiskCard), findsOneWidget);
      expect(find.text('BLAST'), findsOneWidget);
      expect(find.text('Continuous rainfall with high humidity.'), findsOneWidget);

      // 2. Verify mandatory inspection tasks
      expect(find.text('Inspect upper leaf surfaces for spindle lesions.'), findsOneWidget);

      // 3. Tap "I'LL CHECK"
      await tester.tap(find.textContaining("I'LL CHECK"));
      await tester.pumpAndSettle();

      // 4. Verify API was invoked
      expect(fakeAlertRepo.lastRespondedAlertId, 'alert_weather_99');
      expect(fakeAlertRepo.lastRespondedOutcome, 'found');

      // 5. Response recorded badge is displayed
      expect(find.text('प्रतिसाद नोंदवला गेला आहे. शेताचे निरीक्षण केल्याबद्दल धन्यवाद!'), findsWidgets);
    });

    testWidgets('Renders honest empty state when no active alerts exist',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      fakeAlertRepo.returnEmpty = true;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            alertRepositoryProvider.overrideWithValue(fakeAlertRepo),
            activeFarmIdProvider.overrideWith((ref) => ActiveFarmIdNotifier(null, 'f_nashik_01')),
          ],
          child: const BhoomiApp(homeOverride: AlertsScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('सध्या कोणतीही सतर्कता नाही'), findsOneWidget);
      expect(find.text('तुमच्या परिसरातील हवामान व पीक परिस्थिती सध्या सामान्य आहे.'), findsOneWidget);
      expect(find.byType(RiskCard), findsNothing);
    });
  });
}
