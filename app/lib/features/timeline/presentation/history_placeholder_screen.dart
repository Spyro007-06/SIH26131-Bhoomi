import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/localization/locale_provider.dart';
import '../../../widgets/app_empty_state.dart';
import '../../../widgets/language_selector_button.dart';

/// Farm Timeline and Case File history placeholder screen for Step 3.
class HistoryPlaceholderScreen extends ConsumerWidget {
  const HistoryPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(stringsProvider);

    return Scaffold(
      backgroundColor: AppColors.ricePaper,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          strings.navHistory,
          style: AppTypography.subheading.copyWith(
            color: AppColors.primaryDark,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: const [
          LanguageSelectorButton(),
        ],
      ),
      body: const SafeArea(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.l20),
          child: Center(
            child: AppEmptyState(
              icon: Icons.history_rounded,
              title: 'No diagnostic history yet',
              subtitle: 'Past crop diagnoses, field observations, treatments, and follow-up check-ins will form your permanent farm case file here.',
            ),
          ),
        ),
      ),
    );
  }
}
