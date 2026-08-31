import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_radius.dart';
import 'app_button.dart';

/// Closed-Loop Follow-up Card (F10, PRD §5, API_CONTRACT §11).
///
/// Principles:
/// - Simple human question: "How is the crop doing now?"
/// - 3 large tactile options: Improved, No change, Got worse.
/// - Drives severity promotion and auto-escalation on deterioration.
class FollowUpCard extends StatelessWidget {
  final String question;
  final String questionLocalized;
  final String target;
  final ValueChanged<String>? onResponse; // 'improved' | 'no_change' | 'got_worse'
  final VoidCallback? onAttachPhoto;

  const FollowUpCard({
    super.key,
    this.question = 'How is the crop doing after treatment?',
    this.questionLocalized = 'उपचारानंतर पिकाची स्थिती कशी आहे?',
    this.target = 'Paddy Blast Treatment (करपा उपचार)',
    this.onResponse,
    this.onAttachPhoto,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.warmSurface,
        borderRadius: AppRadius.card,
        border: Border.all(color: AppColors.info, width: 1.5),
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
            decoration: const BoxDecoration(
              color: AppColors.infoBg,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(AppRadius.cardValue),
                topRight: Radius.circular(AppRadius.cardValue),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.update_rounded, color: AppColors.info, size: 22),
                const SizedBox(width: AppSpacing.s8),
                Expanded(
                  child: Text(
                    'Follow-up Check-in (पाठपुरावा)',
                    style: AppTypography.subhead.copyWith(
                      color: AppColors.info,
                      fontSize: 15,
                    ),
                  ),
                ),
                Text(
                  target,
                  style: AppTypography.captionSmall.copyWith(
                    fontWeight: FontWeight.w600,
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
                Text(
                  question,
                  style: AppTypography.sectionTitle.copyWith(
                    color: AppColors.soilCharcoal,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  questionLocalized,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.forest,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.l16),

                // 3 Large options
                Row(
                  children: [
                    Expanded(
                      child: _buildChoiceButton(
                        label: 'Improved\n(सुधारणा)',
                        icon: Icons.sentiment_satisfied_alt_rounded,
                        color: AppColors.success,
                        onTap: () => onResponse?.call('improved'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.s8),
                    Expanded(
                      child: _buildChoiceButton(
                        label: 'No change\n(बदल नाही)',
                        icon: Icons.sentiment_neutral_rounded,
                        color: AppColors.fieldSlate,
                        onTap: () => onResponse?.call('no_change'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.s8),
                    Expanded(
                      child: _buildChoiceButton(
                        label: 'Got worse\n(बिघडले)',
                        icon: Icons.sentiment_very_dissatisfied_rounded,
                        color: AppColors.danger,
                        onTap: () => onResponse?.call('got_worse'),
                      ),
                    ),
                  ],
                ),

                if (onAttachPhoto != null) ...[
                  const SizedBox(height: AppSpacing.l16),
                  AppButton.outline(
                    label: 'Attach Current Photo (सध्याचा फोटो जोडा)',
                    onPressed: onAttachPhoto,
                    isFullWidth: true,
                    size: AppButtonSize.small,
                    leadingIcon: const Icon(Icons.add_a_photo_outlined, size: 18),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChoiceButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: AppRadius.button,
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: AppRadius.button,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.button,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.s8,
              vertical: AppSpacing.l16,
            ),
            child: Column(
              children: [
                Icon(icon, color: color, size: 28),
                const SizedBox(height: AppSpacing.s8),
                Text(
                  label,
                  style: AppTypography.caption.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.soilCharcoal,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
