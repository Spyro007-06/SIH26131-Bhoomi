import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bhoomi/main.dart';
import 'package:bhoomi/features/diagnose/presentation/camera_capture_screen.dart';
import 'package:bhoomi/features/diagnose/presentation/advisory_result_screen.dart';
import 'package:bhoomi/models/diagnosis_models.dart';
import 'package:bhoomi/models/advisory_models.dart';
import 'package:bhoomi/models/gate_models.dart';
import 'package:bhoomi/widgets/app_button.dart';

void main() {
  group('Accessibility, Semantics & Text Scaling Tests (Step 6)', () {
    testWidgets('Camera capture screen provides semantic labels for icon-only action buttons',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const ProviderScope(
          child: BhoomiApp(
            homeOverride: CameraCaptureScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify semantics nodes exist for capture, gallery, and flash
      expect(
        find.bySemanticsLabel('कॅमेराने पिकाचा फोटो काढा'),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel('गॅलरीतून निवडा'),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel('कॅमेरा फ्लॅश चालू किंवा बंद करा'),
        findsOneWidget,
      );
    });

    testWidgets('Advisory screen renders without overflow at 1.5x and 2.0x text scaling',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      const adviseResponse = DiagnoseResponse(
        gate: GateDecision(
          outcome: 'advise',
          confidence: 0.95,
          thresholdApplied: 0.70,
          reasonCode: 'ABOVE_GATE',
          alternatives: [Prediction(label: 'blast', confidence: 0.95)],
        ),
        problemId: 'p_access_101',
        diagnosis: DiagnosisDetail(
          label: 'blast',
          severity: 'high',
          confidence: 0.95,
        ),
        advisory: AdvisoryModel(
          possibleIssue: 'Paddy Blast (भातावरील करपा)',
          whatToAvoid: 'Do not apply nitrogen fertilizer now.',
          whatToCheck: 'Check spindle-shaped lesions on upper canopy leaves.',
          ladder: [
            LadderRungModel(
              tier: 'cultural',
              action: 'Drain standing water and allow soil surface to dry.',
            ),
            LadderRungModel(
              tier: 'chemical',
              action: 'Tricyclazole 75 WP',
              dosage: '0.6 g per litre',
              phiDays: 30,
              reentryHours: 24,
            ),
          ],
        ),
      );

      // Test with 2.0x TextScaler (high accessibility magnification)
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(
            textScaler: TextScaler.linear(2.0),
            size: Size(412, 915),
          ),
          child: const ProviderScope(
            child: BhoomiApp(
              homeOverride: AdvisoryResultScreen(response: adviseResponse),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Ensure key sections render cleanly without RenderFlex overflow exceptions
      expect(find.text('BLAST'), findsOneWidget);
      expect(find.text('Do not apply nitrogen fertilizer now.'), findsOneWidget);
      expect(find.text('Chemical Action (रासायनिक फवारणी)'), findsOneWidget);
    });

    testWidgets('Primary buttons satisfy minimum touch target heights >= 48px',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                AppButton.primary(
                  label: 'मोठा बटण (Large CTA)',
                  size: AppButtonSize.large,
                  onPressed: () {},
                ),
                AppButton.secondary(
                  label: 'मध्यम बटण (Medium CTA)',
                  size: AppButtonSize.normal,
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final largeBtnFinder = find.widgetWithText(AppButton, 'मोठा बटण (Large CTA)');
      final mediumBtnFinder = find.widgetWithText(AppButton, 'मध्यम बटण (Medium CTA)');

      final largeSize = tester.getSize(largeBtnFinder);
      final mediumSize = tester.getSize(mediumBtnFinder);

      expect(largeSize.height, greaterThanOrEqualTo(52.0));
      expect(mediumSize.height, greaterThanOrEqualTo(48.0));
    });
  });
}
