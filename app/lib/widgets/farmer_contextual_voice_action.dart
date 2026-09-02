import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_radius.dart';
import 'farmer_voice_assistant.dart';

enum ContextualVoiceVariant {
  primary,
  outline,
  audio,
}

/// FarmerContextualVoiceAction: A reusable contextual voice action adhering to the 3-level hierarchy:
/// - Level 1: Home Voice Hero (68dp mic)
/// - Level 2: Important Contextual Voice Action (Medium, 48-56dp height, mic icon, clear contextual label)
/// - Level 3: Supporting Audio Action (Audio speaker icon, "Listen / Explain" label)
class FarmerContextualVoiceAction extends StatelessWidget {
  final String label;
  final String? contextTopic;
  final ValueChanged<String>? onQuerySubmitted;
  final VoidCallback? onTap;
  final ContextualVoiceVariant variant;
  final bool isFullWidth;
  final IconData? leadingIcon;
  final bool isPlaying;

  const FarmerContextualVoiceAction({
    super.key,
    required this.label,
    this.contextTopic,
    this.onQuerySubmitted,
    this.onTap,
    this.variant = ContextualVoiceVariant.outline,
    this.isFullWidth = true,
    this.leadingIcon,
    this.isPlaying = false,
  });

  /// Factory for Level 2 Primary Accent Contextual Action
  factory FarmerContextualVoiceAction.primary({
    required String label,
    String? contextTopic,
    ValueChanged<String>? onQuerySubmitted,
    VoidCallback? onTap,
    bool isFullWidth = true,
    IconData leadingIcon = Icons.mic_rounded,
  }) {
    return FarmerContextualVoiceAction(
      label: label,
      contextTopic: contextTopic,
      onQuerySubmitted: onQuerySubmitted,
      onTap: onTap,
      variant: ContextualVoiceVariant.primary,
      isFullWidth: isFullWidth,
      leadingIcon: leadingIcon,
    );
  }

  /// Factory for Level 2 High-Contrast Outline Contextual Action
  factory FarmerContextualVoiceAction.outline({
    required String label,
    String? contextTopic,
    ValueChanged<String>? onQuerySubmitted,
    VoidCallback? onTap,
    bool isFullWidth = true,
    IconData leadingIcon = Icons.mic_rounded,
  }) {
    return FarmerContextualVoiceAction(
      label: label,
      contextTopic: contextTopic,
      onQuerySubmitted: onQuerySubmitted,
      onTap: onTap,
      variant: ContextualVoiceVariant.outline,
      isFullWidth: isFullWidth,
      leadingIcon: leadingIcon,
    );
  }

  /// Factory for Level 3 Supporting Audio Action
  factory FarmerContextualVoiceAction.audio({
    required String label,
    required VoidCallback onTap,
    bool isFullWidth = false,
    bool isPlaying = false,
  }) {
    return FarmerContextualVoiceAction(
      label: label,
      onTap: onTap,
      variant: ContextualVoiceVariant.audio,
      isFullWidth: isFullWidth,
      leadingIcon: isPlaying ? Icons.pause_rounded : Icons.volume_up_rounded,
      isPlaying: isPlaying,
    );
  }

  void _handleTap(BuildContext context) {
    if (onTap != null) {
      onTap!();
    } else {
      FarmerVoiceAssistant.show(
        context,
        initialContext: contextTopic,
        onQuerySubmitted: onQuerySubmitted,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final effectiveIcon = leadingIcon ??
        (variant == ContextualVoiceVariant.audio
            ? (isPlaying ? Icons.pause_rounded : Icons.volume_up_rounded)
            : Icons.mic_rounded);

    Color backgroundColor;
    Color foregroundColor;
    Border? border;

    switch (variant) {
      case ContextualVoiceVariant.primary:
        backgroundColor = AppColors.forest;
        foregroundColor = AppColors.pureWhite;
        border = null;
        break;
      case ContextualVoiceVariant.outline:
        backgroundColor = AppColors.primaryLight;
        foregroundColor = AppColors.forest;
        border = Border.all(color: AppColors.forest, width: 1.5);
        break;
      case ContextualVoiceVariant.audio:
        backgroundColor = isPlaying ? AppColors.forest : AppColors.primaryLight;
        foregroundColor = isPlaying ? AppColors.pureWhite : AppColors.forest;
        border = Border.all(
          color: isPlaying ? AppColors.forest : AppColors.forest.withValues(alpha: 0.4),
          width: 1.5,
        );
        break;
    }

    final buttonContent = Container(
      constraints: const BoxConstraints(minHeight: 48),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.l16,
        vertical: AppSpacing.m12,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: AppRadius.button,
        border: border,
        boxShadow: variant == ContextualVoiceVariant.primary
            ? [
                BoxShadow(
                  color: AppColors.forest.withValues(alpha: 0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ]
            : null,
      ),
      child: Row(
        mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(effectiveIcon, color: foregroundColor, size: 22),
          const SizedBox(width: AppSpacing.s8),
          Flexible(
            child: Text(
              label,
              style: AppTypography.button.copyWith(
                color: foregroundColor,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );

    return Semantics(
      label: label,
      button: true,
      child: InkWell(
        borderRadius: AppRadius.button,
        onTap: () => _handleTap(context),
        child: isFullWidth ? SizedBox(width: double.infinity, child: buttonContent) : buttonContent,
      ),
    );
  }
}
