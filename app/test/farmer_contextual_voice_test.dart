import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bhoomi/main.dart';
import 'package:bhoomi/core/localization/locale_provider.dart';
import 'package:bhoomi/core/localization/app_strings.dart';
import 'package:bhoomi/widgets/farmer_contextual_voice_action.dart';
import 'package:bhoomi/widgets/farmer_voice_assistant.dart';
import 'package:bhoomi/widgets/followup_card.dart';
import 'package:bhoomi/repositories/voice_repository.dart';
import 'package:bhoomi/models/voice_models.dart';
import 'package:bhoomi/providers/repository_providers.dart';

class FakeVoiceRepo extends VoiceRepository {
  @override
  Future<VoiceTranscribeResult> transcribe({
    required String assetId,
    String lang = 'mr-IN',
    String? context,
  }) async {
    return const VoiceTranscribeResult(
      text: 'उपचारानंतर पिकात चांगली सुधारणा झाली आहे',
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
      audioUrl: 'https://bhoomi-s3.gov.in/voice/sample_advisory.mp3',
      expiresIn: 600,
    );
  }
}

void main() {
  group('FarmerContextualVoiceAction & Phase 3 Contextual Integration Tests', () {
    late FakeVoiceRepo fakeVoiceRepo;

    setUp(() {
      fakeVoiceRepo = FakeVoiceRepo();
    });

    testWidgets('FarmerContextualVoiceAction opens assistant with contextual topic badge',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            voiceRepositoryProvider.overrideWithValue(fakeVoiceRepo),
          ],
          child: BhoomiApp(
            homeOverride: Scaffold(
              body: Center(
                child: FarmerContextualVoiceAction.outline(
                  label: 'या समस्येबद्दल विचारा',
                  contextTopic: 'Paddy Blast',
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('या समस्येबद्दल विचारा'), findsOneWidget);

      // Tap contextual voice button
      await tester.tap(find.text('या समस्येबद्दल विचारा'));
      await tester.pumpAndSettle();

      // Assistant opens with context topic badge
      expect(find.byType(FarmerVoiceAssistant), findsOneWidget);
      expect(find.text('विषय: Paddy Blast'), findsOneWidget);
    });

    testWidgets('FollowUpCard integrates contextual voice action and maps spoken feedback',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      String? recordedOutcome;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            voiceRepositoryProvider.overrideWithValue(fakeVoiceRepo),
          ],
          child: BhoomiApp(
            homeOverride: Scaffold(
              body: Center(
                child: FollowUpCard(
                  target: 'Paddy Blast Treatment',
                  onResponse: (outcome) => recordedOutcome = outcome,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('बोलून सांगा'), findsOneWidget);

      // Tap Tell Bhoomi
      await tester.tap(find.text('बोलून सांगा'));
      await tester.pumpAndSettle();

      expect(find.byType(FarmerVoiceAssistant), findsOneWidget);
      expect(find.text('विषय: Paddy Blast Treatment Follow-up'), findsOneWidget);

      // Start listening & Stop recording
      await tester.tap(find.text('बोलायला सुरुवात करा'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.text('थांबवा'));
      await tester.pump();
      await tester.pumpAndSettle();

      // Submit recognized transcript
      await tester.tap(find.text('विचारणा करा'));
      await tester.pumpAndSettle();

      expect(recordedOutcome, 'improved');
    });

    testWidgets('Contextual Voice Actions Multilingual Verification (Marathi, Hindi, English)',
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
            child: BhoomiApp(
              homeOverride: Scaffold(
                body: Consumer(
                  builder: (context, ref, _) {
                    final strings = ref.watch(stringsProvider);
                    return Column(
                      children: [
                        FarmerContextualVoiceAction.outline(
                          label: strings.voiceContextDiagnosis,
                          contextTopic: 'Paddy Blast',
                        ),
                        FarmerContextualVoiceAction.outline(
                          label: strings.voiceContextAlertWhy,
                          contextTopic: 'Pest Alert',
                        ),
                        FarmerContextualVoiceAction.primary(
                          label: strings.voiceContextFollowupTell,
                          contextTopic: 'Follow-up',
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(FarmerContextualVoiceAction), findsNWidgets(3));
      }
    });

    testWidgets('Contextual Voice Actions Dynamic Text Scaling (1.0x, 1.5x, 2.0x)',
        (WidgetTester tester) async {
      for (final textScale in [1.0, 1.5, 2.0]) {
        tester.view.physicalSize = const Size(360, 640) * 2.0;
        tester.view.devicePixelRatio = 2.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              voiceRepositoryProvider.overrideWithValue(fakeVoiceRepo),
            ],
            child: MediaQuery(
              data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
              child: BhoomiApp(
                homeOverride: Scaffold(
                  body: Center(
                    child: FarmerContextualVoiceAction.outline(
                      label: 'या समस्येबद्दल विचारा',
                      contextTopic: 'Paddy Blast',
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.byType(FarmerContextualVoiceAction), findsOneWidget);
      }
    });
  });
}
