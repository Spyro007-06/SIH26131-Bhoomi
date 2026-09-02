import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_radius.dart';
import '../core/localization/locale_provider.dart';
import '../core/localization/app_strings.dart';
import 'app_button.dart';
import '../models/farm_models.dart';

/// Farm Health Card for Home Screen (F1, F11, API_CONTRACT §5).
///
/// Principles:
/// - Farm identity + qualitative health sentence + trend arrow.
/// - Deliberately NO composite numeric health scores.
/// - Fast 3-second comprehension for smallholder paddy farmers.
/// - Fully pure multilingual with no mixed-language strings.
class FarmHealthCard extends ConsumerWidget {
  final String? farmName;
  final String cropDetails; // e.g. "Indrayani Paddy · Tillering"
  final String region;      // e.g. "Nashik, MH"
  final String healthSentence; // e.g. "One open problem, being monitored."
  final String healthTrend;    // "improving" | "worsening" | "stable"
  final int openProblems;
  final int pendingFollowups;
  final int activeAlerts;
  final VoidCallback? onCheckCrop;
  final VoidCallback? onAskBhoomi;

  FarmHealthCard({
    super.key,
    this.farmName,
    String? cropDetails,
    String? cropName,
    String? growthStage,
    this.region = 'Nashik, Maharashtra',
    String? healthSentence,
    String? healthTrend,
    HealthModel? health,
    this.openProblems = 1,
    this.pendingFollowups = 1,
    this.activeAlerts = 1,
    this.onCheckCrop,
    this.onAskBhoomi,
  })  : cropDetails = cropDetails ??
            (cropName != null && growthStage != null
                ? '$cropName · $growthStage'
                : cropName ?? growthStage ?? 'Indrayani Paddy · Tillering Stage'),
        healthSentence = healthSentence ?? health?.sentence ?? 'One open problem, being monitored.',
        healthTrend = healthTrend ?? health?.trend ?? 'worsening';

  IconData get _trendIcon {
    switch (healthTrend.toLowerCase()) {
      case 'improving':
        return Icons.trending_up_rounded;
      case 'worsening':
        return Icons.trending_down_rounded;
      default:
        return Icons.trending_flat_rounded;
    }
  }

  Color get _trendColor {
    switch (healthTrend.toLowerCase()) {
      case 'improving':
        return AppColors.success;
      case 'worsening':
        return AppColors.danger;
      default:
        return AppColors.fieldSlate;
    }
  }

  String _getTrendText(AppStrings strings) {
    switch (healthTrend.toLowerCase()) {
      case 'improving':
        return strings.trendImproving;
      case 'worsening':
        return strings.trendNeedsAttention;
      default:
        return strings.trendStable;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    AppStrings strings;
    try {
      strings = ref.watch(stringsProvider);
    } catch (_) {
      strings = AppStrings(AppLanguage.marathi);
    }
    final displayName = farmName ?? strings.defaultFarmName;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.warmSurface,
        borderRadius: AppRadius.card,
        border: Border.all(color: AppColors.border, width: 1.0),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Farm Identity & Region
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.l16,
              vertical: AppSpacing.m12,
            ),
            decoration: const BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(AppRadius.cardValue),
                topRight: Radius.circular(AppRadius.cardValue),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.agriculture_rounded,
                  color: AppColors.forest,
                  size: 24,
                ),
                const SizedBox(width: AppSpacing.s8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: AppTypography.subhead.copyWith(
                          color: AppColors.primaryDark,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        '$cropDetails · $region',
                        style: AppTypography.captionSmall.copyWith(
                          color: AppColors.forest,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: AppSpacing.cardPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Health Sentence & Trend (Resilient Layout)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            strings.fieldHealthStatusTitle,
                            style: AppTypography.captionSmall.copyWith(
                              letterSpacing: 0.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.s8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.s8,
                            vertical: AppSpacing.xs4,
                          ),
                          decoration: BoxDecoration(
                            color: _trendColor.withValues(alpha: 0.12),
                            borderRadius: AppRadius.chip,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(_trendIcon, color: _trendColor, size: 16),
                              const SizedBox(width: AppSpacing.xs4),
                              Text(
                                _getTrendText(strings),
                                style: AppTypography.captionSmall.copyWith(
                                  color: _trendColor,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs4),
                    Text(
                      healthSentence,
                      style: AppTypography.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.soilCharcoal,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.l16),
                const Divider(height: 1, color: AppColors.subtleDivider),
                const SizedBox(height: AppSpacing.l16),

                // Meaningful Information Indicators (Clean Pure Localized Wrap)
                Wrap(
                  spacing: AppSpacing.s8,
                  runSpacing: AppSpacing.s8,
                  children: [
                    if (openProblems > 0)
                      _buildStatusChip(
                        icon: Icons.warning_amber_rounded,
                        label: '$openProblems ${strings.statusIssuesLabel}',
                        color: AppColors.warning,
                      ),
                    if (pendingFollowups > 0)
                      _buildStatusChip(
                        icon: Icons.update_rounded,
                        label: '$pendingFollowups ${strings.statusFollowupLabel}',
                        color: AppColors.info,
                      ),
                    if (activeAlerts > 0)
                      _buildStatusChip(
                        icon: Icons.notification_important_rounded,
                        label: '$activeAlerts ${strings.statusAlertsLabel}',
                        color: AppColors.danger,
                      ),
                    if (openProblems == 0 && pendingFollowups == 0 && activeAlerts == 0)
                      _buildStatusChip(
                        icon: Icons.check_circle_rounded,
                        label: strings.statusAllClearLabel,
                        color: AppColors.success,
                      ),
                  ],
                ),

                // Immediate Quick Actions (Rendered only when callbacks are passed)
                if (onCheckCrop != null || onAskBhoomi != null) ...[
                  const SizedBox(height: AppSpacing.l16),
                  Wrap(
                    spacing: AppSpacing.s8,
                    runSpacing: AppSpacing.s8,
                    children: [
                      if (onCheckCrop != null)
                        AppButton.outline(
                          label: strings.navCheckCrop,
                          size: AppButtonSize.small,
                          onPressed: onCheckCrop,
                          leadingIcon: const Icon(Icons.camera_alt_outlined, size: 16),
                        ),
                      if (onAskBhoomi != null)
                        AppButton.secondary(
                          label: strings.voiceTapToSpeak,
                          size: AppButtonSize.small,
                          onPressed: onAskBhoomi,
                          leadingIcon: const Icon(Icons.mic_rounded, size: 16),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.m12,
        vertical: AppSpacing.s8,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: AppRadius.chip,
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: AppSpacing.xs4),
          Text(
            label,
            style: AppTypography.captionSmall.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
