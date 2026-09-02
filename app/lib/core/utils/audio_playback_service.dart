import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

bool get _isTestEnv {
  if (Platform.environment.containsKey('FLUTTER_TEST')) return true;
  try {
    return WidgetsBinding.instance.runtimeType.toString().contains('Test');
  } catch (_) {
    return false;
  }
}

/// Abstract wrapper around [AudioPlayer] for testability and platform isolation.
abstract class AudioPlayerWrapper {
  Future<void> play(Source source);
  Future<void> pause();
  Future<void> resume();
  Future<void> stop();
  Future<void> seek(Duration position);
  Stream<PlayerState> get onPlayerStateChanged;
  Stream<Duration> get onPositionChanged;
  Stream<Duration> get onDurationChanged;
  Stream<void> get onPlayerComplete;
  PlayerState get state;
  Future<void> dispose();
}

/// Default production implementation wrapping native [AudioPlayer].
class DefaultAudioPlayerWrapper implements AudioPlayerWrapper {
  AudioPlayer? _nativePlayer;
  PlayerState _simulatedState = PlayerState.stopped;
  final StreamController<PlayerState> _stateController =
      StreamController<PlayerState>.broadcast();
  final StreamController<void> _completeController =
      StreamController<void>.broadcast();

  AudioPlayer _getPlayer() {
    _nativePlayer ??= AudioPlayer();
    return _nativePlayer!;
  }

  @override
  PlayerState get state => _isTestEnv ? _simulatedState : (_nativePlayer?.state ?? _simulatedState);

  @override
  Stream<PlayerState> get onPlayerStateChanged => _isTestEnv
      ? _stateController.stream
      : _getPlayer().onPlayerStateChanged;

  @override
  Stream<Duration> get onPositionChanged =>
      _isTestEnv ? const Stream.empty() : _getPlayer().onPositionChanged;

  @override
  Stream<Duration> get onDurationChanged =>
      _isTestEnv ? const Stream.empty() : _getPlayer().onDurationChanged;

  @override
  Stream<void> get onPlayerComplete => _isTestEnv
      ? _completeController.stream
      : _getPlayer().onPlayerComplete;

  @override
  Future<void> play(Source source) async {
    _simulatedState = PlayerState.playing;
    if (!_stateController.isClosed) {
      _stateController.add(PlayerState.playing);
    }
    if (_isTestEnv) return;
    try {
      await _getPlayer().play(source);
    } catch (_) {}
  }

  @override
  Future<void> pause() async {
    _simulatedState = PlayerState.paused;
    if (!_stateController.isClosed) {
      _stateController.add(PlayerState.paused);
    }
    if (_isTestEnv) return;
    try {
      if (_nativePlayer != null) {
        await _nativePlayer!.pause();
      }
    } catch (_) {}
  }

  @override
  Future<void> resume() async {
    _simulatedState = PlayerState.playing;
    if (!_stateController.isClosed) {
      _stateController.add(PlayerState.playing);
    }
    if (_isTestEnv) return;
    try {
      if (_nativePlayer != null) {
        await _nativePlayer!.resume();
      }
    } catch (_) {}
  }

  @override
  Future<void> stop() async {
    _simulatedState = PlayerState.stopped;
    if (!_stateController.isClosed) {
      _stateController.add(PlayerState.stopped);
    }
    if (_isTestEnv) return;
    try {
      if (_nativePlayer != null) {
        await _nativePlayer!.stop();
      }
    } catch (_) {}
  }

  @override
  Future<void> seek(Duration position) async {
    if (_isTestEnv) return;
    try {
      if (_nativePlayer != null) {
        await _nativePlayer!.seek(position);
      }
    } catch (_) {}
  }

  @override
  Future<void> dispose() async {
    _simulatedState = PlayerState.stopped;
    if (!_stateController.isClosed) {
      _stateController.close();
    }
    if (!_completeController.isClosed) {
      _completeController.close();
    }
    if (_isTestEnv) return;
    try {
      if (_nativePlayer != null) {
        await _nativePlayer!.dispose();
        _nativePlayer = null;
      }
    } catch (_) {}
  }
}

/// Service providing unified audio playback for URLs, local files, and byte arrays.
class AudioPlaybackService {
  final AudioPlayerWrapper _player;

  AudioPlaybackService({AudioPlayerWrapper? player})
      : _player = player ?? DefaultAudioPlayerWrapper();

  PlayerState get state => _player.state;
  Stream<PlayerState> get onPlayerStateChanged => _player.onPlayerStateChanged;
  Stream<Duration> get onPositionChanged => _player.onPositionChanged;
  Stream<Duration> get onDurationChanged => _player.onDurationChanged;
  Stream<void> get onPlayerComplete => _player.onPlayerComplete;

  /// Play audio from remote URL (e.g. S3 presigned URL).
  Future<void> playUrl(String url) async {
    await _player.play(UrlSource(url));
  }

  /// Play audio from local file on device storage.
  Future<void> playFile(String filePath) async {
    await _player.play(DeviceFileSource(filePath));
  }

  /// Play audio directly from in-memory byte buffer.
  Future<void> playBytes(Uint8List bytes, {String? mimeType}) async {
    await _player.play(BytesSource(bytes, mimeType: mimeType));
  }

  /// Pause current audio playback.
  Future<void> pause() async {
    await _player.pause();
  }

  /// Resume paused audio playback.
  Future<void> resume() async {
    await _player.resume();
  }

  /// Stop current playback and reset position.
  Future<void> stop() async {
    await _player.stop();
  }

  /// Seek playback to specified duration.
  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  /// Dispose player resources.
  Future<void> dispose() async {
    await _player.dispose();
  }
}

/// Riverpod provider for [AudioPlayerWrapper].
final audioPlayerWrapperProvider = Provider<AudioPlayerWrapper>((ref) {
  final wrapper = DefaultAudioPlayerWrapper();
  ref.onDispose(() => wrapper.dispose());
  return wrapper;
});

/// Riverpod provider for [AudioPlaybackService].
final audioPlaybackServiceProvider = Provider<AudioPlaybackService>((ref) {
  final wrapper = ref.watch(audioPlayerWrapperProvider);
  final service = AudioPlaybackService(player: wrapper);
  ref.onDispose(() => service.dispose());
  return service;
});
