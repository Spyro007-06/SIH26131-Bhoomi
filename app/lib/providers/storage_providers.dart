import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/storage/secure_storage.dart';
import '../core/storage/token_storage.dart';

final secureStorageProvider = Provider<SecureStorage>((ref) {
  return const SecureStorage();
});

final tokenStorageProvider = Provider<TokenStorage>((ref) {
  final secureStorage = ref.watch(secureStorageProvider);
  return TokenStorage(storage: secureStorage);
});
