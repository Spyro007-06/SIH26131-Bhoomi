import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_radius.dart';
import 'app_button.dart';

/// Reusable Empty State component for lists, history, and timeline.
class AppEmptyState extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  const AppEmptyState({
    super.key,
    required this.title,
    String? description,
    String? message,
    String? subtitle,
    this.icon = Icons.spa_outlined,
    this.actionLabel,
    this.onAction,
  }) : description = description ?? message ?? subtitle ?? '';

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
              color: AppColors.primaryLight,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: AppColors.forest,
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
            description,
            style: AppTypography.body.copyWith(
              color: AppColors.fieldSlate,
            ),
            textAlign: TextAlign.center,
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: AppSpacing.xxl24),
            AppButton.primary(
              label: actionLabel!,
              onPressed: onAction,
              isFullWidth: true,
            ),
          ],
        ],
      ),
    );
  }
}
