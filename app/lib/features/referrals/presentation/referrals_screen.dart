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
import '../../../widgets/app_button.dart';
import '../../../widgets/language_selector_button.dart';

/// KVK & Agricultural Support Referrals Directory Screen.
class ReferralsScreen extends ConsumerWidget {
  const ReferralsScreen({super.key});

  void _handleCall(BuildContext context, String phone, String title) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Calling $title ($phone)...'),
        backgroundColor: AppColors.forest,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(stringsProvider);
    final activeFarmId = ref.watch(activeFarmIdProvider) ?? 'f_1';
    final referralsAsync = ref.watch(farmReferralsProvider(activeFarmId));

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
          strings.referralsTitle,
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
        child: referralsAsync.when(
          loading: () => Center(
            child: AppLoading(message: strings.loading),
          ),
          error: (err, _) => Center(
            child: AppErrorState(
              title: strings.genericError,
              message: strings.networkError,
              onRetry: () => ref.refresh(farmReferralsProvider(activeFarmId)),
            ),
          ),
          data: (res) {
            final kvk = res.kvk;
            final labs = res.districtLabs;
            final helpline = res.helpline ?? '1800-180-1551';

            if (kvk == null && labs.isEmpty) {
              return Center(
                child: AppEmptyState(
                  title: strings.noReferralsTitle,
                  message: strings.noReferralsMessage,
                  icon: Icons.support_agent_outlined,
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(farmReferralsProvider(activeFarmId));
              },
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.l20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Government Kisan Call Center Banner
                    AppCard(
                      padding: const EdgeInsets.all(AppSpacing.l16),
                      backgroundColor: AppColors.primaryLight.withValues(alpha: 0.5),
                      border: Border.all(color: AppColors.forest.withValues(alpha: 0.3)),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: const BoxDecoration(
                              color: AppColors.forest,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.phone_in_talk_rounded, color: Colors.white, size: 26),
                          ),
                          const SizedBox(width: AppSpacing.m16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  strings.helplineHeader,
                                  style: AppTypography.bodyMedium.copyWith(
                                    color: AppColors.soilCharcoal,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  helpline,
                                  style: AppTypography.title.copyWith(
                                    color: AppColors.forest,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.call, color: AppColors.forest, size: 28),
                            onPressed: () => _handleCall(context, helpline, 'Kisan Call Center'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.l20),

                    // Local KVK Center Card
                    if (kvk != null) ...[
                      Text(
                        strings.kvkHeader,
                        style: AppTypography.subheading.copyWith(
                          color: AppColors.soilCharcoal,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.s10),
                      AppCard(
                        padding: const EdgeInsets.all(AppSpacing.l16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    kvk.name,
                                    style: AppTypography.bodyMedium.copyWith(
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.primaryDark,
                                    ),
                                  ),
                                ),
                                if (kvk.distanceKm != null)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppSpacing.s8,
                                      vertical: AppSpacing.s4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryLight,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      '${kvk.distanceKm!.toStringAsFixed(1)} km',
                                      style: AppTypography.caption.copyWith(
                                        color: AppColors.forest,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            if (kvk.address != null) ...[
                              const SizedBox(height: AppSpacing.s6),
                              Text(
                                kvk.address!,
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.fieldSlate,
                                ),
                              ),
                            ],
                            const SizedBox(height: AppSpacing.m16),
                            AppButton.primary(
                              label: '${strings.callButton} (${kvk.phone})',
                              size: AppButtonSize.normal,
                              onPressed: () => _handleCall(context, kvk.phone, kvk.name),
                              leadingIcon: const Icon(Icons.call, color: Colors.white, size: 18),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.l20),
                    ],

                    // District Diagnostic Labs
                    if (labs.isNotEmpty) ...[
                      Text(
                        'जिल्हा कृषी प्रयोगशाळा (Diagnostic Labs)',
                        style: AppTypography.subheading.copyWith(
                          color: AppColors.soilCharcoal,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.s10),
                      ...labs.map((lab) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.m12),
                          child: AppCard(
                            padding: const EdgeInsets.all(AppSpacing.l16),
                            child: Row(
                              children: [
                                const Icon(Icons.biotech_outlined, color: AppColors.forest, size: 28),
                                const SizedBox(width: AppSpacing.m12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        lab.name,
                                        style: AppTypography.bodyMedium.copyWith(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      if (lab.address != null)
                                        Text(
                                          lab.address!,
                                          style: AppTypography.caption.copyWith(
                                            color: AppColors.fieldSlate,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.call, color: AppColors.forest),
                                  onPressed: () => _handleCall(context, lab.phone, lab.name),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
