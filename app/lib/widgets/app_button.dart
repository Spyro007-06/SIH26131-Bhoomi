import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_radius.dart';

enum AppButtonVariant {
  primary,
  secondary,
  danger,
  outline,
  ghost,
}

enum AppButtonSize {
  large,  // 56px height (Hero / primary actions)
  normal, // 52px height (Default)
  small,  // 44px height (Compact secondary)
}

/// Tactile, accessible button designed for high outdoor visibility.
/// Meets minimum touch target of 48-56px for primary farmer interactions.
class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final Widget? leadingIcon;
  final Widget? trailingIcon;
  final bool isLoading;
  final bool isFullWidth;

  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.normal,
    this.leadingIcon,
    this.trailingIcon,
    this.isLoading = false,
    this.isFullWidth = false,
  });

  /// Factory constructor for Primary Forest Green Button
  const AppButton.primary({
    super.key,
    required this.label,
    required this.onPressed,
    this.size = AppButtonSize.normal,
    this.leadingIcon,
    this.trailingIcon,
    this.isLoading = false,
    this.isFullWidth = false,
  }) : variant = AppButtonVariant.primary;

  /// Factory constructor for Secondary Paddy Green / Light Button
  const AppButton.secondary({
    super.key,
    required this.label,
    required this.onPressed,
    this.size = AppButtonSize.normal,
    this.leadingIcon,
    this.trailingIcon,
    this.isLoading = false,
    this.isFullWidth = false,
  }) : variant = AppButtonVariant.secondary;

  /// Factory constructor for Danger Muted Red Button
  const AppButton.danger({
    super.key,
    required this.label,
    required this.onPressed,
    this.size = AppButtonSize.normal,
    this.leadingIcon,
    this.trailingIcon,
    this.isLoading = false,
    this.isFullWidth = false,
  }) : variant = AppButtonVariant.danger;

  /// Factory constructor for Outlined Border Button
  const AppButton.outline({
    super.key,
    required this.label,
    required this.onPressed,
    this.size = AppButtonSize.normal,
    this.leadingIcon,
    this.trailingIcon,
    this.isLoading = false,
    this.isFullWidth = false,
  }) : variant = AppButtonVariant.outline;

  /// Factory constructor for Ghost / Text Button
  const AppButton.ghost({
    super.key,
    required this.label,
    required this.onPressed,
    this.size = AppButtonSize.normal,
    this.leadingIcon,
    this.trailingIcon,
    this.isLoading = false,
    this.isFullWidth = false,
  }) : variant = AppButtonVariant.ghost;

  double get _height {
    switch (size) {
      case AppButtonSize.large:
        return AppSpacing.largeActionButtonHeight;
      case AppButtonSize.normal:
        return AppSpacing.primaryButtonHeight;
      case AppButtonSize.small:
        return AppSpacing.minTouchTarget;
    }
  }

  Color _getBackgroundColor(BuildContext context) {
    if (onPressed == null && !isLoading) {
      return AppColors.border;
    }
    switch (variant) {
      case AppButtonVariant.primary:
        return AppColors.forest;
      case AppButtonVariant.secondary:
        return AppColors.paddyGreen;
      case AppButtonVariant.danger:
        return AppColors.danger;
      case AppButtonVariant.outline:
      case AppButtonVariant.ghost:
        return Colors.transparent;
    }
  }

  Color _getForegroundColor(BuildContext context) {
    if (onPressed == null && !isLoading) {
      return AppColors.fieldSlate;
    }
    switch (variant) {
      case AppButtonVariant.primary:
      case AppButtonVariant.secondary:
      case AppButtonVariant.danger:
        return AppColors.pureWhite;
      case AppButtonVariant.outline:
        return AppColors.forest;
      case AppButtonVariant.ghost:
        return AppColors.forest;
    }
  }

  BorderSide _getBorderSide(BuildContext context) {
    if (variant == AppButtonVariant.outline) {
      final color = onPressed == null ? AppColors.border : AppColors.forest;
      return BorderSide(color: color, width: 1.5);
    }
    return BorderSide.none;
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = _getBackgroundColor(context);
    final fgColor = _getForegroundColor(context);
    final borderSide = _getBorderSide(context);

    final content = Row(
      mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading) ...[
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(fgColor),
            ),
          ),
          const SizedBox(width: AppSpacing.m12),
        ] else if (leadingIcon != null) ...[
          IconTheme(
            data: IconThemeData(color: fgColor, size: 22),
            child: leadingIcon!,
          ),
          const SizedBox(width: AppSpacing.s8),
        ],
        Flexible(
          child: Text(
            label,
            style: (size == AppButtonSize.small ? AppTypography.buttonSmall : AppTypography.button)
                .copyWith(color: fgColor),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (trailingIcon != null && !isLoading) ...[
          const SizedBox(width: AppSpacing.s8),
          IconTheme(
            data: IconThemeData(color: fgColor, size: 22),
            child: trailingIcon!,
          ),
        ],
      ],
    );

    final buttonStyle = RawMaterialButton(
      onPressed: isLoading ? null : onPressed,
      elevation: 0,
      focusElevation: 0,
      hoverElevation: 0,
      highlightElevation: 1,
      fillColor: bgColor,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.button,
        side: borderSide,
      ),
      constraints: BoxConstraints(
        minHeight: _height,
        minWidth: isFullWidth ? double.infinity : AppSpacing.minTouchTarget,
      ),
      padding: EdgeInsets.symmetric(
        horizontal: size == AppButtonSize.small ? AppSpacing.m12 : AppSpacing.l16,
        vertical: AppSpacing.s8,
      ),
      child: content,
    );

    if (isFullWidth) {
      return SizedBox(
        width: double.infinity,
        height: _height,
        child: buttonStyle,
      );
    }

    return SizedBox(
      height: _height,
      child: buttonStyle,
    );
  }
}
