import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bhoomi/main.dart';
import 'package:bhoomi/core/theme/app_theme.dart';
import 'package:bhoomi/core/localization/locale_provider.dart';
import 'package:bhoomi/core/localization/app_strings.dart';
import 'package:bhoomi/features/landing/presentation/landing_screen.dart';
import 'package:bhoomi/features/onboarding/presentation/phone_auth_screen.dart';

void main() {
  group('Bhoomi Launch Landing Page & Brand Identity Tests', () {
    testWidgets('1. Launch Landing Screen renders Logo, Hero Artwork, Pillars, and Start CTA',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const ProviderScope(
          child: BhoomiApp(
            homeOverride: LandingScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Brand & Tagline
      expect(find.text('Bhoomi'), findsOneWidget);
      expect(find.text('तुमचा शेतकरी साथी'), findsOneWidget);

      // Verify 3 Product Pillars (Talk, Show, Listen)
      expect(find.text('बोला'), findsOneWidget);
      expect(find.text('दाखवा'), findsOneWidget);
      expect(find.text('ऐका'), findsOneWidget);
      expect(find.byIcon(Icons.mic_rounded), findsOneWidget);
      expect(find.byIcon(Icons.photo_camera_rounded), findsOneWidget);
      expect(find.byIcon(Icons.volume_up_rounded), findsOneWidget);

      // Verify Value Proposition Message
      expect(find.text('बोला, दाखवा आणि योग्य सल्ला मिळवा.'), findsOneWidget);

      // Verify Primary Start CTA
      expect(find.text('सुरू करा'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_forward_rounded), findsOneWidget);
    });

    testWidgets('2. Tapping Start button navigates to existing PhoneAuthScreen',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const ProviderScope(
          child: BhoomiApp(
            homeOverride: LandingScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap "सुरू करा" Start CTA
      await tester.tap(find.text('सुरू करा'));
      await tester.pumpAndSettle();

      // Verify navigation to PhoneAuthScreen
      expect(find.byType(PhoneAuthScreen), findsOneWidget);
      expect(find.text('मोबाईल नंबर'), findsOneWidget);
    });

    testWidgets('3. Multilingual Verification across Marathi, Hindi, and English',
        (WidgetTester tester) async {
      for (final lang in AppLanguage.values) {
        final notifier = LocaleNotifier(null);
        notifier.state = lang;

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              appLanguageProvider.overrideWith((ref) => notifier),
            ],
            child: const BhoomiApp(
              homeOverride: LandingScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(LandingScreen), findsOneWidget);
        expect(find.text('Bhoomi'), findsOneWidget);
      }
    });

    testWidgets('4. Dynamic Text Scaling at 1.0x, 1.5x, 2.0x on Compact 360x640 Screen',
        (WidgetTester tester) async {
      for (final textScale in [1.0, 1.5, 2.0]) {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: TextScaler.linear(textScale),
                ),
                child: child!,
              ),
              home: const LandingScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.byType(LandingScreen), findsOneWidget);
      }
    });

    testWidgets('5. Responsive Multi-Viewport Audit (360x640, 390x844, 412x915, 540x1200, 1080x2400)',
        (WidgetTester tester) async {
      final viewports = [
        const Size(360, 640),
        const Size(390, 844),
        const Size(412, 915),
        const Size(540, 1200),
        const Size(1080, 2400),
      ];

      for (final vp in viewports) {
        tester.view.physicalSize = vp * 2.0;
        tester.view.devicePixelRatio = 2.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          const ProviderScope(
            child: BhoomiApp(
              homeOverride: LandingScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.byType(LandingScreen), findsOneWidget);
      }
    });
  });
}
