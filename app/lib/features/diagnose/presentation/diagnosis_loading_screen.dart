import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/localization/locale_provider.dart';
import '../../../core/localization/app_strings.dart';
import '../../../providers/farm_providers.dart';
import '../../../widgets/app_loading.dart';
import '../../../widgets/app_button.dart';
import '../../../widgets/language_selector_button.dart';
import 'diagnosis_controller.dart';
import 'advisory_result_screen.dart';
import 'escalation_status_screen.dart';
import '../../doubt_doctor/presentation/doubt_doctor_screen.dart';

/// Calm progress loading screen during presigned upload and confidence gate diagnosis.
class DiagnosisLoadingScreen extends ConsumerStatefulWidget {
  const DiagnosisLoadingScreen({super.key});

  @override
  ConsumerState<DiagnosisLoadingScreen> createState() => _DiagnosisLoadingScreenState();
}

class _DiagnosisLoadingScreenState extends ConsumerState<DiagnosisLoadingScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startDiagnosis();
    });
  }

  Future<void> _startDiagnosis() async {
    final activeFarmId = ref.read(activeFarmIdProvider) ?? 'f_1';
    final language = ref.read(appLanguageProvider);
    final langCode = '${language.code}-IN';

    try {
      final response = await ref.read(diagnosisControllerProvider.notifier).submitDiagnosis(
            farmId: activeFarmId,
            lang: langCode,
          );

      if (!mounted || response == null) return;

      // Confidence Gate Routing (Backend is source of truth)
      if (response.isAdvise) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => AdvisoryResultScreen(response: response),
          ),
        );
      } else if (response.isClarify) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => DoubtDoctorScreen(response: response),
          ),
        );
      } else if (response.isEscalate) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => EscalationStatusScreen(response: response),
          ),
        );
      }
    } catch (_) {
      // Error state is captured in diagnosisControllerProvider
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(stringsProvider);
    final diagState = ref.watch(diagnosisControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.ricePaper,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: diagState.isError,
        actions: const [
          LanguageSelectorButton(),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl28),
          child: Center(
            child: diagState.isError
                ? _buildErrorView(strings, diagState)
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Animated scanning emblem
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.forest, width: 3),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.document_scanner_rounded,
                            size: 48,
                            color: AppColors.forest,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl32),

                      // Title
                      Text(
                        strings.checkingPhotoTitle,
                        textAlign: TextAlign.center,
                        style: AppTypography.subheading.copyWith(
                          color: AppColors.primaryDark,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.s8),

                      // Subtitle
                      Text(
                        strings.checkingPhotoSubtitle,
                        textAlign: TextAlign.center,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.fieldSlate,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl32),

                      // Tactile loading spinner
                      AppLoading(
                        message: diagState.isUploading
                            ? strings.uploadingPhoto
                            : strings.loading,
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorView(AppStrings strings, DiagnosisState state) {
    final isUploadErr = (state.errorMessage ?? '').contains('PHOTO_UPLOAD_FAILED');
    final title = isUploadErr ? strings.uploadFailedTitle : strings.diagnosisTimeoutTitle;
    final message = isUploadErr ? strings.uploadFailedDesc : strings.diagnosisTimeoutDesc;

    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.l20),
            decoration: BoxDecoration(
              color: AppColors.danger.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.cloud_off_rounded,
              size: 56,
              color: AppColors.danger,
            ),
          ),
          const SizedBox(height: AppSpacing.l20),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTypography.subheading.copyWith(
              color: AppColors.soilCharcoal,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.s8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTypography.body.copyWith(
              color: AppColors.fieldSlate,
            ),
          ),
          const SizedBox(height: AppSpacing.xl32),

          AppButton.primary(
            label: strings.retryAction,
            size: AppButtonSize.large,
            onPressed: _startDiagnosis,
            leadingIcon: const Icon(Icons.refresh_rounded, color: Colors.white),
          ),
          const SizedBox(height: AppSpacing.m12),

          AppButton.secondary(
            label: strings.changePhotoAction,
            size: AppButtonSize.large,
            onPressed: () => Navigator.of(context).pop(),
            leadingIcon: const Icon(Icons.photo_camera_rounded),
          ),
        ],
      ),
    );
  }
}
