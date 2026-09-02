import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_radius.dart';

enum BadgeType {
  primary,
  success,
  warning,
  danger,
  info,
  neutral,
  severity,
}

typedef StatusBadgeType = BadgeType;

/// Semantic status badge with icon and high-contrast text.
/// Avoids color-only meaning by always pairing color with text/icon reinforcement.
class AppStatusBadge extends StatelessWidget {
  final String label;
  final Widget? icon;
  final BadgeType type;
  final bool isSmall;

  const AppStatusBadge({
    super.key,
    String? label,
    String? text,
    String? status,
    this.icon,
    BadgeType? type,
    BadgeType? variant,
    this.isSmall = false,
  })  : label = label ?? text ?? status ?? '',
        type = type ?? variant ?? BadgeType.neutral;

  /// Factory for High Risk Badge
  const AppStatusBadge.highRisk({
    super.key,
    this.label = 'HIGH RISK',
    this.icon = const Icon(Icons.warning_amber_rounded, size: 16),
    this.isSmall = false,
  }) : type = BadgeType.danger;

  /// Factory for Moderate / Medium Risk Badge
  const AppStatusBadge.mediumRisk({
    super.key,
    this.label = 'MEDIUM RISK',
    this.icon = const Icon(Icons.info_outline_rounded, size: 16),
    this.isSmall = false,
  }) : type = BadgeType.warning;

  /// Factory for Low Risk / Safe Badge
  const AppStatusBadge.lowRisk({
    super.key,
    this.label = 'LOW RISK',
    this.icon = const Icon(Icons.check_circle_outline_rounded, size: 16),
    this.isSmall = false,
  }) : type = BadgeType.success;

  /// Factory for Info / Neutral Badge
  const AppStatusBadge.info({
    super.key,
    required this.label,
    this.icon,
    this.isSmall = false,
  }) : type = BadgeType.info;

  /// Factory for Gate: Advise
  const AppStatusBadge.advise({
    super.key,
    this.label = 'CONFIDENT DIAGNOSIS',
    this.icon = const Icon(Icons.verified_rounded, size: 16),
    this.isSmall = false,
  }) : type = BadgeType.primary;

  /// Factory for Gate: Clarify (Doubt Doctor)
  const AppStatusBadge.clarify({
    super.key,
    this.label = 'ONE OBSERVATION NEEDED',
    this.icon = const Icon(Icons.help_outline_rounded, size: 16),
    this.isSmall = false,
  }) : type = BadgeType.warning;

  /// Factory for Gate: Escalate
  const AppStatusBadge.escalate({
    super.key,
    this.label = 'EXPERT REVIEW NEEDED',
    this.icon = const Icon(Icons.support_agent_rounded, size: 16),
    this.isSmall = false,
  }) : type = BadgeType.danger;

  /// Factory for Demonstration / Stub Badge
  const AppStatusBadge.stub({
    super.key,
    this.label = 'DEMO STUB',
    this.icon = const Icon(Icons.science_outlined, size: 16),
    this.isSmall = false,
  }) : type = BadgeType.warning;

  Color get _backgroundColor {
    switch (type) {
      case BadgeType.primary:
        return AppColors.primaryLight;
      case BadgeType.success:
        return AppColors.successBg;
      case BadgeType.warning:
        return AppColors.warningBg;
      case BadgeType.danger:
        return AppColors.dangerBg;
      case BadgeType.info:
        return AppColors.infoBg;
      case BadgeType.neutral:
        return AppColors.border;
      case BadgeType.severity:
        return AppColors.warningBg;
    }
  }

  Color get _textColor {
    switch (type) {
      case BadgeType.primary:
        return AppColors.forest;
      case BadgeType.success:
        return AppColors.success;
      case BadgeType.warning:
        return AppColors.warning;
      case BadgeType.danger:
        return AppColors.danger;
      case BadgeType.info:
        return AppColors.info;
      case BadgeType.neutral:
        return AppColors.soilCharcoal;
      case BadgeType.severity:
        return AppColors.warning;
    }
  }

  Color get _borderColor {
    switch (type) {
      case BadgeType.primary:
        return AppColors.forest.withValues(alpha: 0.3);
      case BadgeType.success:
        return AppColors.success.withValues(alpha: 0.4);
      case BadgeType.warning:
        return AppColors.warning.withValues(alpha: 0.4);
      case BadgeType.danger:
        return AppColors.danger.withValues(alpha: 0.4);
      case BadgeType.info:
        return AppColors.info.withValues(alpha: 0.4);
      case BadgeType.neutral:
        return AppColors.border;
      case BadgeType.severity:
        return AppColors.warning.withValues(alpha: 0.4);
    }
  }

  @override
  Widget build(BuildContext context) {
    final fg = _textColor;
    final bg = _backgroundColor;
    final border = _borderColor;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmall ? AppSpacing.s8 : AppSpacing.m12,
        vertical: isSmall ? AppSpacing.xs4 : AppSpacing.s8,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppRadius.chip,
        border: Border.all(color: border, width: 1.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (icon != null) ...[
            IconTheme(
              data: IconThemeData(
                color: fg,
                size: isSmall ? 14 : 16,
              ),
              child: icon!,
            ),
            SizedBox(width: isSmall ? AppSpacing.xs4 : AppSpacing.s8),
          ],
          Text(
            label,
            style: (isSmall ? AppTypography.captionSmall : AppTypography.badge).copyWith(
              color: fg,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
