import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_strings.dart';

class LocaleNotifier extends StateNotifier<AppLanguage> {
  LocaleNotifier() : super(AppLanguage.marathi);

  void setLanguage(AppLanguage language) {
    state = language;
  }
}

final appLanguageProvider =
    StateNotifierProvider<LocaleNotifier, AppLanguage>((ref) {
  return LocaleNotifier();
});

final stringsProvider = Provider<AppStrings>((ref) {
  final lang = ref.watch(appLanguageProvider);
  return AppStrings(lang);
});
