import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:bhoomi/core/theme/app_colors.dart';
import 'package:bhoomi/core/theme/app_typography.dart';
import 'package:bhoomi/core/theme/app_spacing.dart';
import 'package:bhoomi/core/theme/app_radius.dart';
import 'package:bhoomi/core/constants/app_constants.dart';

void main() {
  group('Design Tokens Verification', () {
    test('AppColors matches exact specification hex codes', () {
      expect(AppColors.forest, const Color(0xFF245C45));
      expect(AppColors.primaryDark, const Color(0xFF174432));
      expect(AppColors.primaryLight, const Color(0xFFDDEBE2));
      expect(AppColors.paddyGreen, const Color(0xFF5F8F45));
      expect(AppColors.ricePaper, const Color(0xFFF7F5EE));
      expect(AppColors.warmSurface, const Color(0xFFFFFDF8));
      expect(AppColors.soilCharcoal, const Color(0xFF202A25));
      expect(AppColors.fieldSlate, const Color(0xFF66736B));
      expect(AppColors.border, const Color(0xFFD8DED8));
      expect(AppColors.turmeric, const Color(0xFFD69A2D));
      expect(AppColors.warning, const Color(0xFFC98224));
      expect(AppColors.warningBg, const Color(0xFFFFF1D6));
      expect(AppColors.danger, const Color(0xFFB94A48));
      expect(AppColors.dangerBg, const Color(0xFFFCE8E6));
      expect(AppColors.success, const Color(0xFF3F7D4A));
      expect(AppColors.successBg, const Color(0xFFE6F2E8));
      expect(AppColors.info, const Color(0xFF3F7180));
      expect(AppColors.infoBg, const Color(0xFFE6F1F4));
    });

    test('Primary farmer text sizes satisfy >= 16px invariant', () {
      expect(AppTypography.body.fontSize, greaterThanOrEqualTo(16.0));
      expect(AppTypography.bodyMedium.fontSize, greaterThanOrEqualTo(16.0));
      expect(AppTypography.bodyLarge.fontSize, greaterThanOrEqualTo(18.0));
      expect(AppTypography.button.fontSize, greaterThanOrEqualTo(16.0));
      expect(AppTypography.sectionTitle.fontSize, greaterThanOrEqualTo(18.0));
      expect(AppTypography.screenTitle.fontSize, greaterThanOrEqualTo(24.0));
      expect(AppTypography.display.fontSize, greaterThanOrEqualTo(30.0));
    });

    test('AppSpacing scale and touch targets satisfy accessibility minimums', () {
      expect(AppSpacing.xs4, 4.0);
      expect(AppSpacing.s8, 8.0);
      expect(AppSpacing.m12, 12.0);
      expect(AppSpacing.l16, 16.0);
      expect(AppSpacing.xl20, 20.0);
      expect(AppSpacing.xxl24, 24.0);
      expect(AppSpacing.xxxl32, 32.0);
      expect(AppSpacing.huge40, 40.0);

      expect(AppSpacing.minTouchTarget, greaterThanOrEqualTo(44.0));
      expect(AppSpacing.primaryButtonHeight, greaterThanOrEqualTo(48.0));
      expect(AppSpacing.largeActionButtonHeight, greaterThanOrEqualTo(56.0));
    });

    test('AppRadius tokens match shape specifications', () {
      expect(AppRadius.cardValue, 16.0);
      expect(AppRadius.buttonValue, 14.0);
      expect(AppRadius.inputValue, 14.0);
      expect(AppRadius.sheetValue, 24.0);
      expect(AppRadius.chipValue, 10.0);
    });

    test('Gate thresholds match frozen specifications (DESIGN.md §6)', () {
      expect(AppConstants.gateThreshold, 0.70);
      expect(AppConstants.floorThreshold, 0.45);
      expect(AppConstants.marginThreshold, 0.15);
    });

    test('Veto Invariant: Verdict strings contain zero endorsement vocabulary', () {
      const forbiddenWords = ['safe', 'approved', 'you can use', 'recommended'];

      for (final entry in AppConstants.verdictMessages.entries) {
        final messageLower = entry.value.toLowerCase();
        for (final forbidden in forbiddenWords) {
          expect(
            messageLower.contains(forbidden),
            isFalse,
            reason: 'Verdict code ${entry.key} contains forbidden endorsement word: "$forbidden"',
          );
        }
      }
    });

    test('No objection found verdict exact wording matches specification', () {
      expect(
        AppConstants.verdictMessages['NO_OBJECTION_FOUND'],
        'No objection found. Follow the printed label for dosage.',
      );
    });
  });
}
