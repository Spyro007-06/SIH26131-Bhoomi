import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/localization/locale_provider.dart';
import '../../home/presentation/home_screen.dart';
import '../../diagnose/presentation/camera_capture_screen.dart';
import '../../alerts/presentation/alerts_screen.dart';
import '../../timeline/presentation/history_screen.dart';
import '../../more/presentation/more_screen.dart';

/// Main Authenticated Application Shell with Bottom Navigation.
class MainAppShell extends ConsumerStatefulWidget {
  final int initialIndex;

  const MainAppShell({
    super.key,
    this.initialIndex = 0,
  });

  @override
  ConsumerState<MainAppShell> createState() => _MainAppShellState();
}

class _MainAppShellState extends ConsumerState<MainAppShell> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  void _onTabSelected(int index) {
    if (_currentIndex != index) {
      setState(() => _currentIndex = index);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(stringsProvider);

    final pages = [
      HomeScreen(onCheckCropPressed: () => _onTabSelected(1)),
      CameraCaptureScreen(onBack: () => _onTabSelected(0)),
      const AlertsScreen(),
      const HistoryScreen(),
      const MoreScreen(),
    ];

    return PopScope(
      canPop: _currentIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _currentIndex != 0) {
          setState(() => _currentIndex = 0);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.ricePaper,
        body: IndexedStack(
          index: _currentIndex,
          children: pages,
        ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.warmSurface,
          boxShadow: [
            BoxShadow(
              color: AppColors.soilCharcoal.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, -3),
            ),
          ],
          border: const Border(
            top: BorderSide(color: AppColors.border, width: 1.0),
          ),
        ),
        child: SafeArea(
          child: NavigationBarTheme(
            data: NavigationBarThemeData(
              indicatorColor: AppColors.primaryLight,
              labelTextStyle: WidgetStateProperty.resolveWith<TextStyle>(
                (states) {
                  if (states.contains(WidgetState.selected)) {
                    return AppTypography.caption.copyWith(
                      color: AppColors.forest,
                      fontWeight: FontWeight.w700,
                    );
                  }
                  return AppTypography.caption.copyWith(
                    color: AppColors.fieldSlate,
                    fontWeight: FontWeight.w500,
                  );
                },
              ),
              iconTheme: WidgetStateProperty.resolveWith<IconThemeData>(
                (states) {
                  if (states.contains(WidgetState.selected)) {
                    return const IconThemeData(
                      color: AppColors.forest,
                      size: 26,
                    );
                  }
                  return const IconThemeData(
                    color: AppColors.fieldSlate,
                    size: 24,
                  );
                },
              ),
            ),
            child: NavigationBar(
              selectedIndex: _currentIndex,
              onDestinationSelected: _onTabSelected,
              backgroundColor: Colors.transparent,
              elevation: 0,
              height: 68,
              destinations: [
                NavigationDestination(
                  icon: const Icon(Icons.home_outlined),
                  selectedIcon: const Icon(Icons.home_rounded),
                  label: strings.navHome,
                  tooltip: strings.navHome,
                ),
                NavigationDestination(
                  icon: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: _currentIndex == 1
                          ? AppColors.forest
                          : AppColors.forest.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.camera_alt_rounded,
                      color: _currentIndex == 1 ? Colors.white : AppColors.forest,
                      size: 20,
                    ),
                  ),
                  label: strings.navCheckCrop,
                  tooltip: strings.navCheckCrop,
                ),
                NavigationDestination(
                  icon: const Icon(Icons.shield_outlined),
                  selectedIcon: const Icon(Icons.shield_rounded),
                  label: strings.navAlerts,
                  tooltip: strings.navAlerts,
                ),
                NavigationDestination(
                  icon: const Icon(Icons.history_rounded),
                  selectedIcon: const Icon(Icons.manage_history_rounded),
                  label: strings.navHistory,
                  tooltip: strings.navHistory,
                ),
                NavigationDestination(
                  icon: const Icon(Icons.more_horiz_rounded),
                  selectedIcon: const Icon(Icons.more_horiz_rounded),
                  label: strings.navMore,
                  tooltip: strings.navMore,
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
}
