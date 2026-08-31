import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/localization/locale_provider.dart';
import '../../../models/diagnosis_models.dart';
import '../../../widgets/app_button.dart';
import '../../../widgets/app_card.dart';
import '../../../widgets/stub_banner.dart';

/// Screen displayed when Confidence Gate outcome is 'escalate' or Doubt Doctor is unresolved.
class EscalationStatusScreen extends ConsumerWidget {
  final DiagnoseResponse? response;
  final EscalationModel? escalation;
  final String? unresolvedReason;
  final String? spokenSummary;
  final bool isStub;

  const EscalationStatusScreen({
    super.key,
    this.response,
    this.escalation,
    this.unresolvedReason,
    this.spokenSummary,
    this.isStub = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(stringsProvider);

    final isStubMode = response?.gate.isStub ?? isStub;
    final esc = response?.escalation ?? escalation;
    final audioSummary = response?.spokenSummary ?? spokenSummary;

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
          strings.escalateTitle,
          style: AppTypography.subheading.copyWith(
            color: AppColors.primaryDark,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.l20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Stub mode banner if is_stub == true
              if (isStubMode) ...[
                const StubBanner(
                  message: 'Demonstration Mode: Expert routing simulated by mock engine.',
                ),
                const SizedBox(height: AppSpacing.m16),
              ],

              // Escalation Header Banner
              AppCard(
                padding: const EdgeInsets.all(AppSpacing.l20),
                backgroundColor: AppColors.danger.withValues(alpha: 0.08),
                border: Border.all(color: AppColors.danger, width: 1.5),
                child: Column(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: AppColors.danger.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.support_agent_rounded,
                        color: AppColors.danger,
                        size: 36,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.l16),
                    Text(
                      strings.escalateTitle,
                      textAlign: TextAlign.center,
                      style: AppTypography.subheading.copyWith(
                        color: AppColors.danger,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s8),
                    Text(
                      strings.escalateSubtitle,
                      textAlign: TextAlign.center,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.soilCharcoal,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.l20),

              // Case Assignment Details Card
              AppCard(
                padding: const EdgeInsets.all(AppSpacing.l16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Case ID
                    _DetailRow(
                      icon: Icons.confirmation_number_outlined,
                      label: strings.caseIdLabel,
                      value: esc?.caseId ?? 'CASE-2026-NASHIK',
                    ),
                    const Divider(height: 24, color: AppColors.border),

                    // Assigned Expert / KVK
                    _DetailRow(
                      icon: Icons.domain_rounded,
                      label: strings.assignedToLabel,
                      value: esc?.assignedTo ?? 'KVK Nashik Agronomy Cell',
                    ),
                    const Divider(height: 24, color: AppColors.border),

                    // Queue Position
                    _DetailRow(
                      icon: Icons.people_outline_rounded,
                      label: strings.queuePositionLabel,
                      value: '${esc?.queuePosition ?? 1} (लवकरच संपर्क होईल)',
                    ),
                    const Divider(height: 24, color: AppColors.border),

                    // Estimated Response Time
                    _DetailRow(
                      icon: Icons.timer_outlined,
                      label: strings.etaMinutesLabel,
                      value: '${esc?.etaMinutes ?? 30} मिनिटे (Minutes)',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.l20),

              // Spoken Audio Summary if available
              if (audioSummary != null && audioSummary.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(AppSpacing.l16),
                  decoration: BoxDecoration(
                    color: AppColors.warmSurface,
                    borderRadius: AppRadius.card,
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.volume_up_rounded, color: AppColors.forest, size: 24),
                      const SizedBox(width: AppSpacing.m12),
                      Expanded(
                        child: Text(
                          audioSummary,
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.soilCharcoal,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.l20),
              ],

              // Back to Home Button
              AppButton.primary(
                label: strings.backToHome,
                size: AppButtonSize.large,
                onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
                leadingIcon: const Icon(Icons.home_rounded, color: Colors.white),
              ),
              const SizedBox(height: AppSpacing.l20),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.forest, size: 22),
        const SizedBox(width: AppSpacing.m12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTypography.caption.copyWith(
                  color: AppColors.fieldSlate,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.soilCharcoal,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
