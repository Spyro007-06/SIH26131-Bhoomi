import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/localization/locale_provider.dart';
import '../../../widgets/app_empty_state.dart';

/// Alerts tab screen placeholder for Step 3.
class AlertsPlaceholderScreen extends ConsumerWidget {
  const AlertsPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(stringsProvider);

    return Scaffold(
      backgroundColor: AppColors.ricePaper,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          strings.navAlerts,
          style: AppTypography.subheading.copyWith(
            color: AppColors.primaryDark,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.l20),
          child: Center(
            child: AppEmptyState(
              icon: Icons.shield_outlined,
              title: strings.noActiveAlerts,
              subtitle: 'Weather, pest spread, and seasonal risk alerts will appear here when issued for your region.',
            ),
          ),
        ),
      ),
    );
  }
}
