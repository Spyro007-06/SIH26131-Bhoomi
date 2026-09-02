import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_radius.dart';
import 'app_status_badge.dart';
import 'app_button.dart';

/// Proactive Risk Alert Card (F5, F6, API_CONTRACT §10).
///
/// Invariant: Every alert MUST carry at least one inspection task.
/// Never a passive notification — always carries clear 'where to look' task and outcome action.
class RiskCard extends StatelessWidget {
  final String target;
  final String riskLevel; // 'high' | 'medium' | 'low'
  final String reason;
  final List<String> inspectionTasks;
  final String triggerType; // 'weather' | 'seasonal' | 'spread' | 'combined'
  final VoidCallback? onInspectNow;
  final VoidCallback? onRemindTomorrow;

  const RiskCard({
    super.key,
    this.target = 'Paddy Blast (भातावरील करपा)',
    this.riskLevel = 'high',
    this.reason = 'Humidity above 90% for 4 consecutive nights at tillering stage.',
    this.inspectionTasks = const [
      'Check the upper leaves on 10 plants across the field.',
      'Photograph any spot with a grey centre.',
    ],
    this.triggerType = 'weather',
    this.onInspectNow,
    this.onRemindTomorrow,
  });

  Color get _cardBorderColor {
    switch (riskLevel.toLowerCase()) {
      case 'high':
        return AppColors.danger;
      case 'medium':
        return AppColors.warning;
      default:
        return AppColors.forest;
    }
  }

  Widget _buildRiskBadge() {
    switch (riskLevel.toLowerCase()) {
      case 'high':
        return const AppStatusBadge.highRisk();
      case 'medium':
        return const AppStatusBadge.mediumRisk();
      default:
        return const AppStatusBadge.lowRisk();
    }
  }

  String get _triggerLabel {
    switch (triggerType.toLowerCase()) {
      case 'spread':
        return 'Nearby Farm Outbreak Alert (शेजारील शेत इशारा)';
      case 'seasonal':
        return 'Seasonal Pest Alert (हंगामी इशारा)';
      case 'combined':
        return 'Combined Risk Alert';
      default:
        return 'Weather Risk Alert (हवामान आधारित इशारा)';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.warmSurface,
        borderRadius: AppRadius.card,
        border: Border.all(
          color: _cardBorderColor,
          width: riskLevel.toLowerCase() == 'high' ? 2.0 : 1.0,
        ),
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
          // Header
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.l16,
              vertical: AppSpacing.m12,
            ),
            decoration: BoxDecoration(
              color: riskLevel.toLowerCase() == 'high'
                  ? AppColors.dangerBg
                  : AppColors.warningBg,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppRadius.cardValue),
                topRight: Radius.circular(AppRadius.cardValue),
              ),
            ),
            child: Row(
              children: [
                _buildRiskBadge(),
                const SizedBox(width: AppSpacing.m12),
                Expanded(
                  child: Text(
                    _triggerLabel,
                    style: AppTypography.caption.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.soilCharcoal,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
                // Target Title
                Text(
                  target,
                  style: AppTypography.sectionTitle.copyWith(
                    color: AppColors.soilCharcoal,
                  ),
                ),
                const SizedBox(height: AppSpacing.s8),

                // Why (Reason)
                Container(
                  padding: const EdgeInsets.all(AppSpacing.m12),
                  decoration: BoxDecoration(
                    color: AppColors.ricePaper,
                    borderRadius: AppRadius.button,
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.insights_rounded,
                        color: AppColors.fieldSlate,
                        size: 20,
                      ),
                      const SizedBox(width: AppSpacing.s8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'WHY (कारण):',
                              style: AppTypography.captionSmall.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppColors.fieldSlate,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              reason,
                              style: AppTypography.body.copyWith(
                                fontSize: 15,
                                color: AppColors.soilCharcoal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.l16),

                // Go Look (Inspection Task)
                Text(
                  'GO LOOK (शेतात काय तपासावे):',
                  style: AppTypography.caption.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.forest,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: AppSpacing.s8),
                ...inspectionTasks.map(
                  (task) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.s8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 2),
                          child: Icon(
                            Icons.check_circle_rounded,
                            color: AppColors.forest,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.s8),
                        Expanded(
                          child: Text(
                            task,
                            style: AppTypography.bodyMedium.copyWith(
                              color: AppColors.soilCharcoal,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: AppSpacing.l16),

                // Non-dismissible actions
                Row(
                  children: [
                    Expanded(
                      flex: 6,
                      child: AppButton.primary(
                        label: "I'LL CHECK (मी तपासतो)",
                        onPressed: onInspectNow,
                        leadingIcon: const Icon(Icons.search_rounded, size: 20),
                      ),
                    ),
                    if (onRemindTomorrow != null) ...[
                      const SizedBox(width: AppSpacing.s8),
                      Expanded(
                        flex: 4,
                        child: AppButton.outline(
                          label: 'Remind Later',
                          onPressed: onRemindTomorrow,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
