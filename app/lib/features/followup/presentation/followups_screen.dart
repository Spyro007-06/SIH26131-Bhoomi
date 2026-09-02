import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/localization/locale_provider.dart';
import '../../../models/followup_models.dart';
import '../../../providers/farm_providers.dart';
import '../../../providers/feature_providers.dart';
import '../../../providers/repository_providers.dart';
import '../../../widgets/app_loading.dart';
import '../../../widgets/app_error_state.dart';
import '../../../widgets/app_empty_state.dart';
import '../../../widgets/followup_card.dart';
import '../../../widgets/language_selector_button.dart';

/// Closed-Loop Follow-Up Check-ins Screen.
class FollowupsScreen extends ConsumerStatefulWidget {
  const FollowupsScreen({super.key});

  @override
  ConsumerState<FollowupsScreen> createState() => _FollowupsScreenState();
}

class _FollowupsScreenState extends ConsumerState<FollowupsScreen> {
  final Map<String, FollowUpResultModel> _completedResults = {};
  final Set<String> _submittingIds = {};

  Future<void> _handleFollowUpResponse(String followUpId, String response) async {
    if (_submittingIds.contains(followUpId) || _completedResults.containsKey(followUpId)) {
      return;
    }

    setState(() {
      _submittingIds.add(followUpId);
    });

    try {
      final repo = ref.read(followUpRepositoryProvider);
      final result = await repo.respondToFollowUp(
        followUpId: followUpId,
        response: response,
      );

      if (!mounted) return;
      final strings = ref.read(stringsProvider);
      setState(() {
        _submittingIds.remove(followUpId);
        _completedResults[followUpId] = result;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(strings.followupSuccessMessage),
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      final strings = ref.read(stringsProvider);
      setState(() {
        _submittingIds.remove(followUpId);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(strings.genericError),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(stringsProvider);
    final activeFarmId = ref.watch(activeFarmIdProvider) ?? 'f_1';
    final followupsAsync = ref.watch(pendingFollowUpsProvider(activeFarmId));

    return Scaffold(
      backgroundColor: AppColors.ricePaper,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          strings.followupsTitle,
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
        child: followupsAsync.when(
          loading: () => Center(
            child: AppLoading(message: strings.loading),
          ),
          error: (err, _) => Center(
            child: AppErrorState(
              title: strings.genericError,
              message: strings.networkError,
              onRetry: () => ref.refresh(pendingFollowUpsProvider(activeFarmId)),
            ),
          ),
          data: (res) {
            final followups = res.followUps;

            if (followups.isEmpty) {
              return Center(
                child: AppEmptyState(
                  title: strings.noPendingFollowupsTitle,
                  message: strings.noPendingFollowupsMessage,
                  icon: Icons.task_alt_rounded,
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(pendingFollowUpsProvider(activeFarmId));
              },
              child: ListView.separated(
                padding: const EdgeInsets.all(AppSpacing.l20),
                itemCount: followups.length,
                separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.l16),
                itemBuilder: (context, index) {
                  final item = followups[index];
                  final isCompleted = _completedResults.containsKey(item.id);
                  final result = _completedResults[item.id];
                  final isSubmitting = _submittingIds.contains(item.id);

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      FollowUpCard(
                        question: item.question ?? strings.followupQuestionDefault,
                        questionLocalized: strings.followupQuestionDefault,
                        target: (item.target ?? 'TREATMENT').replaceAll('_', ' ').toUpperCase(),
                        onResponse: isCompleted || isSubmitting
                            ? null
                            : (val) => _handleFollowUpResponse(item.id, val),
                      ),
                      if (isCompleted && result != null) ...[
                        const SizedBox(height: AppSpacing.s8),
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.l16),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.forest.withValues(alpha: 0.3)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.check_circle_rounded, color: AppColors.forest, size: 20),
                                  const SizedBox(width: AppSpacing.s8),
                                  Expanded(
                                    child: Text(
                                      strings.followupSuccessMessage,
                                      style: AppTypography.bodySmall.copyWith(
                                        color: AppColors.forest,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (result.severityChange != null) ...[
                                const SizedBox(height: AppSpacing.s6),
                                Text(
                                  'Severity: ${result.severityChange!.from} → ${result.severityChange!.to}',
                                  style: AppTypography.caption.copyWith(
                                    color: AppColors.soilCharcoal,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                              if (result.escalated == true && result.caseId != null) ...[
                                const SizedBox(height: AppSpacing.s6),
                                Text(
                                  'Auto-Escalated to Expert (Case ID: ${result.caseId})',
                                  style: AppTypography.caption.copyWith(
                                    color: AppColors.danger,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ],
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
