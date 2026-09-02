import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bhoomi/main.dart';
import 'package:bhoomi/models/timeline_models.dart';
import 'package:bhoomi/models/problem_models.dart';
import 'package:bhoomi/models/diagnosis_models.dart';
import 'package:bhoomi/repositories/timeline_repository.dart';
import 'package:bhoomi/repositories/problem_repository.dart';
import 'package:bhoomi/providers/repository_providers.dart';
import 'package:bhoomi/providers/farm_providers.dart';
import 'package:bhoomi/features/timeline/presentation/history_screen.dart';
import 'package:bhoomi/features/timeline/presentation/problem_detail_screen.dart';

class FakeTimelineRepository extends TimelineRepository {
  bool returnEmpty = false;

  @override
  Future<TimelineResponse> getTimeline({required String farmId, int limit = 20, String? cursor}) async {
    if (returnEmpty) {
      return const TimelineResponse(events: [], count: 0);
    }
    return const TimelineResponse(
      events: [
        TimelineEventModel(
          id: 'ev_diag_1',
          farmId: 'f_nashik_01',
          eventType: 'diagnosis',
          title: 'Paddy Blast Detected',
          description: 'Early blast symptoms identified with 89% confidence.',
          severity: 'early',
          problemId: 'p_prob_101',
          timestamp: '2026-08-30T14:30:00Z',
        ),
        TimelineEventModel(
          id: 'ev_alert_1',
          farmId: 'f_nashik_01',
          eventType: 'alert',
          title: 'Humidity Alert',
          description: 'High humidity threshold reached.',
          severity: 'medium',
          timestamp: '2026-08-29T10:00:00Z',
        ),
      ],
      count: 2,
    );
  }
}

class FakeProblemRepository extends ProblemRepository {
  @override
  Future<ProblemDetailModel> getProblemDetail(String problemId) async {
    return ProblemDetailModel(
      id: 'p_prob_101',
      farmId: 'f_nashik_01',
      crop: 'paddy',
      type: 'disease',
      label: 'blast',
      severity: 'early',
      status: 'open',
      openedAt: '2026-08-30T14:30:00Z',
      observations: [],
    );
  }

  @override
  Future<ProblemsResponse> getProblems({required String farmId, String? status, String? type, int limit = 20, String? cursor}) =>
      throw UnimplementedError();

  @override
  Future<EscalationModel> escalateProblem(String problemId) => throw UnimplementedError();
}

void main() {
  group('Timeline / Crop History Tests (Step 5)', () {
    late FakeTimelineRepository fakeTimelineRepo;
    late FakeProblemRepository fakeProblemRepo;

    setUp(() {
      fakeTimelineRepo = FakeTimelineRepository();
      fakeProblemRepo = FakeProblemRepository();
    });

    testWidgets('Renders timeline events and navigates to ProblemDetailScreen on tap',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            timelineRepositoryProvider.overrideWithValue(fakeTimelineRepo),
            problemRepositoryProvider.overrideWithValue(fakeProblemRepo),
            activeFarmIdProvider.overrideWith((ref) => ActiveFarmIdNotifier(null, 'f_nashik_01')),
          ],
          child: const BhoomiApp(homeOverride: HistoryScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Verify Timeline Title & Events
      expect(find.text('पीक इतिहास (Timeline)'), findsOneWidget);
      expect(find.text('Paddy Blast Detected'), findsOneWidget);
      expect(find.text('Humidity Alert'), findsOneWidget);

      // 2. Tap event with problemId
      await tester.tap(find.text('Paddy Blast Detected'));
      await tester.pumpAndSettle();

      // 3. Navigated to ProblemDetailScreen
      expect(find.byType(ProblemDetailScreen), findsOneWidget);
      expect(find.text('समस्या सविस्तर माहिती'), findsOneWidget);
      expect(find.text('BLAST'), findsOneWidget);
    });

    testWidgets('Renders empty state when timeline has no events',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      fakeTimelineRepo.returnEmpty = true;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            timelineRepositoryProvider.overrideWithValue(fakeTimelineRepo),
            activeFarmIdProvider.overrideWith((ref) => ActiveFarmIdNotifier(null, 'f_nashik_01')),
          ],
          child: const BhoomiApp(homeOverride: HistoryScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('अजून कोणताही इतिहास नाही'), findsOneWidget);
      expect(find.text('निदान, सतर्कता किंवा उपचारानंतरच्या नोंदी येथे दिसतील.'), findsOneWidget);
    });
  });
}
