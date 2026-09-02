import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bhoomi/main.dart';
import 'package:bhoomi/models/problem_models.dart';
import 'package:bhoomi/models/advisory_models.dart';
import 'package:bhoomi/models/diagnosis_models.dart';
import 'package:bhoomi/repositories/problem_repository.dart';
import 'package:bhoomi/providers/repository_providers.dart';
import 'package:bhoomi/features/timeline/presentation/problem_detail_screen.dart';

class FakeProblemRepositoryWithData extends ProblemRepository {
  @override
  Future<ProblemDetailModel> getProblemDetail(String problemId) async {
    return ProblemDetailModel(
      id: 'p_prob_99',
      farmId: 'f_nashik_01',
      crop: 'paddy',
      type: 'disease',
      label: 'blast',
      severity: 'moderate',
      status: 'open',
      openedAt: '2026-08-28T10:00:00Z',
      resolvedAt: null,
      observations: [
        ObservationModel(
          id: 'obs_1',
          problemId: 'p_prob_99',
          question: 'Is underside fuzzy?',
          cueId: 'leaf_underside_mold',
          answer: 'yes',
          createdAt: '2026-08-28T10:05:00Z',
        ),
      ],
      advisory: AdvisoryModel(
        possibleIssue: 'Paddy Blast',
        whatToAvoid: 'Do not apply urea nitrogen fertilizer.',
        whatToCheck: 'Check leaf collars for rot.',
        ladder: [],
      ),
      escalation: EscalationModel(
        caseId: 'CASE-EXP-888',
        assignedTo: 'KVK Agronomist Cell',
        queuePosition: 1,
        etaMinutes: 30,
      ),
    );
  }

  @override
  Future<ProblemsResponse> getProblems({required String farmId, String? status, String? type, int limit = 20, String? cursor}) =>
      throw UnimplementedError();

  @override
  Future<EscalationModel> escalateProblem(String problemId) => throw UnimplementedError();
}

void main() {
  group('Problem Detail Screen Tests (Step 5)', () {
    testWidgets('Renders complete case file with status, observations, advisory, and escalation',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            problemRepositoryProvider.overrideWithValue(FakeProblemRepositoryWithData()),
          ],
          child: const BhoomiApp(
            homeOverride: ProblemDetailScreen(problemId: 'p_prob_99'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Verify Problem title and status
      expect(find.text('BLAST'), findsOneWidget);
      expect(find.text('सक्रिय (Open)'), findsOneWidget);
      expect(find.textContaining('नोंदणी दिनांक: 2026-08-28'), findsOneWidget);

      // 2. Verify Escalation details
      expect(find.text('केस क्रमांक (Case ID): CASE-EXP-888'), findsOneWidget);
      expect(find.text('नियुक्त केंद्र / तज्ञ: KVK Agronomist Cell'), findsOneWidget);

      // 3. Verify Observations list
      expect(find.text('Cue: leaf_underside_mold'), findsOneWidget);
      expect(find.text('Answer: YES'), findsOneWidget);

      // 4. Verify Advisory summary
      expect(find.text('Do not apply urea nitrogen fertilizer.'), findsOneWidget);
    });
  });
}
