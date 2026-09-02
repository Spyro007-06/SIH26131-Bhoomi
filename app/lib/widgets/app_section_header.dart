import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../core/theme/app_spacing.dart';

/// Clean Section Header for grouping content across farmer screens.
class AppSectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? icon;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;

  const AppSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.trailing,
    this.padding = const EdgeInsets.only(
      top: AppSpacing.xxl24,
      bottom: AppSpacing.m12,
    ),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (icon != null) ...[
            IconTheme(
              data: const IconThemeData(
                color: AppColors.forest,
                size: 22,
              ),
              child: icon!,
            ),
            const SizedBox(width: AppSpacing.s8),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: AppTypography.sectionTitle,
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: AppSpacing.xs4),
                  Text(
                    subtitle!,
                    style: AppTypography.caption,
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: AppSpacing.m12),
            trailing!,
          ],
        ],
      ),
    );
  }
}
