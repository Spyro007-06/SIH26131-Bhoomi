import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bhoomi/main.dart';
import 'package:bhoomi/models/diagnosis_models.dart';
import 'package:bhoomi/models/advisory_models.dart';
import 'package:bhoomi/models/gate_models.dart';
import 'package:bhoomi/widgets/stub_banner.dart';
import 'package:bhoomi/features/diagnose/presentation/advisory_result_screen.dart';
import 'package:bhoomi/features/doubt_doctor/presentation/doubt_doctor_screen.dart';
import 'package:bhoomi/features/diagnose/presentation/escalation_status_screen.dart';

void main() {
  group('Confidence Gate Outcome Routing & Safety Tests (Step 4)', () {
    testWidgets('Advise outcome renders diagnosis, StubBanner, and IPM ladder with chemical collapsed',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      const adviseResponse = DiagnoseResponse(
        gate: GateDecision(
          outcome: 'advise',
          confidence: 0.89,
          thresholdApplied: 0.70,
          reasonCode: 'ABOVE_GATE',
          alternatives: [
            Prediction(label: 'blast', confidence: 0.89),
            Prediction(label: 'brown_spot', confidence: 0.08),
          ],
          isStub: true, // Stub mode enabled
        ),
        problemId: 'p_101',
        problemType: 'disease',
        diagnosis: DiagnosisDetail(
          label: 'blast',
          severity: 'early',
          confidence: 0.89,
        ),
        advisory: AdvisoryModel(
          possibleIssue: 'Early Paddy Blast (भातावरील करपा)',
          whatToAvoid: 'Do not apply urea nitrogen fertilizer now.',
          whatToCheck: 'Check upper leaves for diamond shaped lesions.',
          ladder: [
            LadderRungModel(tier: 'cultural', action: 'Drain field for 48 hours.'),
            LadderRungModel(tier: 'biological', action: 'Apply Pseudomonas foliar spray.'),
            LadderRungModel(
              tier: 'chemical',
              action: 'Tricyclazole 75 WP',
              dosage: '0.6 g per litre',
              phiDays: 30,
              reentryHours: 24,
            ),
          ],
        ),
        citations: [
          CitationModel(docId: 'c_1', title: 'ICAR Rice PoP', reviewedOn: '2025-11-01'),
        ],
        spokenSummary: 'करपा रोगाची लक्षणे आढळली आहेत.',
      );

      await tester.pumpWidget(
        const ProviderScope(
          child: BhoomiApp(
            homeOverride: AdvisoryResultScreen(response: adviseResponse),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Verify StubBanner is prominently rendered
      expect(find.byType(StubBanner), findsOneWidget);
      expect(find.textContaining('Demonstration Mode'), findsOneWidget);

      // 2. Verify Diagnosis label & High confidence
      expect(find.text('BLAST'), findsOneWidget);
      expect(find.text('उच्च अचूकता (High Confidence)'), findsOneWidget);

      // 3. Verify WHAT TO AVOID is displayed
      expect(find.text('Do not apply urea nitrogen fertilizer now.'), findsOneWidget);

      // 4. Verify Chemical details are COLLAPSED by default
      expect(find.textContaining('0.6 g per litre'), findsNothing);
      expect(find.text('Chemical Action (रासायनिक फवारणी)'), findsOneWidget);

      // 5. Tap to expand chemical details
      await tester.tap(find.text('Chemical Action (रासायनिक फवारणी)'));
      await tester.pumpAndSettle();
      expect(find.textContaining('0.6 g per litre'), findsOneWidget);

      // 6. Safety invariant check: No endorsement language exists on screen
      const forbiddenWords = ['safe', 'approved', 'you can use', 'recommended'];
      final bodyText = find.byType(Text);
      for (final widget in tester.widgetList<Text>(bodyText)) {
        final text = (widget.data ?? '').toLowerCase();
        for (final word in forbiddenWords) {
          expect(text.contains(word), isFalse,
              reason: 'Forbidden endorsement word "$word" found in UI: "$text"');
        }
      }
    });

    testWidgets('Clarify outcome renders DoubtDoctorScreen',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      const clarifyResponse = DiagnoseResponse(
        gate: GateDecision(
          outcome: 'clarify',
          confidence: 0.58,
          thresholdApplied: 0.15,
          reasonCode: 'AMBIGUOUS',
          alternatives: [
            Prediction(label: 'blast', confidence: 0.58),
            Prediction(label: 'brown_spot', confidence: 0.50),
          ],
          isStub: false,
        ),
        problemId: 'p_101',
        clarification: ClarificationModel(
          cueId: 'cue_4',
          question: 'Flip the leaf over. Do you see fuzzy grey growth?',
          questionLocalized: 'पान उलटून पहा. करडी बुरशी दिसते का?',
          candidates: [
            CandidateModel(label: 'blast', signature: 'Diamond lesions with grey centre'),
            CandidateModel(label: 'brown_spot', signature: 'Round spots with yellow halo'),
          ],
          answers: ['yes', 'no', 'unknown'],
        ),
      );

      await tester.pumpWidget(
        const ProviderScope(
          child: BhoomiApp(
            homeOverride: DoubtDoctorScreen(response: clarifyResponse),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(DoubtDoctorScreen), findsOneWidget);
      expect(find.text('थोडी अधिक माहिती हवी आहे'), findsOneWidget);
      expect(find.text('पान उलटून पहा. करडी बुरशी दिसते का?'), findsOneWidget);
    });

    testWidgets('Escalate outcome renders EscalationStatusScreen with case details',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      const escalateResponse = DiagnoseResponse(
        gate: GateDecision(
          outcome: 'escalate',
          confidence: 0.31,
          thresholdApplied: 0.45,
          reasonCode: 'BELOW_FLOOR',
          alternatives: [
            Prediction(label: 'blast', confidence: 0.31),
          ],
          isStub: true,
        ),
        problemId: 'p_101',
        escalation: EscalationModel(
          caseId: 'CASE-2026-NASHIK-99',
          assignedTo: 'KVK Nashik Agronomy Cell',
          queuePosition: 2,
          etaMinutes: 45,
        ),
        spokenSummary: 'तज्ञांकडे पाठवले आहे.',
      );

      await tester.pumpWidget(
        const ProviderScope(
          child: BhoomiApp(
            homeOverride: EscalationStatusScreen(response: escalateResponse),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(EscalationStatusScreen), findsOneWidget);
      expect(find.text('तज्ञांकडे वर्ग केले (Escalated)'), findsWidgets);
      expect(find.text('CASE-2026-NASHIK-99'), findsOneWidget);
      expect(find.text('KVK Nashik Agronomy Cell'), findsOneWidget);
      expect(find.text('2 (लवकरच संपर्क होईल)'), findsOneWidget);
      expect(find.text('45 मिनिटे (Minutes)'), findsOneWidget);
    });
  });
}
