import 'dart:async';
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:record/record.dart';
import 'package:bhoomi/main.dart';
import 'package:bhoomi/core/utils/audio_recording_service.dart';
import 'package:bhoomi/core/utils/audio_playback_service.dart';
import 'package:bhoomi/models/asset_models.dart';
import 'package:bhoomi/models/voice_models.dart';
import 'package:bhoomi/repositories/asset_repository.dart';
import 'package:bhoomi/repositories/voice_repository.dart';
import 'package:bhoomi/providers/repository_providers.dart';
import 'package:bhoomi/widgets/farmer_voice_assistant.dart';
import 'package:bhoomi/widgets/spoken_summary_player.dart';

/// Test Fake for [AudioRecorderWrapper].
class FakeAudioRecorderWrapper implements AudioRecorderWrapper {
  bool hasMicPermission = true;
  bool recordingActive = false;
  String? startTargetPath;
  RecordConfig? startConfig;
  int startCallCount = 0;
  int stopCallCount = 0;
  int cancelCallCount = 0;
  int disposeCallCount = 0;

  @override
  Future<bool> hasPermission() async => hasMicPermission;

  @override
  Future<bool> isRecording() async => recordingActive;

  @override
  Future<void> start(RecordConfig config, {required String path}) async {
    startConfig = config;
    startTargetPath = path;
    recordingActive = true;
    startCallCount++;
  }

  @override
  Future<String?> stop() async {
    recordingActive = false;
    stopCallCount++;
    return startTargetPath;
  }

  @override
  Future<void> cancel() async {
    recordingActive = false;
    cancelCallCount++;
  }

  @override
  Future<void> dispose() async {
    recordingActive = false;
    disposeCallCount++;
  }
}

/// Test Fake for [AudioPlayerWrapper].
class FakeAudioPlayerWrapper implements AudioPlayerWrapper {
  PlayerState _state = PlayerState.stopped;
  Source? currentSource;
  int playCallCount = 0;
  int pauseCallCount = 0;
  int resumeCallCount = 0;
  int stopCallCount = 0;

  final StreamController<PlayerState> _stateController =
      StreamController<PlayerState>.broadcast();
  final StreamController<void> _completeController =
      StreamController<void>.broadcast();

  @override
  PlayerState get state => _state;

  @override
  Stream<PlayerState> get onPlayerStateChanged => _stateController.stream;

  @override
  Stream<Duration> get onPositionChanged => const Stream.empty();

  @override
  Stream<Duration> get onDurationChanged => const Stream.empty();

  @override
  Stream<void> get onPlayerComplete => _completeController.stream;

  @override
  Future<void> play(Source source) async {
    currentSource = source;
    _state = PlayerState.playing;
    _stateController.add(PlayerState.playing);
    playCallCount++;
  }

  @override
  Future<void> pause() async {
    _state = PlayerState.paused;
    _stateController.add(PlayerState.paused);
    pauseCallCount++;
  }

  @override
  Future<void> resume() async {
    _state = PlayerState.playing;
    _stateController.add(PlayerState.playing);
    resumeCallCount++;
  }

  @override
  Future<void> stop() async {
    _state = PlayerState.stopped;
    _stateController.add(PlayerState.stopped);
    stopCallCount++;
  }

  @override
  Future<void> seek(Duration position) async {}

  void triggerCompletion() {
    _state = PlayerState.completed;
    _stateController.add(PlayerState.completed);
    _completeController.add(null);
  }

  @override
  Future<void> dispose() async {
    _stateController.close();
    _completeController.close();
  }
}

/// Test Fake for [AssetRepository].
class FakeAssetRepository implements AssetRepository {
  Uint8List? uploadedBytes;
  String? uploadedContentType;
  int uploadAudioCallCount = 0;
  String returnedAssetId = 'test_audio_asset_999';

  @override
  Future<PresignedAssetModel> presignAsset({
    required String kind,
    required String contentType,
    String? farmId,
  }) async {
    return const PresignedAssetModel(
      assetId: 'test_audio_asset_999',
      uploadUrl: 'https://bhoomi-s3.gov.in/upload/audio.wav',
      expiresIn: 3600,
    );
  }

  @override
  Future<void> uploadBinary({
    required String uploadUrl,
    required Uint8List bytes,
    required String contentType,
    void Function(int count, int total)? onProgress,
  }) async {}

  @override
  Future<String> uploadImage({
    required Uint8List bytes,
    String contentType = 'image/jpeg',
    String? farmId,
    void Function(int count, int total)? onProgress,
  }) async => 'test_image_asset_123';

  @override
  Future<String> uploadAudio({
    required Uint8List bytes,
    String contentType = 'audio/wav',
    String? farmId,
    void Function(int count, int total)? onProgress,
  }) async {
    uploadedBytes = bytes;
    uploadedContentType = contentType;
    uploadAudioCallCount++;
    return returnedAssetId;
  }
}

/// Test Fake for [VoiceRepository].
class FakeVoiceRepository implements VoiceRepository {
  String? lastTranscribedAssetId;
  String? lastTranscribedLang;
  String? lastSynthesizedText;
  int transcribeCallCount = 0;
  int synthesizeCallCount = 0;

  @override
  Future<VoiceTranscribeResult> transcribe({
    required String assetId,
    String lang = 'mr-IN',
    String? context,
  }) async {
    lastTranscribedAssetId = assetId;
    lastTranscribedLang = lang;
    transcribeCallCount++;
    return const VoiceTranscribeResult(
      text: 'टोमॅटो पिकावर करपा आला आहे, त्यावर काय फवारणी करावी?',
      confidence: 0.96,
      lang: 'mr-IN',
    );
  }

  @override
  Future<VoiceSynthesizeResult> synthesize({
    required String text,
    String lang = 'mr-IN',
  }) async {
    lastSynthesizedText = text;
    synthesizeCallCount++;
    return const VoiceSynthesizeResult(
      audioUrl: 'https://bhoomi-s3.gov.in/voice/synthesized_advisory.mp3',
      expiresIn: 600,
    );
  }
}

void main() {
  group('P3: Audio Recording & Playback Service Unit Tests', () {
    late FakeAudioRecorderWrapper fakeRecorder;
    late FakeAudioPlayerWrapper fakePlayer;
    late AudioRecordingService recordingService;
    late AudioPlaybackService playbackService;

    setUp(() {
      fakeRecorder = FakeAudioRecorderWrapper();
      fakePlayer = FakeAudioPlayerWrapper();
      recordingService = AudioRecordingService(recorder: fakeRecorder);
      playbackService = AudioPlaybackService(player: fakePlayer);
    });

    tearDown(() async {
      await recordingService.dispose();
      await playbackService.dispose();
    });

    test('AudioRecordingService records WAV audio and returns non-empty byte data', () async {
      final path = await recordingService.startRecording(contentType: 'audio/wav');
      expect(path, isNotEmpty);
      expect(path.endsWith('.wav'), isTrue);

      final data = await recordingService.stopRecording();
      expect(data, isNotNull);
      expect(data!.bytes.isNotEmpty, isTrue);
      expect(data.contentType, 'audio/wav');
    });

    test('AudioRecordingService cancel clears active recording safely', () async {
      await recordingService.startRecording(contentType: 'audio/wav');
      await recordingService.cancelRecording();
      // Should not throw and cleanly cancel
    });

    test('AudioPlaybackService plays URL, handles pause, resume, stop, and completions', () async {
      expect(playbackService.state, PlayerState.stopped);

      await playbackService.playUrl('https://bhoomi-s3.gov.in/voice/advisory.mp3');
      expect(fakePlayer.playCallCount, 1);
      expect(fakePlayer.currentSource, isA<UrlSource>());

      await playbackService.pause();
      expect(fakePlayer.pauseCallCount, 1);

      await playbackService.resume();
      expect(fakePlayer.resumeCallCount, 1);

      await playbackService.stop();
      expect(fakePlayer.stopCallCount, 1);
    });
  });

  group('P3: FarmerVoiceAssistant & SpokenSummaryPlayer Widget Flow Tests', () {
    late FakeAudioRecorderWrapper fakeRecorder;
    late FakeAudioPlayerWrapper fakePlayer;
    late FakeAssetRepository fakeAssetRepo;
    late FakeVoiceRepository fakeVoiceRepo;

    setUp(() {
      fakeRecorder = FakeAudioRecorderWrapper();
      fakePlayer = FakeAudioPlayerWrapper();
      fakeAssetRepo = FakeAssetRepository();
      fakeVoiceRepo = FakeVoiceRepository();
    });

    testWidgets('FarmerVoiceAssistant completes full microphone capture -> S3 upload -> playback loop',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      String? submittedQuery;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            audioRecorderWrapperProvider.overrideWithValue(fakeRecorder),
            audioPlayerWrapperProvider.overrideWithValue(fakePlayer),
            assetRepositoryProvider.overrideWithValue(fakeAssetRepo),
            voiceRepositoryProvider.overrideWithValue(fakeVoiceRepo),
          ],
          child: BhoomiApp(
            homeOverride: Scaffold(
              body: FarmerVoiceAssistant(
                initialContext: 'Tomato Blight',
                onQuerySubmitted: (query) {
                  submittedQuery = query;
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Verify Initial Idle State
      expect(find.text('Bhoomi Voice Assistant'), findsOneWidget);
      expect(find.text('विषय: Tomato Blight'), findsOneWidget);

      // 2. Start Listening
      await tester.tap(find.byIcon(Icons.mic_rounded).last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // 3. Stop Listening & Process
      expect(find.text('थांबवा'), findsOneWidget);
      await tester.tap(find.text('थांबवा'));
      await tester.pumpAndSettle();

      // 4. Verify Result State with Transcribed Text
      expect(find.text('तुमचा प्रश्न'), findsOneWidget);
      expect(find.text('टोमॅटो पिकावर करपा आला आहे, त्यावर काय फवारणी करावी?'), findsOneWidget);
      expect(fakeVoiceRepo.transcribeCallCount, 1);

      // 5. Playback Audio
      expect(find.text('सल्ला ऐका (Listen)'), findsOneWidget);
      await tester.tap(find.text('सल्ला ऐका (Listen)'));
      await tester.pumpAndSettle();
      expect(fakeVoiceRepo.synthesizeCallCount, 1);
      expect(fakePlayer.playCallCount, 1);

      // 6. Submit Query
      await tester.tap(find.text('विचारणा करा'));
      await tester.pumpAndSettle();
      expect(submittedQuery, 'टोमॅटो पिकावर करपा आला आहे, त्यावर काय फवारणी करावी?');
    });

    testWidgets('SpokenSummaryPlayer controls real playback and responds to stream completion',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      bool playCallbackFired = false;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            audioPlayerWrapperProvider.overrideWithValue(fakePlayer),
            voiceRepositoryProvider.overrideWithValue(fakeVoiceRepo),
          ],
          child: BhoomiApp(
            homeOverride: Scaffold(
              body: Center(
                child: SpokenSummaryPlayer(
                  text: 'Spray copper oxychloride 3g per litre of water.',
                  title: 'सल्ला ऐका (Listen to Advisory)',
                  onPlayAudio: () {
                    playCallbackFired = true;
                  },
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Initial state
      expect(find.text('सल्ला ऐका (Listen to Advisory)'), findsOneWidget);
      expect(playCallbackFired, isFalse);

      // Tap Play
      await tester.tap(find.byIcon(Icons.volume_up_rounded));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(playCallbackFired, isTrue);
      expect(fakeVoiceRepo.synthesizeCallCount, 1);
      expect(fakePlayer.playCallCount, 1);

      // Tap Pause
      await tester.tap(find.byIcon(Icons.pause_rounded));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.replay_rounded), findsOneWidget);
    });
  });
}
