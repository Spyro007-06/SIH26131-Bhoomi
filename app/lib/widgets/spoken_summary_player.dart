import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_radius.dart';
import '../core/localization/locale_provider.dart';
import '../core/utils/audio_playback_service.dart';
import '../providers/repository_providers.dart';

/// SpokenSummaryPlayer: Standardized voice summary playback widget for farmers.
/// - Requires explicit user tap (no auto-start)
/// - Provides playing/pause/replay tactile controls
/// - Displays animated waveform indicators driven by real audio playback
class SpokenSummaryPlayer extends ConsumerStatefulWidget {
  final String text;
  final String? audioUrl;
  final String? title;
  final VoidCallback? onPlayAudio;

  const SpokenSummaryPlayer({
    super.key,
    required this.text,
    this.audioUrl,
    this.title,
    this.onPlayAudio,
  });

  @override
  ConsumerState<SpokenSummaryPlayer> createState() => _SpokenSummaryPlayerState();
}

class _SpokenSummaryPlayerState extends ConsumerState<SpokenSummaryPlayer>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  bool _isPlaying = false;
  bool _hasPlayed = false;
  late AnimationController _waveController;

  StreamSubscription<PlayerState>? _stateSub;
  StreamSubscription<void>? _completeSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _listenToPlayerStreams();
    });
  }

  void _listenToPlayerStreams() {
    final playbackService = ref.read(audioPlaybackServiceProvider);

    _stateSub?.cancel();
    _stateSub = playbackService.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
          if (_isPlaying) {
            _hasPlayed = true;
            if (!_waveController.isAnimating) {
              _waveController.repeat(reverse: true);
            }
          } else {
            _waveController.stop();
          }
        });
      }
    });

    _completeSub?.cancel();
    _completeSub = playbackService.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() {
          _isPlaying = false;
          _waveController.stop();
        });
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      if (_isPlaying) {
        final playbackService = ref.read(audioPlaybackServiceProvider);
        playbackService.pause();
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stateSub?.cancel();
    _completeSub?.cancel();
    _waveController.dispose();
    super.dispose();
  }

  Future<void> _handleTogglePlayback() async {
    final playbackService = ref.read(audioPlaybackServiceProvider);

    if (_isPlaying) {
      _waveController.stop();
      if (mounted) {
        setState(() {
          _isPlaying = false;
        });
      }
      await playbackService.pause();
    } else {
      widget.onPlayAudio?.call();

      if (mounted) {
        setState(() {
          _isPlaying = true;
          _hasPlayed = true;
          _waveController.repeat(reverse: true);
        });
      }

      try {
        // If audioUrl is provided, play directly
        if (widget.audioUrl != null && widget.audioUrl!.isNotEmpty) {
          await playbackService.playUrl(widget.audioUrl!);
          return;
        }

        // Synthesize via voice repository
        final voiceRepo = ref.read(voiceRepositoryProvider);
        final lang = ref.read(appLanguageProvider);
        final synthResult = await voiceRepo.synthesize(
          text: widget.text,
          lang: lang.localeIdentifier,
        );

        if (synthResult.audioUrl.isNotEmpty) {
          await playbackService.playUrl(synthResult.audioUrl);
        }
      } catch (_) {
        if (mounted) {
          setState(() {
            _isPlaying = false;
            _waveController.stop();
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(stringsProvider);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.l16,
        vertical: AppSpacing.m12,
      ),
      decoration: BoxDecoration(
        color: AppColors.warmSurface,
        borderRadius: AppRadius.card,
        border: Border.all(
          color: _isPlaying ? AppColors.forest : AppColors.border,
          width: _isPlaying ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Semantics(
                label: _isPlaying ? strings.semanticsStopAudio : strings.semanticsPlayAudio,
                button: true,
                child: GestureDetector(
                  onTap: _handleTogglePlayback,
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: _isPlaying ? AppColors.turmeric : AppColors.forest,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: (_isPlaying ? AppColors.turmeric : AppColors.forest)
                              .withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Icon(
                      _isPlaying
                          ? Icons.pause_rounded
                          : (_hasPlayed ? Icons.replay_rounded : Icons.volume_up_rounded),
                      color: AppColors.pureWhite,
                      size: 24,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.m12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title ?? (_isPlaying ? strings.voicePlayingAudio : strings.listenSpokenSummary),
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: _isPlaying ? AppColors.forest : AppColors.soilCharcoal,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _isPlaying
                          ? 'Audio advisory playing...'
                          : 'Tap to listen to this advisory in your language',
                      style: AppTypography.captionSmall.copyWith(
                        color: AppColors.fieldSlate,
                      ),
                    ),
                  ],
                ),
              ),
              if (_isPlaying) ...[
                const SizedBox(width: AppSpacing.s8),
                _buildAnimatedWaveform(),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedWaveform() {
    return AnimatedBuilder(
      animation: _waveController,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(4, (index) {
            final phase = (index * 0.25);
            final heightFactor = ((_waveController.value + phase) % 1.0);
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 1.5),
              width: 3.5,
              height: 10.0 + (heightFactor * 16.0),
              decoration: BoxDecoration(
                color: AppColors.forest,
                borderRadius: BorderRadius.circular(2),
              ),
            );
          }),
        );
      },
    );
  }
}
