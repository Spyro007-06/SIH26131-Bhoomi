import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bhoomi/main.dart';
import 'package:bhoomi/core/localization/locale_provider.dart';
import 'package:bhoomi/core/localization/app_strings.dart';
import 'package:bhoomi/features/diagnose/presentation/camera_capture_screen.dart';
import 'package:bhoomi/widgets/farmer_voice_assistant.dart';
import 'package:bhoomi/repositories/voice_repository.dart';
import 'package:bhoomi/models/voice_models.dart';
import 'package:bhoomi/providers/repository_providers.dart';

class PolishVoiceRepo extends VoiceRepository {
  bool shouldFailTranscribe = false;

  @override
  Future<VoiceTranscribeResult> transcribe({
    required String assetId,
    String lang = 'mr-IN',
    String? context,
  }) async {
    if (shouldFailTranscribe) {
      throw Exception('Voice recognition failure');
    }
    return const VoiceTranscribeResult(
      text: 'उपाययोजना काय करावी?',
      confidence: 0.95,
      lang: 'mr-IN',
    );
  }

  @override
  Future<VoiceSynthesizeResult> synthesize({
    required String text,
    String lang = 'mr-IN',
  }) async {
    return const VoiceSynthesizeResult(
      audioUrl: 'https://bhoomi-s3.gov.in/voice/polished.mp3',
      expiresIn: 600,
    );
  }
}

void main() {
  group('Phase 5: Real-World Usability & Interaction Polish Tests', () {
    late PolishVoiceRepo polishVoiceRepo;

    setUp(() {
      polishVoiceRepo = PolishVoiceRepo();
    });

    testWidgets('Camera Screen renders localized framing guide without hardcoded text',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          child: const BhoomiApp(
            homeOverride: CameraCaptureScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('पाने किंवा बाधित भाग चौकटीत ठेवा'), findsOneWidget);
      expect(find.byIcon(Icons.eco_rounded), findsOneWidget);
    });

    testWidgets('Voice Assistant error recovery allows immediate retry to listening',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      polishVoiceRepo.shouldFailTranscribe = true;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            voiceRepositoryProvider.overrideWithValue(polishVoiceRepo),
          ],
          child: const BhoomiApp(
            homeOverride: Scaffold(
              body: FarmerVoiceAssistant(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Start speaking -> Stop -> Triggers error state
      await tester.tap(find.text('बोलायला सुरुवात करा'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.text('थांबवा'));
      await tester.pump();
      await tester.pumpAndSettle();

      // Error view rendered
      expect(find.text('पुन्हा बोला'), findsOneWidget);

      // Tap Retry -> Immediately goes back to listening state
      polishVoiceRepo.shouldFailTranscribe = false;
      await tester.tap(find.text('पुन्हा बोला'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('ऐकत आहे... बोला'), findsOneWidget);
    });

    testWidgets('Multilingual Verification for Camera and Voice Polish (Marathi, Hindi, English)',
        (WidgetTester tester) async {
      for (final lang in AppLanguage.values) {
        final notifier = LocaleNotifier(null);
        notifier.state = lang;

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              appLanguageProvider.overrideWith((ref) => notifier),
              voiceRepositoryProvider.overrideWithValue(polishVoiceRepo),
            ],
            child: const BhoomiApp(
              homeOverride: CameraCaptureScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(CameraCaptureScreen), findsOneWidget);
      }
    });

    testWidgets('Dynamic Text Scaling at 1.0x, 1.5x, 2.0x on Camera Capture Screen',
        (WidgetTester tester) async {
      for (final textScale in [1.0, 1.5, 2.0]) {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: TextScaler.linear(textScale),
                ),
                child: child!,
              ),
              home: const CameraCaptureScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.byType(CameraCaptureScreen), findsOneWidget);
      }
    });
  });
}
