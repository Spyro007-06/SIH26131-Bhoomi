import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/localization/locale_provider.dart';
import '../../../providers/farm_providers.dart';
import '../../../providers/feature_providers.dart';
import '../../../providers/repository_providers.dart';
import '../../../widgets/app_loading.dart';
import '../../../widgets/app_error_state.dart';
import '../../../widgets/app_empty_state.dart';
import '../../../widgets/risk_card.dart';

/// Active Risk Alerts Surveillance Screen for Bhoomi Farmer App.
class AlertsScreen extends ConsumerStatefulWidget {
  const AlertsScreen({super.key});

  @override
  ConsumerState<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends ConsumerState<AlertsScreen> {
  final Set<String> _respondedAlertIds = {};
  final Set<String> _submittingAlertIds = {};

  Future<void> _handleRespondToAlert(String alertId, String outcome) async {
    if (_submittingAlertIds.contains(alertId) || _respondedAlertIds.contains(alertId)) {
      return;
    }

    setState(() {
      _submittingAlertIds.add(alertId);
    });

    try {
      final repo = ref.read(alertRepositoryProvider);
      await repo.respondToAlert(
        alertId: alertId,
        outcome: outcome,
      );

      if (!mounted) return;
      final strings = ref.read(stringsProvider);
      setState(() {
        _submittingAlertIds.remove(alertId);
        _respondedAlertIds.add(alertId);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(strings.alertResponseRecorded),
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      final strings = ref.read(stringsProvider);
      setState(() {
        _submittingAlertIds.remove(alertId);
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
    final alertsAsync = ref.watch(activeAlertsProvider(activeFarmId));

    return Scaffold(
      backgroundColor: AppColors.ricePaper,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          strings.alertsTitle,
          style: AppTypography.subheading.copyWith(
            color: AppColors.primaryDark,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: alertsAsync.when(
          loading: () => Center(
            child: AppLoading(message: strings.loading),
          ),
          error: (err, _) => Center(
            child: AppErrorState(
              title: strings.genericError,
              message: strings.networkError,
              onRetry: () => ref.refresh(activeAlertsProvider(activeFarmId)),
            ),
          ),
          data: (alertsResponse) {
            final alerts = alertsResponse.alerts;

            if (alerts.isEmpty) {
              return Center(
                child: AppEmptyState(
                  title: strings.noActiveAlertsTitle,
                  message: strings.noActiveAlertsMessage,
                  icon: Icons.shield_outlined,
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(activeAlertsProvider(activeFarmId));
              },
              child: ListView.separated(
                padding: const EdgeInsets.all(AppSpacing.l20),
                itemCount: alerts.length,
                separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.l16),
                itemBuilder: (context, index) {
                  final alert = alerts[index];
                  final isResponded = _respondedAlertIds.contains(alert.id);
                  final isSubmitting = _submittingAlertIds.contains(alert.id);

                  // Invariant: Non-empty inspection tasks
                  final tasks = alert.inspectionTasks.isNotEmpty
                      ? alert.inspectionTasks
                      : ['Check the upper leaves on 10 plants across the field.'];

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      RiskCard(
                        target: alert.target.replaceAll('_', ' ').toUpperCase(),
                        riskLevel: alert.riskLevel,
                        reason: alert.reason,
                        inspectionTasks: tasks,
                        triggerType: alert.triggerType,
                        onInspectNow: isResponded || isSubmitting
                            ? null
                            : () => _handleRespondToAlert(alert.id, 'found'),
                        onRemindTomorrow: isResponded || isSubmitting
                            ? null
                            : () => _handleRespondToAlert(alert.id, 'snoozed'),
                      ),
                      if (isResponded) ...[
                        const SizedBox(height: AppSpacing.s8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.l16,
                            vertical: AppSpacing.s8,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.forest.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.check_circle_rounded, color: AppColors.forest, size: 18),
                              const SizedBox(width: AppSpacing.s8),
                              Expanded(
                                child: Text(
                                  strings.alertResponseRecorded,
                                  style: AppTypography.caption.copyWith(
                                    color: AppColors.forest,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
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
