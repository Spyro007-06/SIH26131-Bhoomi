import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bhoomi/main.dart';
import 'package:bhoomi/widgets/farmer_voice_assistant.dart';
import 'package:bhoomi/repositories/voice_repository.dart';
import 'package:bhoomi/models/voice_models.dart';
import 'package:bhoomi/providers/repository_providers.dart';
import 'package:bhoomi/core/localization/locale_provider.dart';
import 'package:bhoomi/core/localization/app_strings.dart';

class FakeVoiceRepo extends VoiceRepository {
  @override
  Future<VoiceTranscribeResult> transcribe({
    required String assetId,
    String lang = 'mr-IN',
    String? context,
  }) async {
    return const VoiceTranscribeResult(
      text: 'पानांवर करडे ठिपके दिसत आहेत, काय उपाय करावा?',
      confidence: 0.94,
      lang: 'mr-IN',
    );
  }

  @override
  Future<VoiceSynthesizeResult> synthesize({
    required String text,
    String lang = 'mr-IN',
  }) async {
    return const VoiceSynthesizeResult(
      audioUrl: 'https://bhoomi-s3.gov.in/voice/sample_advisory.mp3',
      expiresIn: 600,
    );
  }
}

void main() {
  group('FarmerVoiceAssistant Core Lifecycle & UI/UX Tests (Phase 2)', () {
    late FakeVoiceRepo fakeVoiceRepo;

    setUp(() {
      fakeVoiceRepo = FakeVoiceRepo();
    });

    testWidgets('FarmerVoiceAssistant cycles through full natural flow: IDLE -> LISTENING -> PROCESSING -> RESULT -> PLAYBACK -> ASK AGAIN',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      String? submittedQuery;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            voiceRepositoryProvider.overrideWithValue(fakeVoiceRepo),
          ],
          child: BhoomiApp(
            homeOverride: Scaffold(
              body: FarmerVoiceAssistant(
                onQuerySubmitted: (query) => submittedQuery = query,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1. IDLE State: Large mic button, title, subtitle, CTA
      expect(find.text('Bhoomi Voice Assistant'), findsOneWidget);
      expect(find.text('बोलून विचारा'), findsOneWidget);
      expect(find.text('तुमच्या पिकाबद्दल काहीही विचारा'), findsOneWidget);
      expect(find.text('बोलायला सुरुवात करा'), findsOneWidget);
      expect(find.byIcon(Icons.mic_rounded), findsWidgets);

      // 2. Tap CTA to Start LISTENING
      await tester.tap(find.text('बोलायला सुरुवात करा'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('थांबवा'), findsOneWidget);
      expect(find.text('रद्द करा'), findsOneWidget);

      // 3. Tap Stop to finish recording & trigger PROCESSING -> RESULT
      await tester.tap(find.text('थांबवा'));
      await tester.pump();
      await tester.pumpAndSettle();

      // 4. RESULT State: Transcript & Bhoomi Answer
      expect(find.text('तुमचा प्रश्न'), findsOneWidget);
      expect(find.text('पानांवर करडे ठिपके दिसत आहेत, काय उपाय करावा?'), findsOneWidget);
      expect(find.text('Bhoomi चे उत्तर'), findsOneWidget);
      expect(find.text('सल्ला ऐका (Listen)'), findsOneWidget);
      expect(find.text('आणखी विचारा'), findsOneWidget);
      expect(find.text('विचारणा करा'), findsOneWidget);

      // 5. Test Listen audio playback
      await tester.tap(find.text('सल्ला ऐका (Listen)'));
      await tester.pumpAndSettle();

      expect(find.text('सल्ला ऐकत आहात'), findsOneWidget);

      // 6. Test Ask Again (Returns to listening)
      await tester.tap(find.text('आणखी विचारा'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('थांबवा'), findsOneWidget);

      // 7. Stop and Submit Query
      await tester.tap(find.text('थांबवा'));
      await tester.pump();
      await tester.pumpAndSettle();

      await tester.tap(find.text('विचारणा करा'));
      await tester.pumpAndSettle();
      expect(submittedQuery, 'पानांवर करडे ठिपके दिसत आहेत, काय उपाय करावा?');
    });

    testWidgets('FarmerVoiceAssistant cancels listening and returns cleanly to IDLE',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            voiceRepositoryProvider.overrideWithValue(fakeVoiceRepo),
          ],
          child: const BhoomiApp(
            homeOverride: Scaffold(
              body: FarmerVoiceAssistant(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Start listening
      await tester.tap(find.text('बोलायला सुरुवात करा'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('थांबवा'), findsOneWidget);

      // Tap Cancel (रद्द करा)
      await tester.tap(find.text('रद्द करा'));
      await tester.pumpAndSettle();

      // Back to IDLE state
      expect(find.text('बोलायला सुरुवात करा'), findsOneWidget);
      expect(find.text('बोलून विचारा'), findsOneWidget);
    });

    testWidgets('FarmerVoiceAssistant Multilingual Verification (Marathi, Hindi, English)',
        (WidgetTester tester) async {
      for (final lang in AppLanguage.values) {
        final notifier = LocaleNotifier(null);
        notifier.state = lang;

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              appLanguageProvider.overrideWith((ref) => notifier),
              voiceRepositoryProvider.overrideWithValue(fakeVoiceRepo),
            ],
            child: const BhoomiApp(
              homeOverride: Scaffold(
                body: FarmerVoiceAssistant(),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(FarmerVoiceAssistant), findsOneWidget);
        expect(find.byIcon(Icons.mic_rounded), findsWidgets);
      }
    });

    testWidgets('FarmerVoiceAssistant Responsive & Dynamic Text Scaling Audit (1.0x, 1.5x, 2.0x)',
        (WidgetTester tester) async {
      for (final textScale in [1.0, 1.5, 2.0]) {
        tester.view.physicalSize = const Size(360, 640) * 2.0; // Compact Android
        tester.view.devicePixelRatio = 2.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              voiceRepositoryProvider.overrideWithValue(fakeVoiceRepo),
            ],
            child: MediaQuery(
              data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
              child: const BhoomiApp(
                homeOverride: Scaffold(
                  body: FarmerVoiceAssistant(),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.byType(FarmerVoiceAssistant), findsOneWidget);
      }
    });
  });
}
