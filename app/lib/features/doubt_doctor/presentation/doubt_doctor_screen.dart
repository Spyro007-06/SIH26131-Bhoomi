import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/localization/locale_provider.dart';
import '../../../models/diagnosis_models.dart';
import '../../../providers/repository_providers.dart';
import '../../../widgets/app_button.dart';
import '../../../widgets/app_card.dart';
import '../../../widgets/stub_banner.dart';
import '../../../widgets/language_selector_button.dart';
import '../../diagnose/presentation/advisory_result_screen.dart';
import '../../diagnose/presentation/escalation_status_screen.dart';

/// Doubt Doctor Visual Differential Diagnosis Screen.
/// Activated when Confidence Gate outcome is 'clarify'.
class DoubtDoctorScreen extends ConsumerStatefulWidget {
  final DiagnoseResponse response;

  const DoubtDoctorScreen({
    super.key,
    required this.response,
  });

  @override
  ConsumerState<DoubtDoctorScreen> createState() => _DoubtDoctorScreenState();
}

class _DoubtDoctorScreenState extends ConsumerState<DoubtDoctorScreen> {
  bool _isSubmitting = false;
  String? _errorMessage;

  Future<void> _handleAnswer(String answer) async {
    final problemId = widget.response.problemId ?? 'p_1';
    final cueId = widget.response.clarification?.cueId ?? 'cue_1';

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final doubtDoctorRepo = ref.read(doubtDoctorRepositoryProvider);
      final result = await doubtDoctorRepo.submitAnswer(
        problemId: problemId,
        cueId: cueId,
        answer: answer,
      );

      if (!mounted) return;
      setState(() => _isSubmitting = false);

      if (result.resolved) {
        // Resolved Branch -> Show Advisory
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => AdvisoryResultScreen(
              resolvedDiagnosis: result.diagnosis,
              resolvedAdvisory: result.advisory,
              resolvedSpokenSummary: result.spokenSummary,
              gate: widget.response.gate,
            ),
          ),
        );
      } else {
        // Unresolved Branch -> Escalate to Expert
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => EscalationStatusScreen(
              escalation: result.escalation,
              unresolvedReason: result.reason,
              spokenSummary: result.spokenSummary,
              isStub: widget.response.gate.isStub,
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      final strings = ref.read(stringsProvider);
      setState(() {
        _isSubmitting = false;
        _errorMessage = strings.genericError;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(stringsProvider);
    final isStub = widget.response.gate.isStub;
    final clarification = widget.response.clarification;
    final candidates = clarification?.candidates ?? [];
    final question = clarification?.questionLocalized ??
        clarification?.question ??
        'Flip the leaf over. Do you see fuzzy grey growth on the underside?';

    return Scaffold(
      backgroundColor: AppColors.ricePaper,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.forest),
          tooltip: 'Back to Home',
          onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
        ),
        title: Text(
          strings.doubtDoctorTitle,
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
              // Stub mode banner if is_stub == true
              if (isStub) ...[
                const StubBanner(
                  message: 'Demonstration Mode: Ambiguity gate resolution handled by mock engine.',
                ),
                const SizedBox(height: AppSpacing.m16),
              ],

              // Header Explanation
              Text(
                strings.doubtDoctorSubtitle,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.fieldSlate,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: AppSpacing.l20),

              // Visual Candidate Comparison Cards (Candidate A vs Candidate B)
              if (candidates.length >= 2) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _CandidateCard(
                        candidate: candidates[0],
                        candidateTag: 'शक्यता १ (Candidate A)',
                      ),
                    ),
                    const SizedBox(width: AppSpacing.m12),
                    Expanded(
                      child: _CandidateCard(
                        candidate: candidates[1],
                        candidateTag: 'शक्यता २ (Candidate B)',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.l24),
              ],

              // Main Clarification Question Card
              AppCard(
                padding: const EdgeInsets.all(AppSpacing.l20),
                backgroundColor: AppColors.turmeric.withValues(alpha: 0.12),
                border: Border.all(color: AppColors.turmeric, width: 2.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.help_outline_rounded, color: AppColors.turmeric, size: 24),
                        const SizedBox(width: AppSpacing.s8),
                        Expanded(
                          child: Text(
                            'प्रत्यक्ष निरीक्षण प्रश्न (Field Check):',
                            style: AppTypography.bodyMedium.copyWith(
                              color: AppColors.soilCharcoal,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.m12),
                    Text(
                      question,
                      style: AppTypography.subheading.copyWith(
                        color: AppColors.primaryDark,
                        fontWeight: FontWeight.w800,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl32),

              if (_errorMessage != null) ...[
                Text(
                  _errorMessage!,
                  style: AppTypography.bodySmall.copyWith(color: AppColors.danger),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.m16),
              ],

              // 3 Tactile Answer Buttons (Large touch targets)
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // YES button
                  AppButton.primary(
                    label: strings.answerYes,
                    size: AppButtonSize.large,
                    isLoading: _isSubmitting,
                    onPressed: _isSubmitting ? null : () => _handleAnswer('yes'),
                    leadingIcon: const Icon(Icons.check_rounded, color: Colors.white),
                  ),
                  const SizedBox(height: AppSpacing.m12),

                  // NO button
                  AppButton.secondary(
                    label: strings.answerNo,
                    size: AppButtonSize.large,
                    isLoading: _isSubmitting,
                    onPressed: _isSubmitting ? null : () => _handleAnswer('no'),
                    leadingIcon: const Icon(Icons.close_rounded, color: AppColors.forest),
                  ),
                  const SizedBox(height: AppSpacing.m12),

                  // CAN'T TELL button
                  AppButton.outline(
                    label: strings.answerUnknown,
                    size: AppButtonSize.normal,
                    isLoading: _isSubmitting,
                    onPressed: _isSubmitting ? null : () => _handleAnswer('unknown'),
                    leadingIcon: const Icon(Icons.help_outline, color: AppColors.forest),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.l20),
            ],
          ),
        ),
      ),
    );
  }
}

class _CandidateCard extends StatelessWidget {
  final CandidateModel candidate;
  final String candidateTag;

  const _CandidateCard({
    required this.candidate,
    required this.candidateTag,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.m12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Candidate Tag
          Text(
            candidateTag,
            style: AppTypography.caption.copyWith(
              color: AppColors.fieldSlate,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),

          // Label
          Text(
            candidate.label.replaceAll('_', ' ').toUpperCase(),
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.forest,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.s8),

          // Candidate Photo / Placeholder
          Container(
            height: 90,
            decoration: BoxDecoration(
              color: AppColors.primaryLight.withValues(alpha: 0.5),
              borderRadius: AppRadius.input,
              border: Border.all(color: AppColors.border),
            ),
            clipBehavior: Clip.antiAlias,
            child: candidate.imageUrl != null && candidate.imageUrl!.isNotEmpty
                ? Image.network(
                    candidate.imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Center(
                      child: Icon(Icons.broken_image_rounded, color: AppColors.fieldSlate),
                    ),
                  )
                : const Center(
                    child: Icon(Icons.eco_rounded, color: AppColors.forest, size: 36),
                  ),
          ),
          const SizedBox(height: AppSpacing.s8),

          // Signature Text
          Text(
            candidate.signature,
            style: AppTypography.caption.copyWith(
              color: AppColors.soilCharcoal,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}
