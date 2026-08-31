import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../core/theme/app_spacing.dart';

/// Calm, respectful loading state with clear human context.
class AppLoading extends StatelessWidget {
  final String? message;
  final bool isFullScreen;
  final Color? color;

  const AppLoading({
    super.key,
    this.message,
    this.isFullScreen = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final content = Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 44,
              height: 44,
              child: CircularProgressIndicator(
                strokeWidth: 3.5,
                valueColor: AlwaysStoppedAnimation<Color>(color ?? AppColors.forest),
              ),
            ),
            if (message != null) ...[
              const SizedBox(height: AppSpacing.l16),
              Text(
                message!,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.soilCharcoal,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );

    if (isFullScreen) {
      return Scaffold(
        backgroundColor: AppColors.ricePaper,
        body: SafeArea(child: content),
      );
    }

    return content;
  }
}
