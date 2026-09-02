import '../core/constants/api_endpoints.dart';
import '../core/constants/demo_fixtures.dart';
import '../core/network/api_client.dart';
import '../models/alert_models.dart';

abstract class AlertRepository {
  Future<AlertsResponse> getAlerts({
    required String farmId,
    int limit = 20,
    String? cursor,
  });

  Future<AlertRespondResponse> respondToAlert({
    required String alertId,
    required String outcome, // nothing_found | found | snoozed
    String? imageAssetId,
  });
}

class AlertRepositoryImpl implements AlertRepository {
  final ApiClient _apiClient;

  AlertRepositoryImpl({required ApiClient apiClient}) : _apiClient = apiClient;

  @override
  Future<AlertsResponse> getAlerts({
    required String farmId,
    int limit = 20,
    String? cursor,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'limit': limit,
        if (cursor != null) 'cursor': cursor,
      };

      final response = await _apiClient.get(
        ApiEndpoints.alerts(farmId),
        queryParameters: queryParams,
      );
      return AlertsResponse.fromJson(response as Map<String, dynamic>);
    } catch (_) {
      if (farmId.startsWith('f_demo')) {
        return const AlertsResponse(alerts: DemoFixtures.demoAlerts);
      }
      rethrow;
    }
  }

  @override
  Future<AlertRespondResponse> respondToAlert({
    required String alertId,
    required String outcome,
    String? imageAssetId,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.alertRespond(alertId),
      data: {
        'outcome': outcome,
        if (imageAssetId != null) 'image_asset_id': imageAssetId,
      },
    );
    return AlertRespondResponse.fromJson(response as Map<String, dynamic>);
  }
}
