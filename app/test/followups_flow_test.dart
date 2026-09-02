import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bhoomi/main.dart';
import 'package:bhoomi/models/followup_models.dart';
import 'package:bhoomi/models/farm_models.dart';
import 'package:bhoomi/repositories/followup_repository.dart';
import 'package:bhoomi/providers/repository_providers.dart';
import 'package:bhoomi/providers/farm_providers.dart';
import 'package:bhoomi/features/followup/presentation/followups_screen.dart';
import 'package:bhoomi/widgets/followup_card.dart';

class FakeFollowUpRepository extends FollowUpRepository {
  bool returnEmpty = false;
  String? lastFollowUpId;
  String? lastResponseValue;

  @override
  Future<PendingFollowUpsResponse> getPendingFollowUps(String farmId) async {
    if (returnEmpty) {
      return const PendingFollowUpsResponse(followUps: [], count: 0);
    }
    return const PendingFollowUpsResponse(
      followUps: [
        FollowUpItemModel(
          id: 'fu_treatment_01',
          problemId: 'p_blast_101',
          farmId: 'f_nashik_01',
          target: 'blast_treatment',
          question: 'Are lesions drying up after bio-control spray?',
          dueAt: '2026-08-31T10:00:00Z',
        ),
      ],
      count: 1,
    );
  }

  @override
  Future<FollowUpResultModel> respondToFollowUp({
    required String followUpId,
    required String response,
    String? imageAssetId,
  }) async {
    lastFollowUpId = followUpId;
    lastResponseValue = response;
    return const FollowUpResultModel(
      status: 'recorded',
      severityChange: SeverityChangeModel(from: 'moderate', to: 'early'),
      health: HealthModel(sentence: 'Crop health improving.', trend: 'improving'),
      escalated: false,
    );
  }
}

void main() {
  group('Closed-Loop Follow-Up Flow Tests (Step 5)', () {
    late FakeFollowUpRepository fakeFollowUpRepo;

    setUp(() {
      fakeFollowUpRepo = FakeFollowUpRepository();
    });

    testWidgets('Renders pending follow-up and posts improved response with severity change',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            followUpRepositoryProvider.overrideWithValue(fakeFollowUpRepo),
            activeFarmIdProvider.overrideWith((ref) => ActiveFarmIdNotifier(null, 'f_nashik_01')),
          ],
          child: const BhoomiApp(homeOverride: FollowupsScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Verify FollowUpCard is rendered
      expect(find.byType(FollowUpCard), findsOneWidget);
      expect(find.text('BLAST TREATMENT'), findsOneWidget);
      expect(find.text('Are lesions drying up after bio-control spray?'), findsOneWidget);

      // 2. Verify 3 tactile buttons
      expect(find.textContaining('Improved'), findsOneWidget);
      expect(find.textContaining('No change'), findsOneWidget);
      expect(find.textContaining('Got worse'), findsOneWidget);

      // 3. Tap "Improved"
      await tester.tap(find.textContaining('Improved'));
      await tester.pumpAndSettle();

      // 4. Verify API response
      expect(fakeFollowUpRepo.lastFollowUpId, 'fu_treatment_01');
      expect(fakeFollowUpRepo.lastResponseValue, 'improved');

      // 5. Result severity change is displayed
      expect(find.text('Severity: moderate → early'), findsOneWidget);
    });

    testWidgets('Renders empty state when no follow-ups are pending',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      fakeFollowUpRepo.returnEmpty = true;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            followUpRepositoryProvider.overrideWithValue(fakeFollowUpRepo),
            activeFarmIdProvider.overrideWith((ref) => ActiveFarmIdNotifier(null, 'f_nashik_01')),
          ],
          child: const BhoomiApp(homeOverride: FollowupsScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('कोणताही प्रलंबित फॉलो-अप नाही'), findsOneWidget);
      expect(find.text('सर्व उपचार पडताळणी पूर्ण झाली आहे.'), findsOneWidget);
    });
  });
}
