import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_radius.dart';
import 'app_button.dart';

import '../models/farm_models.dart';

/// Farm Health Card for Home Screen (F1, F11, API_CONTRACT §5).
///
/// Principles:
/// - Farm identity + qualitative health sentence + trend arrow.
/// - Deliberately NO composite numeric health scores.
/// - Fast 3-second comprehension for smallholder paddy farmers.
class FarmHealthCard extends StatelessWidget {
  final String farmName;
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
    this.farmName = 'My Paddy Field (माझे शेत)',
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

  String get _trendText {
    switch (healthTrend.toLowerCase()) {
      case 'improving':
        return 'Improving (सुधारणा)';
      case 'worsening':
        return 'Needs attention (लक्ष द्या)';
      default:
        return 'Stable (स्थिर)';
    }
  }

  @override
  Widget build(BuildContext context) {
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
                        farmName,
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
                // Health Sentence & Trend
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'FIELD HEALTH STATUS',
                            style: AppTypography.captionSmall.copyWith(
                              letterSpacing: 0.5,
                              fontWeight: FontWeight.w700,
                            ),
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
                    ),
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
                          Icon(_trendIcon, color: _trendColor, size: 18),
                          const SizedBox(width: AppSpacing.xs4),
                          Text(
                            _trendText,
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

                const SizedBox(height: AppSpacing.l16),
                const Divider(height: 1, color: AppColors.subtleDivider),
                const SizedBox(height: AppSpacing.l16),

                // Quick Status Counters
                Row(
                  children: [
                    _buildCounterTile(
                      count: openProblems,
                      label: 'Open Issues',
                      color: openProblems > 0 ? AppColors.warning : AppColors.success,
                      icon: Icons.pest_control_rounded,
                    ),
                    const SizedBox(width: AppSpacing.s8),
                    _buildCounterTile(
                      count: pendingFollowups,
                      label: 'Follow-ups',
                      color: pendingFollowups > 0 ? AppColors.info : AppColors.fieldSlate,
                      icon: Icons.update_rounded,
                    ),
                    const SizedBox(width: AppSpacing.s8),
                    _buildCounterTile(
                      count: activeAlerts,
                      label: 'Active Alerts',
                      color: activeAlerts > 0 ? AppColors.danger : AppColors.fieldSlate,
                      icon: Icons.notification_important_rounded,
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.xxl24),

                // Immediate Quick Actions
                Row(
                  children: [
                    Expanded(
                      flex: 6,
                      child: AppButton.primary(
                        label: 'Check Crop (पीक तपासा)',
                        onPressed: onCheckCrop,
                        leadingIcon: const Icon(Icons.camera_alt_rounded, size: 20),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.s8),
                    Expanded(
                      flex: 4,
                      child: AppButton.outline(
                        label: 'Ask Bhoomi',
                        onPressed: onAskBhoomi,
                        leadingIcon: const Icon(Icons.mic_rounded, size: 20),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCounterTile({
    required int count,
    required String label,
    required Color color,
    required IconData icon,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s8,
          vertical: AppSpacing.m12,
        ),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: AppRadius.button,
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: 16),
                const SizedBox(width: AppSpacing.xs4),
                Text(
                  count.toString(),
                  style: AppTypography.subhead.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: AppTypography.captionSmall.copyWith(
                color: AppColors.soilCharcoal,
                fontSize: 11,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
