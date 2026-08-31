import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bhoomi/core/theme/app_theme.dart';
import 'package:bhoomi/widgets/farm_health_card.dart';
import 'package:bhoomi/widgets/risk_card.dart';
import 'package:bhoomi/widgets/stub_banner.dart';
import 'package:bhoomi/widgets/voice_action_button.dart';
import 'package:bhoomi/widgets/advisory_ipm_card.dart';
import 'package:bhoomi/widgets/pesticide_veto_card.dart';
import 'package:bhoomi/widgets/app_text_field.dart';
import 'package:bhoomi/features/showcase/design_showcase_screen.dart';

void main() {
  group('Design Showcase Screen & Reusable Components Tests', () {
    testWidgets('Renders all 11 required design elements without error',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const DesignShowcaseScreen(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // 1. Check Stub Banner
      expect(find.byType(StubBanner), findsOneWidget);
      expect(find.text('DEMONSTRATION MODE'), findsOneWidget);

      // 2. Check Action Buttons
      expect(find.text('1. Primary Button (मुख्य बटण)'), findsOneWidget);
      expect(find.text('2. Secondary Button (दुय्यम बटण)'), findsOneWidget);
      expect(find.text('3. Danger Button (धोका / थांबवा)'), findsOneWidget);

      // 3. Check Input Field
      expect(find.byType(AppTextField), findsOneWidget);
      expect(find.text('Observed Crop Symptoms (पिकावरील लक्षणे)'), findsOneWidget);

      // 4. Check Voice Action Button
      await tester.scrollUntilVisible(find.byType(VoiceActionButton), 300, scrollable: find.byType(Scrollable).first);
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(VoiceActionButton), findsOneWidget);

      // 5. Check Farm Health Card
      await tester.scrollUntilVisible(find.byType(FarmHealthCard), 300, scrollable: find.byType(Scrollable).first);
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(FarmHealthCard), findsOneWidget);
      expect(find.text('FIELD HEALTH STATUS'), findsOneWidget);
      expect(find.text('One open problem, being monitored.'), findsOneWidget);

      // 6. Check Risk Alert Card
      await tester.scrollUntilVisible(find.byType(RiskCard), 300, scrollable: find.byType(Scrollable).first);
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(RiskCard), findsOneWidget);
      expect(find.text('HIGH RISK'), findsOneWidget);
      expect(find.text('GO LOOK (शेतात काय तपासावे):'), findsOneWidget);
      expect(find.text("I'LL CHECK (मी तपासतो)"), findsOneWidget);

      // 7. Check Confidence Gate Card (starts on Advise)
      await tester.scrollUntilVisible(find.text('CONFIDENT DIAGNOSIS'), 300, scrollable: find.byType(Scrollable).first);
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('CONFIDENT DIAGNOSIS'), findsOneWidget);
      expect(find.text('Paddy Blast (भातावरील करपा)'), findsWidgets);

      // 8. Check Advisory IPM Card
      await tester.scrollUntilVisible(find.byType(AdvisoryIpmCard), 300, scrollable: find.byType(Scrollable).first);
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(AdvisoryIpmCard), findsOneWidget);
      expect(find.text('WHAT TO AVOID FIRST (हे अजिबात करू नका):'), findsOneWidget);
      expect(find.text('Cultural Action (मशागतीय / जैविक उपाय)'), findsOneWidget);
      expect(find.text('Biological Action (जैविक नियंत्रण)'), findsOneWidget);
      expect(find.text('Chemical Action (रासायनिक फवारणी)'), findsOneWidget);

      // 9. Check Pesticide Veto Card
      await tester.scrollUntilVisible(find.byType(PesticideVetoCard), 300, scrollable: find.byType(Scrollable).first);
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(PesticideVetoCard), findsOneWidget);
      expect(find.text('DO NOT SPRAY — VETO VERDICT'), findsOneWidget);
      expect(find.text('This is a fungicide. Your problem is an insect pest.'), findsOneWidget);
    });

    testWidgets('Voice button cycles through states correctly',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const DesignShowcaseScreen(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.scrollUntilVisible(find.byType(VoiceActionButton), 300, scrollable: find.byType(Scrollable).first);
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Tap to Speak (बोलण्यासाठी टॅप करा)'), findsOneWidget);

      // Tap to start listening
      await tester.tap(find.byType(VoiceActionButton));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Listening... Tap to stop (ऐकत आहे...)'), findsOneWidget);

      // Tap to stop listening -> transcribing
      await tester.tap(find.byType(VoiceActionButton));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Transcribing speech... (प्रक्रिया करत आहे...)'), findsOneWidget);

      // Tap -> playback
      await tester.tap(find.byType(VoiceActionButton));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Playing audio summary (आवाज सुरू आहे)'), findsOneWidget);
    });

    testWidgets('Confidence gate tab switcher toggles between Advise, Clarify, and Escalate',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const DesignShowcaseScreen(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Scroll down to Confidence Gate header
      await tester.scrollUntilVisible(find.text('7. Confidence Gate UI (3 Bands)'), 300, scrollable: find.byType(Scrollable).first);
      await tester.pump(const Duration(milliseconds: 300));

      // Initial state is Advise
      expect(find.text('CONFIDENT DIAGNOSIS'), findsOneWidget);

      // Switch to Clarify (Doubt Doctor)
      await tester.tap(find.text('Clarify'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('ONE OBSERVATION NEEDED'), findsOneWidget);
      expect(find.text('YES (होय)'), findsOneWidget);
      expect(find.text('NO (नाही)'), findsOneWidget);
      expect(find.text("CAN'T TELL"), findsOneWidget);

      // Switch to Escalate
      await tester.tap(find.text('Escalate'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('EXPERT REVIEW NEEDED'), findsOneWidget);
      expect(find.text('Call Kisan Helpline (कॉल करा)'), findsOneWidget);
    });

    testWidgets('Chemical action in Advisory IPM card expands and collapses',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const DesignShowcaseScreen(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Scroll to Advisory IPM Card
      await tester.scrollUntilVisible(find.byType(AdvisoryIpmCard), 300, scrollable: find.byType(Scrollable).first);
      await tester.pump(const Duration(milliseconds: 300));

      // Chemical details (dosage) should be collapsed initially
      expect(find.text('Dosage (प्रमाण):'), findsNothing);

      // Tap chemical section to expand
      await tester.tap(find.text('Chemical Action (रासायनिक फवारणी)'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Dosage (प्रमाण):'), findsOneWidget);
      expect(find.text('0.6 g per litre of water'), findsOneWidget);
    });
  });
}
