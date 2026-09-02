import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bhoomi/main.dart';
import 'package:bhoomi/widgets/voice_query_sheet.dart';
import 'package:bhoomi/widgets/spoken_summary_player.dart';
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
  group('Voice-First Interaction & Playback Tests (Step 6)', () {
    late FakeVoiceRepo fakeVoiceRepo;

    setUp(() {
      fakeVoiceRepo = FakeVoiceRepo();
    });

    testWidgets('VoiceQuerySheet cycles through IDLE -> LISTENING -> PROCESSING -> RESULT -> PLAYBACK',
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
              body: VoiceQuerySheet(
                onQuerySubmitted: (query) => submittedQuery = query,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1. IDLE State: Large mic button & prompt
      expect(find.text('Bhoomi Voice Assistant'), findsOneWidget);
      expect(find.text('ऐकत आहे... बोला'), findsOneWidget);
      expect(find.byIcon(Icons.mic_rounded), findsWidgets);

      // 2. Tap Mic to Start LISTENING
      await tester.tap(find.byIcon(Icons.mic_rounded).last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('थांबवा'), findsOneWidget);

      // 3. Tap Stop to finish listening & trigger PROCESSING -> RESULT
      await tester.tap(find.text('थांबवा'));
      await tester.pump();
      await tester.pumpAndSettle();

      // 4. RESULT State: Transcription displayed in editable field
      expect(find.text('तुमचा प्रश्न'), findsOneWidget);
      expect(find.text('पानांवर करडे ठिपके दिसत आहेत, काय उपाय करावा?'), findsOneWidget);
      expect(find.text('विचारणा करा'), findsOneWidget);

      // 5. Test Listen audio preview button
      expect(find.text('सल्ला ऐका (Listen)'), findsOneWidget);
      await tester.tap(find.text('सल्ला ऐका (Listen)'));
      await tester.pumpAndSettle();

      expect(find.text('सल्ला ऐकत आहात'), findsOneWidget);

      // 6. Submit Query
      await tester.tap(find.text('विचारणा करा'));
      await tester.pumpAndSettle();
      expect(submittedQuery, 'पानांवर करडे ठिपके दिसत आहेत, काय उपाय करावा?');
    });

    testWidgets('SpokenSummaryPlayer toggles on-demand playback with wave indicator and no auto-start',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      bool playCallbackCalled = false;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            voiceRepositoryProvider.overrideWithValue(fakeVoiceRepo),
          ],
          child: BhoomiApp(
            homeOverride: Scaffold(
              body: Center(
                child: SpokenSummaryPlayer(
                  text: 'Do not apply nitrogen fertilizer. Drain field water for 48 hours.',
                  title: 'सल्ला ऐका (Listen to Advisory)',
                  onPlayAudio: () {
                    playCallbackCalled = true;
                  },
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Initial state: not auto-playing
      expect(find.text('सल्ला ऐका (Listen to Advisory)'), findsOneWidget);
      expect(playCallbackCalled, isFalse);

      // Tap Play
      await tester.tap(find.byIcon(Icons.volume_up_rounded));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(playCallbackCalled, isTrue);

      // Tap Pause
      await tester.tap(find.byIcon(Icons.pause_rounded));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.replay_rounded), findsOneWidget);
    });
  });
}
