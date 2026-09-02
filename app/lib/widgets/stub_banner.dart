import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_radius.dart';

/// Demonstration / Stub Warning Banner (Invariant 11 / docs/DESIGN.md §12).
///
/// MUST be rendered visibly whenever `is_stub: true`.
/// Never silently hidden in the UI.
class StubBanner extends StatelessWidget {
  final String title;
  final String message;
  final EdgeInsetsGeometry margin;

  const StubBanner({
    super.key,
    this.title = 'DEMONSTRATION MODE',
    this.message = 'Synthetic test distribution — not live field diagnosis.',
    this.margin = const EdgeInsets.only(bottom: AppSpacing.l16),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.l16,
        vertical: AppSpacing.m12,
      ),
      decoration: BoxDecoration(
        color: AppColors.warningBg,
        borderRadius: AppRadius.card,
        border: Border.all(
          color: AppColors.warning,
          width: 1.5,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.s8),
            decoration: const BoxDecoration(
              color: AppColors.warning,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.science_rounded,
              color: AppColors.pureWhite,
              size: 20,
            ),
          ),
          const SizedBox(width: AppSpacing.m12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: AppTypography.badge.copyWith(
                    color: AppColors.warning,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  message,
                  style: AppTypography.captionSmall.copyWith(
                    color: AppColors.soilCharcoal,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
