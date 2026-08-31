import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_radius.dart';
import '../core/constants/app_constants.dart';
import 'app_button.dart';

/// Pesticide Label Check Safety Card (F8, PRD §5, API_CONTRACT §9, DESIGN.md §9).
///
/// SAFETY INVARIANTS:
/// 1. VETO, NEVER ENDORSE.
/// 2. NEVER say "safe", "approved", or "you can use this".
/// 3. Render backend verdict strings exactly as provided.
/// 4. The printed bottle label remains the sole authority on dosage.
class PesticideVetoCard extends StatelessWidget {
  final String activeIngredient;
  final String concentration;
  final String formulation;
  final double ocrConfidence;
  final String verdictCode; // NO_OBJECTION_FOUND | WRONG_CLASS | NOT_REGISTERED_FOR_TARGET | WRONG_CROP | PHI_CONFLICT | NOT_IN_RECORDS
  final String? customVerdictMessage;
  final VoidCallback? onRetakePhoto;
  final VoidCallback? onAskExpert;

  const PesticideVetoCard({
    super.key,
    this.activeIngredient = 'carbendazim',
    this.concentration = '50% WP',
    this.formulation = 'wettable powder',
    this.ocrConfidence = 0.88,
    this.verdictCode = 'WRONG_CLASS',
    this.customVerdictMessage,
    this.onRetakePhoto,
    this.onAskExpert,
  });

  bool get _isNoObjection => verdictCode == 'NO_OBJECTION_FOUND';
  bool get _isNotInRecords => verdictCode == 'NOT_IN_RECORDS';
  bool get _isVetoed => !_isNoObjection && !_isNotInRecords;

  String get _verdictMessage {
    if (customVerdictMessage != null) return customVerdictMessage!;
    return AppConstants.verdictMessages[verdictCode] ??
        'Check with an expert before application.';
  }

  Color get _statusColor {
    if (_isNoObjection) return AppColors.success;
    if (_isNotInRecords) return AppColors.turmeric;
    return AppColors.danger;
  }

  Color get _statusBg {
    if (_isNoObjection) return AppColors.successBg;
    if (_isNotInRecords) return AppColors.warningBg;
    return AppColors.dangerBg;
  }

  String get _verdictTitle {
    if (_isNoObjection) return 'NO OBJECTION FOUND';
    if (_isNotInRecords) return 'PRODUCT NOT IN RECORDS';
    return 'DO NOT SPRAY — VETO VERDICT';
  }

  IconData get _verdictIcon {
    if (_isNoObjection) return Icons.check_circle_outline_rounded;
    if (_isNotInRecords) return Icons.help_outline_rounded;
    return Icons.cancel_outlined;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.warmSurface,
        borderRadius: AppRadius.card,
        border: Border.all(
          color: _statusColor,
          width: 2.0,
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
          // Header: Veto Status Banner
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.l16,
              vertical: AppSpacing.m12,
            ),
            decoration: BoxDecoration(
              color: _statusBg,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppRadius.cardValue),
                topRight: Radius.circular(AppRadius.cardValue),
              ),
            ),
            child: Row(
              children: [
                Icon(_verdictIcon, color: _statusColor, size: 24),
                const SizedBox(width: AppSpacing.s8),
                Expanded(
                  child: Text(
                    _verdictTitle,
                    style: AppTypography.badge.copyWith(
                      color: _statusColor,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.s8,
                    vertical: AppSpacing.xs4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.warmSurface,
                    borderRadius: AppRadius.chip,
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(
                    'OCR: ${(ocrConfidence * 100).toInt()}%',
                    style: AppTypography.captionSmall.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
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
                // Step 1 & 2: Extracted Information
                Text(
                  'LABEL OCR EXTRACTION (बाटलीवरील माहिती):',
                  style: AppTypography.captionSmall.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.fieldSlate,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: AppSpacing.s8),

                Container(
                  padding: const EdgeInsets.all(AppSpacing.m12),
                  decoration: BoxDecoration(
                    color: AppColors.ricePaper,
                    borderRadius: AppRadius.button,
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      _buildExtractRow('Active Ingredient:', activeIngredient),
                      const SizedBox(height: AppSpacing.xs4),
                      _buildExtractRow('Concentration & Form:', '$concentration, $formulation'),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.l16),

                // Step 3: Backend Verdict String (Rendered Verbatim)
                Text(
                  'REGULATORY VERDICT (तपासणी निकाल):',
                  style: AppTypography.captionSmall.copyWith(
                    fontWeight: FontWeight.w700,
                    color: _statusColor,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: AppSpacing.s8),

                Container(
                  padding: const EdgeInsets.all(AppSpacing.l16),
                  decoration: BoxDecoration(
                    color: _statusBg,
                    borderRadius: AppRadius.button,
                    border: Border.all(color: _statusColor.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        _isNoObjection
                            ? Icons.info_outline_rounded
                            : Icons.warning_amber_rounded,
                        color: _statusColor,
                        size: 22,
                      ),
                      const SizedBox(width: AppSpacing.s8),
                      Expanded(
                        child: Text(
                          _verdictMessage,
                          style: AppTypography.bodyLarge.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.soilCharcoal,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.l16),

                // Safety Principle Reinforcement Banner
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.m12,
                    vertical: AppSpacing.s8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.warmSurface,
                    borderRadius: AppRadius.chip,
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.shield_outlined,
                        color: AppColors.fieldSlate,
                        size: 16,
                      ),
                      const SizedBox(width: AppSpacing.s8),
                      Expanded(
                        child: Text(
                          'Safety Rule: Veto check only. The printed bottle label remains the sole authority for dosage.',
                          style: AppTypography.captionSmall.copyWith(
                            color: AppColors.fieldSlate,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.l16),

                // Action Buttons
                Row(
                  children: [
                    if (_isVetoed || _isNotInRecords) ...[
                      Expanded(
                        child: AppButton.outline(
                          label: 'Retake Photo',
                          onPressed: onRetakePhoto,
                          leadingIcon: const Icon(Icons.camera_alt_outlined, size: 18),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.s8),
                      Expanded(
                        child: AppButton.danger(
                          label: 'Ask Expert',
                          onPressed: onAskExpert,
                          leadingIcon: const Icon(Icons.support_agent_rounded, size: 18),
                        ),
                      ),
                    ] else ...[
                      Expanded(
                        child: AppButton.primary(
                          label: 'Acknowledge & Follow Label',
                          onPressed: onRetakePhoto,
                          leadingIcon: const Icon(Icons.check_rounded, size: 18),
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

  Widget _buildExtractRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: AppTypography.captionSmall.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.fieldSlate,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.s8),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.soilCharcoal,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }
}
