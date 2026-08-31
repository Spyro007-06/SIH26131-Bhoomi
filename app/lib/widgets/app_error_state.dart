import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_radius.dart';
import 'app_button.dart';

/// Calm, helpful error state designed to avoid panic and guide the farmer on what to do next.
class AppErrorState extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback? onRetry;
  final VoidCallback? onCallHelpline;
  final String retryLabel;
  final String helplineLabel;

  const AppErrorState({
    super.key,
    this.title = 'Unable to complete action',
    required this.message,
    this.onRetry,
    this.onCallHelpline,
    this.retryLabel = 'Try Again',
    this.helplineLabel = 'Call Kisan Helpline',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xxl24),
      decoration: BoxDecoration(
        color: AppColors.warmSurface,
        borderRadius: AppRadius.card,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.l16),
            decoration: const BoxDecoration(
              color: AppColors.dangerBg,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.error_outline_rounded,
              color: AppColors.danger,
              size: 36,
            ),
          ),
          const SizedBox(height: AppSpacing.l16),
          Text(
            title,
            style: AppTypography.sectionTitle,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.s8),
          Text(
            message,
            style: AppTypography.body.copyWith(
              color: AppColors.fieldSlate,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xxl24),
          if (onRetry != null)
            AppButton.primary(
              label: retryLabel,
              onPressed: onRetry,
              isFullWidth: true,
              leadingIcon: const Icon(Icons.refresh_rounded),
            ),
          if (onCallHelpline != null) ...[
            const SizedBox(height: AppSpacing.m12),
            AppButton.outline(
              label: helplineLabel,
              onPressed: onCallHelpline,
              isFullWidth: true,
              leadingIcon: const Icon(Icons.phone_in_talk_rounded),
            ),
          ],
        ],
      ),
    );
  }
}
