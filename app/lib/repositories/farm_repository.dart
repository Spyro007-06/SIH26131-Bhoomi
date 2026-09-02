import '../core/constants/api_endpoints.dart';
import '../core/constants/demo_fixtures.dart';
import '../core/network/api_client.dart';
import '../models/farm_models.dart';

abstract class FarmRepository {
  Future<FarmModel> createFarm({
    required String crop, // paddy
    String? variety,
    required String growthStage,
    required String region,
    required GeoPoint location, // Geolocation is required at creation (C2)
  });
  Future<FarmModel> getFarm(String farmId);
  Future<FarmModel> updateFarm(String farmId, Map<String, dynamic> updates);
  Future<FarmSummaryModel> getFarmSummary(String farmId);
}

class FarmRepositoryImpl implements FarmRepository {
  final ApiClient _apiClient;

  FarmRepositoryImpl({required ApiClient apiClient}) : _apiClient = apiClient;

  @override
  Future<FarmModel> createFarm({
    required String crop,
    String? variety,
    required String growthStage,
    required String region,
    required GeoPoint location,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.farms,
      data: {
        'crop': crop,
        if (variety != null) 'variety': variety,
        'growth_stage': growthStage,
        'region': region,
        'location': location.toJson(),
      },
    );
    return FarmModel.fromJson(response as Map<String, dynamic>);
  }

  @override
  Future<FarmModel> getFarm(String farmId) async {
    try {
      final response = await _apiClient.get(ApiEndpoints.farmDetail(farmId));
      return FarmModel.fromJson(response as Map<String, dynamic>);
    } catch (_) {
      if (farmId.startsWith('f_demo')) {
        return DemoFixtures.demoFarm;
      }
      rethrow;
    }
  }

  @override
  Future<FarmModel> updateFarm(
    String farmId,
    Map<String, dynamic> updates,
  ) async {
    final response = await _apiClient.patch(
      ApiEndpoints.farmDetail(farmId),
      data: updates,
    );
    return FarmModel.fromJson(response as Map<String, dynamic>);
  }

  @override
  Future<FarmSummaryModel> getFarmSummary(String farmId) async {
    try {
      final response = await _apiClient.get(ApiEndpoints.farmSummary(farmId));
      return FarmSummaryModel.fromJson(response as Map<String, dynamic>);
    } catch (_) {
      if (farmId.startsWith('f_demo')) {
        return DemoFixtures.demoFarmSummary;
      }
      rethrow;
    }
  }
}
