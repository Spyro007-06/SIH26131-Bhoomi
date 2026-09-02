import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/localization/locale_provider.dart';
import '../../../widgets/app_button.dart';
import '../../../widgets/language_selector_button.dart';
import 'diagnosis_loading_screen.dart';

/// Image Preview & Confirmation Screen for Crop Diagnosis.
class ImagePreviewScreen extends ConsumerWidget {
  final Uint8List imageBytes;

  const ImagePreviewScreen({
    super.key,
    required this.imageBytes,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(stringsProvider);

    return Scaffold(
      backgroundColor: AppColors.ricePaper,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.forest),
          tooltip: 'Back',
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          strings.previewTitle,
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
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.l20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Hint Banner
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.l16,
                  vertical: AppSpacing.m12,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: AppRadius.input,
                  border: Border.all(color: AppColors.forest.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_outline_rounded, color: AppColors.forest, size: 20),
                    const SizedBox(width: AppSpacing.s8),
                    Expanded(
                      child: Text(
                        strings.previewHint,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.forest,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.l16),

              // Image Preview Card
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.warmSurface,
                    borderRadius: AppRadius.card,
                    border: Border.all(color: AppColors.border, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.soilCharcoal.withValues(alpha: 0.06),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Image.memory(
                    imageBytes,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.image_outlined, size: 64, color: AppColors.fieldSlate),
                            const SizedBox(height: AppSpacing.s8),
                            Text(
                              'Sample Crop Photo Preview',
                              style: AppTypography.bodyMedium.copyWith(
                                color: AppColors.fieldSlate,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.l20),

              // Action Buttons
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppButton.primary(
                    label: strings.usePhotoButton,
                    size: AppButtonSize.large,
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const DiagnosisLoadingScreen(),
                        ),
                      );
                    },
                    leadingIcon: const Icon(Icons.check_circle_rounded, color: Colors.white),
                  ),
                  const SizedBox(height: AppSpacing.m12),
                  AppButton.outline(
                    label: strings.retakeButton,
                    size: AppButtonSize.normal,
                    onPressed: () => Navigator.of(context).pop(),
                    leadingIcon: const Icon(Icons.refresh_rounded, color: AppColors.forest),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
