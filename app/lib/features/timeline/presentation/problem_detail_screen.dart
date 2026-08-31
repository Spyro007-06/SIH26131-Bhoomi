import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/localization/locale_provider.dart';
import '../../../providers/feature_providers.dart';
import '../../../widgets/app_loading.dart';
import '../../../widgets/app_error_state.dart';
import '../../../widgets/app_card.dart';
import '../../../widgets/app_status_badge.dart';
import '../../../widgets/spoken_summary_player.dart';

/// Comprehensive Case File Problem Detail Screen.
class ProblemDetailScreen extends ConsumerWidget {
  final String problemId;

  const ProblemDetailScreen({
    super.key,
    required this.problemId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(stringsProvider);
    final problemAsync = ref.watch(problemDetailProvider(problemId));

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
          strings.problemDetailTitle,
          style: AppTypography.subheading.copyWith(
            color: AppColors.primaryDark,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: problemAsync.when(
          loading: () => Center(
            child: AppLoading(message: strings.loading),
          ),
          error: (err, _) => Center(
            child: AppErrorState(
              title: strings.genericError,
              message: strings.networkError,
              onRetry: () => ref.refresh(problemDetailProvider(problemId)),
            ),
          ),
          data: (problem) {
            final isResolved = problem.status.toLowerCase() == 'resolved';

            return SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.l20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Problem Header Card
                  AppCard(
                    padding: const EdgeInsets.all(AppSpacing.l16),
                    backgroundColor: isResolved
                        ? AppColors.primaryLight.withValues(alpha: 0.4)
                        : AppColors.warmSurface,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            AppStatusBadge(
                              status: problem.severity,
                              type: StatusBadgeType.severity,
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.s10,
                                vertical: AppSpacing.s4,
                              ),
                              decoration: BoxDecoration(
                                color: isResolved
                                    ? AppColors.success.withValues(alpha: 0.12)
                                    : AppColors.turmeric.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                isResolved ? strings.statusResolved : strings.statusOpen,
                                style: AppTypography.caption.copyWith(
                                  color: isResolved ? AppColors.success : AppColors.turmeric,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.s10),
                        Text(
                          problem.label.replaceAll('_', ' ').toUpperCase(),
                          style: AppTypography.title.copyWith(
                            color: AppColors.primaryDark,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.s8),
                        Text(
                          '${strings.openedOnLabel}: ${problem.openedAt.length >= 10 ? problem.openedAt.substring(0, 10) : (problem.openedAt.isNotEmpty ? problem.openedAt : "N/A")}'
                          '${problem.resolvedAt != null && problem.resolvedAt!.isNotEmpty ? ' • ${strings.resolvedOnLabel}: ${problem.resolvedAt!.length >= 10 ? problem.resolvedAt!.substring(0, 10) : problem.resolvedAt}' : ''}',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.fieldSlate,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.l20),

                  // Escalation Details Card (if escalated)
                  if (problem.escalation != null) ...[
                    AppCard(
                      padding: const EdgeInsets.all(AppSpacing.l16),
                      backgroundColor: AppColors.danger.withValues(alpha: 0.08),
                      border: Border.all(color: AppColors.danger, width: 1.5),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.support_agent_rounded, color: AppColors.danger, size: 22),
                              const SizedBox(width: AppSpacing.s8),
                              Expanded(
                                child: Text(
                                  strings.escalateTitle,
                                  style: AppTypography.bodyMedium.copyWith(
                                    color: AppColors.danger,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.s10),
                          Text(
                            '${strings.caseIdLabel}: ${problem.escalation!.caseId}',
                            style: AppTypography.bodySmall.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            '${strings.assignedToLabel}: ${problem.escalation!.assignedTo}',
                            style: AppTypography.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.l20),
                  ],

                  // Field Observations Section
                  Text(
                    strings.observationsHeader,
                    style: AppTypography.subheading.copyWith(
                      color: AppColors.soilCharcoal,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s10),

                  if (problem.observations.isEmpty)
                    AppCard(
                      padding: const EdgeInsets.all(AppSpacing.l16),
                      child: Text(
                        'No field observations recorded.',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.fieldSlate,
                        ),
                      ),
                    )
                  else
                    ...problem.observations.map((obs) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.s10),
                        child: AppCard(
                          padding: const EdgeInsets.all(AppSpacing.l16),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.visibility_outlined, color: AppColors.forest, size: 20),
                              const SizedBox(width: AppSpacing.m12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Cue: ${obs.cueId ?? 'Physical inspection'}',
                                      style: AppTypography.bodyMedium.copyWith(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Answer: ${obs.answer.toUpperCase()}',
                                        style: AppTypography.bodySmall.copyWith(
                                          color: AppColors.forest,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    if (obs.createdAt != null && obs.createdAt!.length >= 10) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        obs.createdAt!.substring(0, 10),
                                        style: AppTypography.caption.copyWith(
                                          color: AppColors.fieldSlate,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  const SizedBox(height: AppSpacing.l20),

                  // Grounded Advisory Summary Section
                  if (problem.advisory != null) ...[
                    Text(
                      'उपाययोजना सारांश (Advisory Summary)',
                      style: AppTypography.subheading.copyWith(
                        color: AppColors.soilCharcoal,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s10),
                    SpokenSummaryPlayer(
                      text: '${problem.advisory!.whatToAvoid}. ${problem.advisory!.whatToCheck}',
                      title: 'सल्ला ऐका (Listen to Advisory)',
                    ),
                    const SizedBox(height: AppSpacing.s10),
                    AppCard(
                      padding: const EdgeInsets.all(AppSpacing.l16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            problem.advisory!.whatToAvoid,
                            style: AppTypography.bodyMedium.copyWith(
                              color: AppColors.danger,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.s8),
                          Text(
                            problem.advisory!.whatToCheck,
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.soilCharcoal,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.l20),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
