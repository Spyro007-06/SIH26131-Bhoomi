import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/localization/locale_provider.dart';
import '../../../providers/farm_providers.dart';
import '../../../providers/feature_providers.dart';
import '../../../widgets/app_loading.dart';
import '../../../widgets/app_error_state.dart';
import '../../../widgets/app_empty_state.dart';
import '../../../widgets/app_card.dart';
import '../../../widgets/app_status_badge.dart';
import '../../../widgets/language_selector_button.dart';
import 'problem_detail_screen.dart';

/// Chronological Crop Case File Timeline Screen.
class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  IconData _getEventIcon(String eventType) {
    switch (eventType.toLowerCase()) {
      case 'diagnosis':
        return Icons.healing_rounded;
      case 'observation':
        return Icons.visibility_outlined;
      case 'treatment':
        return Icons.science_outlined;
      case 'alert':
        return Icons.warning_amber_rounded;
      case 'follow_up':
      case 'followup':
        return Icons.fact_check_outlined;
      default:
        return Icons.event_note_rounded;
    }
  }

  Color _getEventColor(String eventType) {
    switch (eventType.toLowerCase()) {
      case 'diagnosis':
        return AppColors.forest;
      case 'alert':
        return AppColors.warning;
      case 'follow_up':
      case 'followup':
        return AppColors.info;
      default:
        return AppColors.fieldSlate;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(stringsProvider);
    final activeFarmId = ref.watch(activeFarmIdProvider) ?? 'f_1';
    final timelineAsync = ref.watch(farmTimelineProvider(activeFarmId));

    return Scaffold(
      backgroundColor: AppColors.ricePaper,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          strings.timelineTitle,
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
        child: timelineAsync.when(
          loading: () => Center(
            child: AppLoading(message: strings.loading),
          ),
          error: (err, _) => Center(
            child: AppErrorState(
              title: strings.genericError,
              message: strings.networkError,
              onRetry: () => ref.refresh(farmTimelineProvider(activeFarmId)),
            ),
          ),
          data: (timelineRes) {
            final events = timelineRes.events;

            if (events.isEmpty) {
              return Center(
                child: AppEmptyState(
                  title: strings.noHistoryTitle,
                  message: strings.noHistoryMessage,
                  icon: Icons.history_rounded,
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(farmTimelineProvider(activeFarmId));
              },
              child: ListView.separated(
                padding: const EdgeInsets.all(AppSpacing.l20),
                itemCount: events.length,
                separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.l16),
                itemBuilder: (context, index) {
                  final event = events[index];
                  final icon = _getEventIcon(event.eventType);
                  final color = _getEventColor(event.eventType);

                  return InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: event.problemId != null
                        ? () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => ProblemDetailScreen(problemId: event.problemId!),
                              ),
                            );
                          }
                        : null,
                    child: AppCard(
                      padding: const EdgeInsets.all(AppSpacing.l16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Event Icon Badge
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(icon, color: color, size: 24),
                          ),
                          const SizedBox(width: AppSpacing.m12),

                          // Event Details
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        event.title,
                                        style: AppTypography.bodyMedium.copyWith(
                                          color: AppColors.soilCharcoal,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    if (event.severity != null) ...[
                                      const SizedBox(width: AppSpacing.s8),
                                      AppStatusBadge(
                                        status: event.severity!,
                                        type: StatusBadgeType.severity,
                                      ),
                                    ],
                                  ],
                                ),
                                if (event.description != null) ...[
                                  const SizedBox(height: AppSpacing.s4),
                                  Text(
                                    event.description!,
                                    style: AppTypography.bodySmall.copyWith(
                                      color: AppColors.fieldSlate,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: AppSpacing.s8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      event.timestamp.length >= 10
                                          ? event.timestamp.substring(0, 10)
                                          : event.timestamp,
                                      style: AppTypography.caption.copyWith(
                                        color: AppColors.fieldSlate,
                                      ),
                                    ),
                                    if (event.problemId != null)
                                      Row(
                                        children: [
                                          Text(
                                            'तपशील पहा',
                                            style: AppTypography.caption.copyWith(
                                              color: AppColors.forest,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          const Icon(
                                            Icons.chevron_right_rounded,
                                            size: 16,
                                            color: AppColors.forest,
                                          ),
                                        ],
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
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
