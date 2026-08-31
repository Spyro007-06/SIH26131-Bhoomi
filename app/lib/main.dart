import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/localization/locale_provider.dart';
import 'providers/auth_providers.dart';
import 'features/splash/presentation/splash_screen.dart';
import 'features/onboarding/presentation/phone_auth_screen.dart';
import 'features/shell/presentation/main_app_shell.dart';
import 'features/showcase/design_showcase_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: BhoomiApp()));
}

/// Bhoomi Farmer Application Root Widget with Auth-State-Driven Navigation.
class BhoomiApp extends ConsumerWidget {
  final Widget? homeOverride;

  const BhoomiApp({
    super.key,
    this.homeOverride,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final language = ref.watch(appLanguageProvider);
    final authState = ref.watch(authStateProvider);

    return MaterialApp(
      title: 'Bhoomi Farmer Companion',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      locale: Locale(language.code, 'IN'),
      supportedLocales: const [
        Locale('mr', 'IN'), // Marathi (Primary)
        Locale('hi', 'IN'), // Hindi
        Locale('en', 'IN'), // Indian English
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routes: {
        '/showcase': (context) => const DesignShowcaseScreen(),
      },
      home: homeOverride ?? _resolveRootScreen(authState),
    );
  }

  Widget _resolveRootScreen(AuthState authState) {
    if (authState.isInitializing) {
      return const SplashScreen();
    }
    if (authState.isUnauthenticated) {
      return const PhoneAuthScreen();
    }
    return const MainAppShell();
  }
}
