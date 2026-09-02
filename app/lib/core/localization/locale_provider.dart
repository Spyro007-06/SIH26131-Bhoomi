import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../storage/secure_storage.dart';
import '../../providers/storage_providers.dart';
import 'app_strings.dart';

class LocaleNotifier extends StateNotifier<AppLanguage> {
  final SecureStorage? _storage;
  static const String languageStorageKey = 'bhoomi_app_language';

  LocaleNotifier([this._storage]) : super(AppLanguage.marathi) {
    _loadPersistedLanguage();
  }

  Future<void> _loadPersistedLanguage() async {
    if (_storage == null) return;
    try {
      final savedCode = await _storage!.read(key: languageStorageKey);
      if (savedCode != null && savedCode.isNotEmpty) {
        final lang = AppLanguage.fromCode(savedCode);
        if (state != lang) {
          state = lang;
        }
      }
    } catch (_) {}
  }

  Future<void> setLanguage(AppLanguage language) async {
    state = language;
    try {
      await _storage?.write(key: languageStorageKey, value: language.code);
    } catch (_) {}
  }
}

final appLanguageProvider =
    StateNotifierProvider<LocaleNotifier, AppLanguage>((ref) {
  final storage = ref.watch(secureStorageProvider);
  return LocaleNotifier(storage);
});

final stringsProvider = Provider<AppStrings>((ref) {
  final lang = ref.watch(appLanguageProvider);
  return AppStrings(lang);
});

