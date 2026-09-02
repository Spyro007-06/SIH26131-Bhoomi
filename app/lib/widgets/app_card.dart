import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_radius.dart';

/// Base Card widget for Bhoomi v2.
/// Uses Warm Surface (#FFFDF8) background, 16px radius, and subtle border (#D8DED8).
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color backgroundColor;
  final Color borderColor;
  final double borderWidth;
  final Color? accentStripeColor;
  final double accentStripeWidth;
  final VoidCallback? onTap;
  final double? width;
  final double? height;
  final BoxBorder? border;

  const AppCard({
    super.key,
    required this.child,
    this.padding = AppSpacing.cardPadding,
    this.backgroundColor = AppColors.warmSurface,
    this.borderColor = AppColors.border,
    this.borderWidth = 1.0,
    this.accentStripeColor,
    this.accentStripeWidth = 6.0,
    this.onTap,
    this.width,
    this.height,
    this.border,
  });

  /// Factory for an Alert / Warning Card with an Amber accent stripe
  const AppCard.warning({
    super.key,
    required this.child,
    this.padding = AppSpacing.cardPadding,
    this.backgroundColor = AppColors.warmSurface,
    this.borderColor = AppColors.border,
    this.borderWidth = 1.0,
    this.onTap,
    this.width,
    this.height,
    this.border,
  })  : accentStripeColor = AppColors.turmeric,
        accentStripeWidth = 6.0;

  /// Factory for a Danger / Veto Card with a Muted Red accent stripe
  const AppCard.danger({
    super.key,
    required this.child,
    this.padding = AppSpacing.cardPadding,
    this.backgroundColor = AppColors.warmSurface,
    this.borderColor = AppColors.border,
    this.borderWidth = 1.0,
    this.onTap,
    this.width,
    this.height,
    this.border,
  })  : accentStripeColor = AppColors.danger,
        accentStripeWidth = 6.0;

  /// Factory for an Advise / Success Card with a Forest Green accent stripe
  const AppCard.success({
    super.key,
    required this.child,
    this.padding = AppSpacing.cardPadding,
    this.backgroundColor = AppColors.warmSurface,
    this.borderColor = AppColors.border,
    this.borderWidth = 1.0,
    this.onTap,
    this.width,
    this.height,
    this.border,
  })  : accentStripeColor = AppColors.forest,
        accentStripeWidth = 6.0;

  @override
  Widget build(BuildContext context) {
    Widget cardContent = child;

    if (accentStripeColor != null) {
      cardContent = ClipRRect(
        borderRadius: AppRadius.card,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: accentStripeWidth,
                color: accentStripeColor,
              ),
              Expanded(
                child: Padding(
                  padding: padding,
                  child: child,
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      cardContent = Padding(
        padding: padding,
        child: child,
      );
    }

    final cardContainer = Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: AppRadius.card,
        border: border ??
            Border.all(
              color: borderColor,
              width: borderWidth,
            ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: AppRadius.card,
        child: onTap != null
            ? InkWell(
                onTap: onTap,
                borderRadius: AppRadius.card,
                splashColor: AppColors.primaryLight.withValues(alpha: 0.5),
                highlightColor: AppColors.primaryLight.withValues(alpha: 0.2),
                child: cardContent,
              )
            : cardContent,
      ),
    );

    return cardContainer;
  }
}
