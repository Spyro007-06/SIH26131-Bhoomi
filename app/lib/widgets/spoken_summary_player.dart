import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_radius.dart';
import '../core/localization/locale_provider.dart';
import '../providers/repository_providers.dart';

/// SpokenSummaryPlayer: Standardized voice summary playback widget for farmers.
/// - Requires explicit user tap (no auto-start)
/// - Provides playing/pause/replay tactile controls
/// - Displays animated waveform indicators during active playback
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
    with SingleTickerProviderStateMixin {
  bool _isPlaying = false;
  bool _hasPlayed = false;
  late AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  Future<void> _handleTogglePlayback() async {
    if (_isPlaying) {
      _waveController.stop();
      setState(() {
        _isPlaying = false;
      });
    } else {
      _waveController.repeat(reverse: true);
      setState(() {
        _isPlaying = true;
        _hasPlayed = true;
      });

      widget.onPlayAudio?.call();

      // Synthesize via voice repository if needed
      try {
        final voiceRepo = ref.read(voiceRepositoryProvider);
        final lang = ref.read(appLanguageProvider);
        await voiceRepo.synthesize(
          text: widget.text,
          lang: lang.localeIdentifier,
        );
      } catch (_) {
        // Safe fallback
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
