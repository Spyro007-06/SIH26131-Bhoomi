import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_radius.dart';
import '../core/localization/app_strings.dart';
import '../core/localization/locale_provider.dart';

/// Shows the global modal bottom sheet or dialog to select the active application language.
Future<void> showLanguageSelectionModal(BuildContext context, WidgetRef ref) {
  final currentLang = ref.read(appLanguageProvider);
  final strings = ref.read(stringsProvider);

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      return Container(
        padding: const EdgeInsets.only(
          left: AppSpacing.l20,
          right: AppSpacing.l20,
          top: AppSpacing.l20,
          bottom: AppSpacing.xl32,
        ),
        decoration: const BoxDecoration(
          color: AppColors.warmSurface,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(AppRadius.sheetValue),
            topRight: Radius.circular(AppRadius.sheetValue),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 16,
              offset: Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Sheet Drag Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.m16),

              // Title Header
              Row(
                children: [
                  const Text('🌐', style: TextStyle(fontSize: 22)),
                  const SizedBox(width: AppSpacing.s8),
                  Expanded(
                    child: Text(
                      strings.selectLanguageTitle,
                      style: AppTypography.subheading.copyWith(
                        color: AppColors.primaryDark,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: AppColors.fieldSlate),
                    tooltip: strings.cancel,
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.m12),

              // Language Options List
              ...AppLanguage.values.map((lang) {
                final isSelected = lang == currentLang;
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.s8),
                  child: Material(
                    color: isSelected
                        ? AppColors.primaryLight
                        : AppColors.warmSurface,
                    borderRadius: AppRadius.card,
                    child: InkWell(
                      borderRadius: AppRadius.card,
                      onTap: () {
                        ref.read(appLanguageProvider.notifier).setLanguage(lang);
                        Navigator.of(ctx).pop();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.l16,
                          vertical: AppSpacing.m12,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: AppRadius.card,
                          border: Border.all(
                            color: isSelected ? AppColors.forest : AppColors.border,
                            width: isSelected ? 2.0 : 1.0,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isSelected
                                  ? Icons.radio_button_checked_rounded
                                  : Icons.radio_button_off_rounded,
                              color: isSelected ? AppColors.forest : AppColors.fieldSlate,
                              size: 22,
                            ),
                            const SizedBox(width: AppSpacing.m12),
                            Expanded(
                              child: Text(
                                lang.label,
                                style: AppTypography.bodyMedium.copyWith(
                                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                  color: isSelected ? AppColors.forest : AppColors.soilCharcoal,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            if (isSelected)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.s8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.forest,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  'सक्रिय',
                                  style: AppTypography.captionSmall.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      );
    },
  );
}

/// Compact, accessible, responsive Global Language Selector Button.
/// Can be embedded in AppBars or screen headers across the entire app.
class LanguageSelectorButton extends ConsumerWidget {
  final bool isDarkBackground;
  final EdgeInsetsGeometry? margin;

  const LanguageSelectorButton({
    super.key,
    this.isDarkBackground = false,
    this.margin,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final language = ref.watch(appLanguageProvider);

    final fgColor = isDarkBackground ? Colors.white : AppColors.forest;
    final bgColor = isDarkBackground
        ? Colors.black.withValues(alpha: 0.35)
        : AppColors.primaryLight.withValues(alpha: 0.7);
    final borderColor = isDarkBackground
        ? Colors.white.withValues(alpha: 0.4)
        : AppColors.forest.withValues(alpha: 0.3);

    return Semantics(
      button: true,
      label: 'भाषा निवडा. सध्याची भाषा: ${language.label}',
      child: Container(
        margin: margin ?? const EdgeInsets.symmetric(horizontal: AppSpacing.s8, vertical: 8),
        child: Material(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => showLanguageSelectionModal(context, ref),
            child: Container(
              constraints: const BoxConstraints(
                minHeight: 36,
                minWidth: 44,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.s10,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: borderColor, width: 1.2),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    '🌐',
                    style: TextStyle(fontSize: 14),
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      language.label,
                      style: AppTypography.bodySmall.copyWith(
                        color: fgColor,
                        fontWeight: FontWeight.w700,
                        height: 1.1,
                      ),
                      softWrap: false,
                      overflow: TextOverflow.fade,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
