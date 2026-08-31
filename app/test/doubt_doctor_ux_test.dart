import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bhoomi/main.dart';
import 'package:bhoomi/models/diagnosis_models.dart';
import 'package:bhoomi/models/gate_models.dart';
import 'package:bhoomi/models/advisory_models.dart';
import 'package:bhoomi/repositories/doubt_doctor_repository.dart';
import 'package:bhoomi/providers/repository_providers.dart';
import 'package:bhoomi/features/doubt_doctor/presentation/doubt_doctor_screen.dart';
import 'package:bhoomi/features/diagnose/presentation/advisory_result_screen.dart';
import 'package:bhoomi/features/diagnose/presentation/escalation_status_screen.dart';

class FakeDoubtDoctorRepository extends DoubtDoctorRepository {
  bool shouldResolve = true;
  String? lastSubmittedAnswer;
  String? lastSubmittedCueId;

  @override
  Future<DoubtDoctorAnswerResult> submitAnswer({
    required String problemId,
    required String cueId,
    required String answer,
  }) async {
    lastSubmittedCueId = cueId;
    lastSubmittedAnswer = answer;

    if (shouldResolve) {
      return const DoubtDoctorAnswerResult(
        resolved: true,
        observationId: 'obs_999',
        diagnosis: DiagnosisDetail(
          label: 'blast',
          severity: 'early',
          confidence: 0.92,
        ),
        advisory: AdvisoryModel(
          possibleIssue: 'Confirmed Paddy Blast',
          whatToAvoid: 'Do not top-dress urea.',
          whatToCheck: 'Diamond shaped grey spots.',
          ladder: [],
        ),
        spokenSummary: 'करपा रोगाचे अचूक निदान झाले.',
      );
    } else {
      return const DoubtDoctorAnswerResult(
        resolved: false,
        reason: 'answer_did_not_discriminate',
        observationId: 'obs_999',
        escalation: EscalationModel(
          caseId: 'CASE-EXP-001',
          assignedTo: 'KVK Agronomist',
          queuePosition: 1,
          etaMinutes: 20,
        ),
        spokenSummary: 'तज्ञांकडे केस वर्ग केली आहे.',
      );
    }
  }
}

void main() {
  group('Doubt Doctor Visual Differential Diagnosis UX Tests (Step 4)', () {
    late FakeDoubtDoctorRepository fakeDoubtDoctorRepo;

    const sampleClarifyResponse = DiagnoseResponse(
      gate: GateDecision(
        outcome: 'clarify',
        confidence: 0.55,
        thresholdApplied: 0.15,
        reasonCode: 'AMBIGUOUS',
        alternatives: [
          Prediction(label: 'blast', confidence: 0.55),
          Prediction(label: 'brown_spot', confidence: 0.50),
        ],
        isStub: false,
      ),
      problemId: 'p_prob_77',
      clarification: ClarificationModel(
        cueId: 'cue_leaf_underside_4',
        question: 'Do you see grey mold on underside?',
        questionLocalized: 'पानाच्या मागील बाजूस करडी बुरशी दिसते का?',
        candidates: [
          CandidateModel(label: 'blast', signature: 'Diamond lesions with grey centre'),
          CandidateModel(label: 'brown_spot', signature: 'Round spots with yellow halo'),
        ],
        answers: ['yes', 'no', 'unknown'],
      ),
    );

    setUp(() {
      fakeDoubtDoctorRepo = FakeDoubtDoctorRepository();
    });

    testWidgets('Renders 2 visual candidate cards, localized question, and 3 tactile answer buttons',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            doubtDoctorRepositoryProvider.overrideWithValue(fakeDoubtDoctorRepo),
          ],
          child: const BhoomiApp(
            homeOverride: DoubtDoctorScreen(response: sampleClarifyResponse),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Verify Header & Subtitle
      expect(find.text('थोडी अधिक माहिती हवी आहे'), findsOneWidget);

      // 2. Verify Candidate Cards
      expect(find.text('BLAST'), findsOneWidget);
      expect(find.text('BROWN SPOT'), findsOneWidget);
      expect(find.text('Diamond lesions with grey centre'), findsOneWidget);
      expect(find.text('Round spots with yellow halo'), findsOneWidget);

      // 3. Verify Localized Question
      expect(find.text('पानाच्या मागील बाजूस करडी बुरशी दिसते का?'), findsOneWidget);

      // 4. Verify 3 Tactile Buttons
      expect(find.text('होय (YES)'), findsOneWidget);
      expect(find.text('नाही (NO)'), findsOneWidget);
      expect(find.text("सांगता येत नाही (CAN'T TELL)"), findsOneWidget);
    });

    testWidgets('Tapping YES with resolved response routes to AdvisoryResultScreen',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      fakeDoubtDoctorRepo.shouldResolve = true;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            doubtDoctorRepositoryProvider.overrideWithValue(fakeDoubtDoctorRepo),
          ],
          child: const BhoomiApp(
            homeOverride: DoubtDoctorScreen(response: sampleClarifyResponse),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap YES
      await tester.tap(find.text('होय (YES)'));
      await tester.pumpAndSettle();

      // Verify answer was submitted to API with correct contract parameters
      expect(fakeDoubtDoctorRepo.lastSubmittedCueId, 'cue_leaf_underside_4');
      expect(fakeDoubtDoctorRepo.lastSubmittedAnswer, 'yes');

      // Resolved outcome rendered AdvisoryResultScreen
      expect(find.byType(AdvisoryResultScreen), findsOneWidget);
    });

    testWidgets('Tapping CANNOT TELL with unresolved response routes to EscalationStatusScreen',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      fakeDoubtDoctorRepo.shouldResolve = false;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            doubtDoctorRepositoryProvider.overrideWithValue(fakeDoubtDoctorRepo),
          ],
          child: const BhoomiApp(
            homeOverride: DoubtDoctorScreen(response: sampleClarifyResponse),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap CAN'T TELL
      await tester.tap(find.text("सांगता येत नाही (CAN'T TELL)"));
      await tester.pumpAndSettle();

      // Verify answer was submitted as 'unknown'
      expect(fakeDoubtDoctorRepo.lastSubmittedAnswer, 'unknown');

      // Unresolved outcome rendered EscalationStatusScreen
      expect(find.byType(EscalationStatusScreen), findsOneWidget);
      expect(find.text('CASE-EXP-001'), findsOneWidget);
    });
  });
}
