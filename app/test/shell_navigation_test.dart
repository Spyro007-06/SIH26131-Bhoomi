import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bhoomi/main.dart';
import 'package:bhoomi/features/shell/presentation/main_app_shell.dart';
import 'package:bhoomi/features/home/presentation/home_screen.dart';
import 'package:bhoomi/features/diagnose/presentation/camera_capture_screen.dart';
import 'package:bhoomi/features/alerts/presentation/alerts_screen.dart';
import 'package:bhoomi/features/timeline/presentation/history_screen.dart';
import 'package:bhoomi/features/more/presentation/more_screen.dart';
import 'package:bhoomi/models/farm_models.dart';
import 'package:bhoomi/models/alert_models.dart';
import 'package:bhoomi/models/followup_models.dart';
import 'package:bhoomi/models/timeline_models.dart';
import 'package:bhoomi/models/referral_models.dart';
import 'package:bhoomi/repositories/farm_repository.dart';
import 'package:bhoomi/repositories/alert_repository.dart';
import 'package:bhoomi/repositories/followup_repository.dart';
import 'package:bhoomi/repositories/timeline_repository.dart';
import 'package:bhoomi/repositories/referral_repository.dart';
import 'package:bhoomi/providers/repository_providers.dart';
import 'package:bhoomi/providers/farm_providers.dart';

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
  group('Main App Shell & Navigation Tests (Step 3)', () {
    testWidgets('Renders all 5 navigation tabs and switches destinations',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          overrides: _getShellOverrides(),
          child: const BhoomiApp(homeOverride: MainAppShell()),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Initial tab is Home
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.text('मुख्य'), findsWidgets);
      expect(find.text('पीक तपासा'), findsWidgets);
      expect(find.text('सतर्कता'), findsWidgets);
      expect(find.text('इतिहास'), findsWidgets);
      expect(find.text('अधिक'), findsWidgets);

      // 2. Switch to Check Crop Tab (Index 1)
      await tester.tap(find.byIcon(Icons.camera_alt_rounded).last);
      await tester.pumpAndSettle();
      expect(find.byType(CameraCaptureScreen), findsOneWidget);

      // 3. Switch to Alerts Tab (Index 2)
      await tester.tap(find.byIcon(Icons.shield_outlined).last);
      await tester.pumpAndSettle();
      expect(find.byType(AlertsScreen), findsOneWidget);

      // 4. Switch to History Tab (Index 3)
      await tester.tap(find.byIcon(Icons.history_rounded).last);
      await tester.pumpAndSettle();
      expect(find.byType(HistoryScreen), findsOneWidget);

      // 5. Switch to More Tab (Index 4)
      await tester.tap(find.byIcon(Icons.more_horiz_rounded));
      await tester.pumpAndSettle();
      expect(find.byType(MoreScreen), findsOneWidget);

      // 6. Switch back to Home Tab (Index 0)
      await tester.tap(find.byIcon(Icons.home_outlined));
      await tester.pumpAndSettle();
      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('Check Crop Hero Banner on Home navigates directly to Check Crop tab',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          overrides: _getShellOverrides(),
          child: const BhoomiApp(homeOverride: MainAppShell()),
        ),
      );
      await tester.pumpAndSettle();

      // On Home Screen, tap "Spot any disease? Take photo now" card
      expect(find.text('पिकावर काही रोग किंवा कीड दिसतेय?'), findsOneWidget);
      await tester.tap(find.text('पिकावर काही रोग किंवा कीड दिसतेय?'));
      await tester.pumpAndSettle();

      // Switched to Check Crop tab
      expect(find.byType(CameraCaptureScreen), findsOneWidget);
    });

    testWidgets('Responsive layouts render cleanly across common mobile viewports',
        (WidgetTester tester) async {
      final viewports = [
        const Size(360, 640), // Compact Android
        const Size(390, 844), // Standard Android/iOS
        const Size(412, 915), // Tall Android
      ];

      for (final size in viewports) {
        tester.view.physicalSize = size * 2.0;
        tester.view.devicePixelRatio = 2.0;

        await tester.pumpWidget(
          ProviderScope(
            overrides: _getShellOverrides(),
            child: const BhoomiApp(homeOverride: MainAppShell()),
          ),
        );
        await tester.pumpAndSettle();

        // Ensure no layout overflow exceptions occurred
        expect(tester.takeException(), isNull);
        expect(find.byType(MainAppShell), findsOneWidget);
      }
      tester.view.resetPhysicalSize();
    });
  });
}
