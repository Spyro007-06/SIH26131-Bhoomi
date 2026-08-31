import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/network/api_client.dart';
import '../core/network/api_config.dart';
import 'storage_providers.dart';

final apiConfigProvider = Provider<ApiConfig>((ref) {
  return const ApiConfig();
});

final apiClientProvider = Provider<ApiClient>((ref) {
  final config = ref.watch(apiConfigProvider);
  final tokenStorage = ref.watch(tokenStorageProvider);
  return ApiClient(
    config: config,
    tokenStorage: tokenStorage,
  );
});
