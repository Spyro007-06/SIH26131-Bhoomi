import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/localization/locale_provider.dart';
import '../../../widgets/app_loading.dart';

/// Branded startup initialization screen.
/// Rendered exclusively during AuthStatus.initializing while secure storage is read.
class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(stringsProvider);

    return Scaffold(
      backgroundColor: AppColors.ricePaper,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Brand Emblem
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.forest, width: 2.5),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.eco_rounded,
                      size: 52,
                      color: AppColors.forest,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.l24),

                // App Title
                Text(
                  strings.appName,
                  style: AppTypography.display.copyWith(
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: AppSpacing.s8),

                // Subtitle
                Text(
                  strings.appTagline,
                  textAlign: TextAlign.center,
                  style: AppTypography.subheading.copyWith(
                    color: AppColors.fieldSlate,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl48),

                // Tactile Loading Indicator
                AppLoading(
                  message: strings.loading,
                  color: AppColors.forest,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
