import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/localization/locale_provider.dart';
import '../../../widgets/app_card.dart';
import '../../../widgets/stub_banner.dart';
import '../../../widgets/language_selector_button.dart';

/// Check Crop placeholder screen for Step 3.
/// Visual entrypoint for the upcoming camera diagnosis workflow.
class CheckCropPlaceholderScreen extends ConsumerWidget {
  const CheckCropPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(stringsProvider);

    return Scaffold(
      backgroundColor: AppColors.ricePaper,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          strings.navCheckCrop,
          style: AppTypography.subheading.copyWith(
            color: AppColors.primaryDark,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: const [
          LanguageSelectorButton(),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.l20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const StubBanner(
                message: 'Camera Diagnosis workflow will be activated in Step 4.',
              ),
              const SizedBox(height: AppSpacing.l20),

              // Diagnostic Camera Placeholder Card
              AppCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.l20,
                  vertical: AppSpacing.xxl48,
                ),
                child: Column(
                  children: [
                    Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.forest, width: 2),
                      ),
                      child: const Icon(
                        Icons.add_a_photo_rounded,
                        size: 44,
                        color: AppColors.forest,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.l24),
                    Text(
                      strings.checkCropBannerTitle,
                      textAlign: TextAlign.center,
                      style: AppTypography.subheading.copyWith(
                        color: AppColors.soilCharcoal,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s8),
                    Text(
                      'Take a clear photograph of affected leaves or pests. Our confidence-gated diagnostic engine will identify the issue.',
                      textAlign: TextAlign.center,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.fieldSlate,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
