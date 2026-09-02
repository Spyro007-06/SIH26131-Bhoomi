import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/localization/locale_provider.dart';
import '../../../models/farm_models.dart';
import '../../../providers/farm_providers.dart';
import '../../../providers/feature_providers.dart';
import '../../../providers/repository_providers.dart';
import '../../../widgets/app_button.dart';
import '../../../widgets/app_card.dart';
import '../../../widgets/farm_health_card.dart';
import '../../../widgets/risk_card.dart';
import '../../../widgets/followup_card.dart';
import '../../onboarding/presentation/farm_setup_screen.dart';
import '../../timeline/presentation/problem_detail_screen.dart';
import '../../../widgets/farmer_voice_assistant.dart';
import '../../../widgets/language_selector_button.dart';

/// Central Home Dashboard for Bhoomi Farmer App.
class HomeScreen extends ConsumerWidget {
  final VoidCallback? onCheckCropPressed;

  const HomeScreen({
    super.key,
    this.onCheckCropPressed,
  });

  String _getGreeting(dynamic strings) {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return strings.greetingMorning;
    } else if (hour < 17) {
      return strings.greetingAfternoon;
    } else {
      return strings.greetingEvening;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(stringsProvider);
    final activeFarmId = ref.watch(activeFarmIdProvider);
    final summaryAsync = ref.watch(activeFarmSummaryProvider);

    final farmIdForFeatures = activeFarmId ?? 'f_1';
    final alertsAsync = ref.watch(activeAlertsProvider(farmIdForFeatures));
    final followupsAsync = ref.watch(pendingFollowUpsProvider(farmIdForFeatures));
    final timelineAsync = ref.watch(farmTimelineProvider(farmIdForFeatures));

    return Scaffold(
      backgroundColor: AppColors.ricePaper,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.forest,
          onRefresh: () async {
            ref.invalidate(activeFarmSummaryProvider);
            ref.invalidate(activeAlertsProvider(farmIdForFeatures));
            ref.invalidate(pendingFollowUpsProvider(farmIdForFeatures));
            ref.invalidate(farmTimelineProvider(farmIdForFeatures));
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.l20,
              vertical: AppSpacing.l20,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Header: Personal Greeting, Bhoomi Partner Info & Global Language Selector
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getGreeting(strings),
                            style: AppTypography.subheading.copyWith(
                              color: AppColors.primaryDark,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${strings.appName} · ${strings.greetingPartnerSubtitle}',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.fieldSlate,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.s8),
                    // Global Language Selector Button
                    const LanguageSelectorButton(),
                  ],
                ),
                const SizedBox(height: AppSpacing.l20),

                // =========================================================================
                // 2. PRIMARY VOICE AREA: 🎤 TALK TO BHOOMI (MAIN INTERACTION HERO)
                // =========================================================================
                Semantics(
                  label: '${strings.voiceHeroTitle}. ${strings.voiceHeroSubtitleFull}',
                  button: true,
                  child: InkWell(
                    borderRadius: AppRadius.card,
                    onTap: () => FarmerVoiceAssistant.show(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.l16,
                        vertical: AppSpacing.l20,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.warmSurface,
                        borderRadius: AppRadius.card,
                        border: Border.all(color: AppColors.forest, width: 2.0),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.forest.withValues(alpha: 0.16),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // 68dp Interactive Tactile Microphone
                          Container(
                            width: 68,
                            height: 68,
                            decoration: BoxDecoration(
                              color: AppColors.forest,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.forest.withValues(alpha: 0.35),
                                  blurRadius: 14,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.mic_rounded,
                              color: AppColors.pureWhite,
                              size: 36,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.m12),

                          // Clear Hierarchy: Title + Subtitle
                          Text(
                            strings.voiceHeroTitle,
                            style: AppTypography.sectionTitle.copyWith(
                              color: AppColors.forest,
                              fontWeight: FontWeight.w800,
                              fontSize: 22,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: AppSpacing.xs4),
                          Text(
                            strings.voiceHeroSubtitleFull,
                            style: AppTypography.body.copyWith(
                              color: AppColors.soilCharcoal,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: AppSpacing.l16),

                          // Prominent Primary CTA Action Button
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              vertical: AppSpacing.m12,
                              horizontal: AppSpacing.l16,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.forest,
                              borderRadius: AppRadius.button,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.mic_rounded, color: Colors.white, size: 22),
                                const SizedBox(width: AppSpacing.s8),
                                Flexible(
                                  child: Text(
                                    strings.voiceHeroCta,
                                    style: AppTypography.button.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 16,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: AppSpacing.l16),

                // =========================================================================
                // 3. COMPACT FARM STATUS CARD
                // =========================================================================
                if (activeFarmId == null || activeFarmId.isEmpty)
                  AppCard(
                    padding: const EdgeInsets.all(AppSpacing.l16),
                    backgroundColor: AppColors.warmSurface,
                    border: Border.all(color: AppColors.turmeric, width: 1.5),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.add_location_alt_rounded, color: AppColors.turmeric, size: 24),
                            const SizedBox(width: AppSpacing.s8),
                            Expanded(
                              child: Text(
                                strings.noFarmSetupTitle,
                                style: AppTypography.bodyMedium.copyWith(
                                  color: AppColors.soilCharcoal,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.s8),
                        Text(
                          strings.noFarmSetupDesc,
                          style: AppTypography.bodySmall.copyWith(color: AppColors.fieldSlate),
                        ),
                        const SizedBox(height: AppSpacing.m12),
                        AppButton.secondary(
                          label: strings.setupFarmButton,
                          size: AppButtonSize.small,
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const FarmSetupScreen(),
                              ),
                            );
                          },
                          leadingIcon: const Icon(Icons.add, size: 18),
                        ),
                      ],
                    ),
                  )
                else
                  summaryAsync.when(
                    data: (summary) {
                      if (summary != null) {
                        return FarmHealthCard(
                          health: summary.health,
                          cropName: '${summary.farm.crop} (${summary.farm.variety ?? "Indrayani"})',
                          growthStage: summary.farm.growthStage,
                          region: summary.farm.region,
                          openProblems: summary.openProblems,
                          pendingFollowups: summary.pendingFollowups,
                          activeAlerts: summary.activeAlerts,
                        );
                      }
                      return FarmHealthCard(
                        health: const HealthModel(
                          sentence: 'Farm memory initialized. Monitoring active.',
                          trend: 'stable',
                        ),
                        cropName: 'Paddy / भात (Indrayani)',
                        growthStage: 'Tillering',
                        region: 'Nashik',
                      );
                    },
                    loading: () => FarmHealthCard(
                      health: const HealthModel(
                        sentence: 'Loading farm status...',
                        trend: 'stable',
                      ),
                      cropName: 'Paddy / भात',
                      growthStage: '...',
                      region: '...',
                    ),
                    error: (_, __) => FarmHealthCard(
                      health: const HealthModel(
                        sentence: 'Farm status offline. Cached data displayed.',
                        trend: 'stable',
                      ),
                      cropName: 'Paddy / भात',
                      growthStage: 'Tillering',
                      region: 'Maharashtra',
                    ),
                  ),

                const SizedBox(height: AppSpacing.l16),

                // =========================================================================
                // 4. SECONDARY CROP CHECK ACTION: 📷 SHOW BHOOMI YOUR CROP
                // =========================================================================
                GestureDetector(
                  onTap: onCheckCropPressed,
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.l16),
                    decoration: BoxDecoration(
                      color: AppColors.forest,
                      borderRadius: AppRadius.card,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.forest.withValues(alpha: 0.25),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.camera_alt_rounded,
                            color: Colors.white,
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.l16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                strings.checkCropBannerTitle,
                                style: AppTypography.subheading.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                strings.checkCropBannerAction,
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.primaryLight,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_ios_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: AppSpacing.xl28),

                // Section 1: Active Weather & Pest Alerts
                Text(
                  strings.recentAlertsHeader,
                  style: AppTypography.subheading.copyWith(
                    color: AppColors.soilCharcoal,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.m12),
                alertsAsync.when(
                  loading: () => const AppCard(
                    padding: EdgeInsets.all(AppSpacing.l16),
                    child: Center(
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.forest),
                    ),
                  ),
                  error: (_, __) => AppCard(
                    padding: const EdgeInsets.all(AppSpacing.l16),
                    child: Text(
                      strings.noActiveAlerts,
                      style: AppTypography.bodySmall.copyWith(color: AppColors.fieldSlate),
                    ),
                  ),
                  data: (alertsRes) {
                    if (alertsRes.alerts.isEmpty) {
                      return AppCard(
                        padding: const EdgeInsets.all(AppSpacing.l16),
                        child: Row(
                          children: [
                            const Icon(Icons.shield_outlined, color: AppColors.success, size: 24),
                            const SizedBox(width: AppSpacing.m12),
                            Expanded(
                              child: Text(
                                strings.noActiveAlerts,
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.fieldSlate,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    // Render top active alert
                    final topAlert = alertsRes.alerts.first;
                    final tasks = topAlert.inspectionTasks.isNotEmpty
                        ? topAlert.inspectionTasks
                        : ['Check the upper leaves on 10 plants across the field.'];

                    return RiskCard(
                      target: topAlert.target.replaceAll('_', ' ').toUpperCase(),
                      riskLevel: topAlert.riskLevel,
                      reason: topAlert.reason,
                      inspectionTasks: tasks,
                      triggerType: topAlert.triggerType,
                      onInspectNow: () async {
                        try {
                          await ref.read(alertRepositoryProvider).respondToAlert(
                                alertId: topAlert.id,
                                outcome: 'found',
                              );
                          ref.invalidate(activeAlertsProvider(farmIdForFeatures));
                        } catch (_) {}
                      },
                    );
                  },
                ),

                const SizedBox(height: AppSpacing.l24),

                // Section 2: Pending Follow-ups
                Text(
                  strings.pendingFollowupsHeader,
                  style: AppTypography.subheading.copyWith(
                    color: AppColors.soilCharcoal,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.m12),
                followupsAsync.when(
                  loading: () => const AppCard(
                    padding: EdgeInsets.all(AppSpacing.l16),
                    child: Center(
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.forest),
                    ),
                  ),
                  error: (_, __) => AppCard(
                    padding: const EdgeInsets.all(AppSpacing.l16),
                    child: Text(
                      strings.noPendingFollowups,
                      style: AppTypography.bodySmall.copyWith(color: AppColors.fieldSlate),
                    ),
                  ),
                  data: (followupsRes) {
                    if (followupsRes.followUps.isEmpty) {
                      return AppCard(
                        padding: const EdgeInsets.all(AppSpacing.l16),
                        child: Row(
                          children: [
                            const Icon(Icons.event_available_rounded, color: AppColors.forest, size: 24),
                            const SizedBox(width: AppSpacing.m12),
                            Expanded(
                              child: Text(
                                strings.noPendingFollowups,
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.fieldSlate,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    final topFollowup = followupsRes.followUps.first;
                    return FollowUpCard(
                      question: topFollowup.question ?? strings.followupQuestionDefault,
                      questionLocalized: strings.followupQuestionDefault,
                      target: (topFollowup.target ?? 'TREATMENT').replaceAll('_', ' ').toUpperCase(),
                      onResponse: (response) async {
                        try {
                          await ref.read(followUpRepositoryProvider).respondToFollowUp(
                                followUpId: topFollowup.id,
                                response: response,
                              );
                          ref.invalidate(pendingFollowUpsProvider(farmIdForFeatures));
                        } catch (_) {}
                      },
                    );
                  },
                ),

                const SizedBox(height: AppSpacing.l24),

                // Section 3: Recent Activity (Timeline Snippet)
                Text(
                  'अलीकडील नोंदी (Recent Activity)',
                  style: AppTypography.subheading.copyWith(
                    color: AppColors.soilCharcoal,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.m12),
                timelineAsync.when(
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (timelineRes) {
                    if (timelineRes.events.isEmpty) {
                      return AppCard(
                        padding: const EdgeInsets.all(AppSpacing.l16),
                        child: Text(
                          strings.noHistoryMessage,
                          style: AppTypography.bodySmall.copyWith(color: AppColors.fieldSlate),
                        ),
                      );
                    }

                    return Column(
                      children: timelineRes.events.take(2).map((ev) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.s10),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: ev.problemId != null
                                ? () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => ProblemDetailScreen(problemId: ev.problemId!),
                                      ),
                                    );
                                  }
                                : null,
                            child: AppCard(
                              padding: const EdgeInsets.all(AppSpacing.l16),
                              child: Row(
                                children: [
                                  const Icon(Icons.history_rounded, color: AppColors.forest, size: 22),
                                  const SizedBox(width: AppSpacing.m12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          ev.title,
                                          style: AppTypography.bodyMedium.copyWith(
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        Text(
                                          ev.timestamp.length >= 10 ? ev.timestamp.substring(0, 10) : ev.timestamp,
                                          style: AppTypography.caption.copyWith(
                                            color: AppColors.fieldSlate,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (ev.problemId != null)
                                    const Icon(Icons.chevron_right_rounded, color: AppColors.fieldSlate, size: 18),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),

                const SizedBox(height: AppSpacing.xl32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
