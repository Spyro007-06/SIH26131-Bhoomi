import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_radius.dart';

enum VoiceState {
  idle,
  listening,
  transcribing,
  playback,
}

/// Reusable Voice Control widget for voice-first interactions outdoors.
///
/// States:
/// - idle: Large microphone button to start speaking
/// - listening: Pulsing recording state with stop control
/// - transcribing: Processing indicator
/// - playback: Speaking audio with pause/replay controls
class VoiceActionButton extends StatefulWidget {
  final VoiceState state;
  final VoidCallback? onStartListening;
  final VoidCallback? onStopListening;
  final VoidCallback? onTogglePlayback;
  final String? spokenSummaryText;
  final String activeLanguage;
  final bool isCompact;

  const VoiceActionButton({
    super.key,
    this.state = VoiceState.idle,
    this.onStartListening,
    this.onStopListening,
    this.onTogglePlayback,
    this.spokenSummaryText,
    this.activeLanguage = 'mr-IN',
    this.isCompact = false,
  });

  @override
  State<VoiceActionButton> createState() => _VoiceActionButtonState();
}

class _VoiceActionButtonState extends State<VoiceActionButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.18).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );

    if (widget.state == VoiceState.listening ||
        widget.state == VoiceState.playback) {
      _animController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(VoiceActionButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.state == VoiceState.listening ||
        widget.state == VoiceState.playback) {
      if (!_animController.isAnimating) {
        _animController.repeat(reverse: true);
      }
    } else {
      _animController.stop();
      _animController.reset();
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Color get _stateColor {
    switch (widget.state) {
      case VoiceState.idle:
        return AppColors.forest;
      case VoiceState.listening:
        return AppColors.turmeric;
      case VoiceState.transcribing:
        return AppColors.info;
      case VoiceState.playback:
        return AppColors.paddyGreen;
    }
  }

  String get _stateLabel {
    switch (widget.state) {
      case VoiceState.idle:
        return 'Tap to Speak (बोलण्यासाठी टॅप करा)';
      case VoiceState.listening:
        return 'Listening... Tap to stop (ऐकत आहे...)';
      case VoiceState.transcribing:
        return 'Transcribing speech... (प्रक्रिया करत आहे...)';
      case VoiceState.playback:
        return 'Playing audio summary (आवाज सुरू आहे)';
    }
  }

  IconData get _stateIcon {
    switch (widget.state) {
      case VoiceState.idle:
        return Icons.mic_rounded;
      case VoiceState.listening:
        return Icons.stop_rounded;
      case VoiceState.transcribing:
        return Icons.hourglass_top_rounded;
      case VoiceState.playback:
        return Icons.volume_up_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isCompact) {
      return _buildCompactButton();
    }
    return _buildExpandedCard();
  }

  Widget _buildCompactButton() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        final scale = (widget.state == VoiceState.listening ||
                widget.state == VoiceState.playback)
            ? _pulseAnimation.value
            : 1.0;

        return Transform.scale(
          scale: scale,
          child: Container(
            width: AppSpacing.largeActionButtonHeight,
            height: AppSpacing.largeActionButtonHeight,
            decoration: BoxDecoration(
              color: _stateColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: _stateColor.withValues(alpha: 0.35),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  if (widget.state == VoiceState.idle) {
                    widget.onStartListening?.call();
                  } else if (widget.state == VoiceState.listening) {
                    widget.onStopListening?.call();
                  } else if (widget.state == VoiceState.playback) {
                    widget.onTogglePlayback?.call();
                  }
                },
                customBorder: const CircleBorder(),
                child: Center(
                  child: Icon(
                    _stateIcon,
                    color: AppColors.pureWhite,
                    size: 28,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildExpandedCard() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: AppRadius.card,
        onTap: () {
          if (widget.state == VoiceState.idle) {
            widget.onStartListening?.call();
          } else if (widget.state == VoiceState.listening) {
            widget.onStopListening?.call();
          } else if (widget.state == VoiceState.transcribing) {
            widget.onTogglePlayback?.call();
          } else if (widget.state == VoiceState.playback) {
            widget.onTogglePlayback?.call();
          }
        },
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.l16),
          decoration: BoxDecoration(
            color: AppColors.warmSurface,
            borderRadius: AppRadius.card,
            border: Border.all(
              color: widget.state != VoiceState.idle
                  ? _stateColor
                  : AppColors.border,
              width: widget.state != VoiceState.idle ? 2.0 : 1.0,
            ),
          ),
          child: Row(
            children: [
              _buildCompactButton(),
          const SizedBox(width: AppSpacing.l16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _stateLabel,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.soilCharcoal,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (widget.spokenSummaryText != null &&
                    widget.state == VoiceState.playback) ...[
                  const SizedBox(height: AppSpacing.xs4),
                  Text(
                    widget.spokenSummaryText!,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.fieldSlate,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ] else ...[
                  const SizedBox(height: AppSpacing.xs4),
                  Text(
                    'Marathi / Hindi / English voice',
                    style: AppTypography.captionSmall,
                  ),
                ],
              ],
            ),
          ),
          if (widget.state == VoiceState.playback)
            IconButton(
              icon: const Icon(Icons.replay_rounded, color: AppColors.forest),
              onPressed: widget.onTogglePlayback,
              tooltip: 'Replay',
            ),
        ],
      ),
    ),
  ),
);
}
}
