# P3 — Real Device Microphone Recording & Audio Playback Architecture

## Overview

The Bhoomi Farmer App has completed production hardening for its voice pipeline. All simulated mock voice recording and placeholder asset strings (`audio_mock_asset`, simulated timer waveforms) have been replaced with real hardware-integrated microphone recording (`record`), S3 presigned binary audio upload (`AssetRepository.uploadAudio`), and audio streaming playback (`audioplayers`).

---

## 1. Native Permissions & Platform Configuration

### Android (`android/app/src/main/AndroidManifest.xml`)
- Declared `android.permission.RECORD_AUDIO` to enable hardware microphone capture.
- Declared `android.permission.MODIFY_AUDIO_SETTINGS` for audio playback routing.

### iOS (`ios/Runner/Info.plist`)
- Declared `NSMicrophoneUsageDescription`:
  ```xml
  <key>NSMicrophoneUsageDescription</key>
  <string>Bhoomi requires microphone access to record farmer voice queries and provide agricultural advice in your regional language.</string>
  ```

---

## 2. Core Audio Architecture

```
[ Farmer Voice UI ]
       │
       ▼
[ AudioRecordingService ] ───► [ AudioRecorderWrapper ] ───► Native Hardware Mic (record)
       │
       ▼ (WAV 16kHz Mono / AAC)
[ Temp File via path_provider ]
       │
       ▼ (Binary Bytes)
[ AssetRepository.uploadAudio ] ───► POST /assets/presign ──► S3 Binary PUT ──► returns real asset_id
       │
       ▼ (Clean up temp file)
[ VoiceRepository.transcribe ] ───► POST /voice/transcribe with {asset_id, lang, context}
       │
       ▼ (Synthesized audio URL)
[ AudioPlaybackService ] ───► [ AudioPlayerWrapper ] ───► Native Speaker / Output (audioplayers)
```

### Services & Wrappers

1. **[`AudioRecordingService`](file:///d:/Project/SIH26131-Bhoomi/app/lib/core/utils/audio_recording_service.dart)**:
   - Encapsulates recording lifecycle: start, stop, cancel, temporary file generation, byte reading, and disk cleanup.
   - Integrates permission checks (`checkPermission`, `requestPermission`, `openSettings`).
   - Configures audio encoding: 16 kHz Mono WAV (`AudioEncoder.wav`) or AAC (`AudioEncoder.aacLc`).
   - Isolate native dependencies behind `AudioRecorderWrapper` for 100% test isolation.

2. **[`AudioPlaybackService`](file:///d:/Project/SIH26131-Bhoomi/app/lib/core/utils/audio_playback_service.dart)**:
   - Unified playback engine supporting remote URLs (`playUrl`), local device files (`playFile`), and in-memory byte buffers (`playBytes`).
   - Controls: `pause()`, `resume()`, `stop()`, `seek()`.
   - Exposes reactive broadcast streams: `onPlayerStateChanged`, `onPositionChanged`, `onDurationChanged`, `onPlayerComplete`.
   - Isolated behind `AudioPlayerWrapper` for deterministic unit and widget testing.

---

## 3. Widget Integration

### [`FarmerVoiceAssistant`](file:///d:/Project/SIH26131-Bhoomi/app/lib/widgets/farmer_voice_assistant.dart)
- **Zero Mock Assets**: Eliminated fake `audio_mock_asset` sentinel.
- **Workflow State Machine**: `idle` ➔ `listening` ➔ `processing` ➔ `result` ➔ `playback` ➔ `error` / `permission`.
- **Presigned Upload Pipeline**: Reads recorded binary audio bytes, calls `AssetRepository.uploadAudio()`, immediately deletes temporary files, and passes real `asset_id` to `VoiceRepository.transcribe()`.
- **Background Lifecycle Resilience**: Implements `WidgetsBindingObserver` to immediately cancel recording or pause playback when the app is backgrounded (`AppLifecycleState.paused` / `inactive`).
- **Tactile UI & Pulsing Animation**: Prominent 80dp circular mic button with breathing ripple effect during active recording and animated waveform equalizer during advisory playback.

### [`SpokenSummaryPlayer`](file:///d:/Project/SIH26131-Bhoomi/app/lib/widgets/spoken_summary_player.dart)
- Connected to `AudioPlaybackService` streams to replace simulated waveform timer with real playback events.
- Provides tactile play, pause, replay controls with animated equalizer indicator.
- Automatically pauses audio when the screen is navigated away or backgrounded.

---

## 4. Verification & Testing

- `flutter analyze`: **0 issues**
- `flutter test`: **164/164 passed**
- Comprehensive test coverage in [`app/test/real_voice_workflow_test.dart`](file:///d:/Project/SIH26131-Bhoomi/app/test/real_voice_workflow_test.dart), `test/voice_first_workflow_test.dart`, `test/farmer_voice_assistant_test.dart`, and `test/farmer_contextual_voice_test.dart`.

### Physical Device Verification Requirements
To test on real hardware:
1. Deploy build to Android or iOS device.
2. Grant microphone permission when prompted.
3. Tap 🎤 to record a spoken Marathi/Hindi/English sentence.
4. Verify recording stops, uploads to S3, returns transcribed query, and plays synthesized audio advisory through speaker.
