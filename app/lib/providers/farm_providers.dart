import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/farm_models.dart';
import 'repository_providers.dart';
import 'storage_providers.dart';

class ActiveFarmIdNotifier extends StateNotifier<String?> {
  final Ref? _ref;

  ActiveFarmIdNotifier([this._ref, String? initialId]) : super(initialId) {
    if (_ref != null && initialId == null) {
      _loadInitialFarmId();
    }
  }

  Future<void> _loadInitialFarmId() async {
    if (_ref == null) return;
    final tokenStorage = _ref!.read(tokenStorageProvider);
    final savedId = await tokenStorage.getActiveFarmId();
    state = savedId;
  }

  Future<void> setActiveFarmId(String farmId) async {
    state = farmId;
    if (_ref != null) {
      final tokenStorage = _ref!.read(tokenStorageProvider);
      await tokenStorage.saveActiveFarmId(farmId);
    }
  }

  Future<void> clearActiveFarm() async {
    state = null;
    if (_ref != null) {
      final tokenStorage = _ref!.read(tokenStorageProvider);
      await tokenStorage.saveActiveFarmId('');
    }
  }
}

final activeFarmIdProvider =
    StateNotifierProvider<ActiveFarmIdNotifier, String?>((ref) {
  return ActiveFarmIdNotifier(ref);
});

/// FutureProvider that fetches the active farm's summary (F11 / Home Screen)
final activeFarmSummaryProvider =
    FutureProvider.autoDispose<FarmSummaryModel?>((ref) async {
  final activeFarmId = ref.watch(activeFarmIdProvider);
  if (activeFarmId == null || activeFarmId.isEmpty) return null;

  final farmRepo = ref.watch(farmRepositoryProvider);
  return await farmRepo.getFarmSummary(activeFarmId);
});
