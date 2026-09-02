import '../core/constants/api_endpoints.dart';
import '../core/network/api_client.dart';
import '../models/health_models.dart';

abstract class HealthRepository {
  Future<SystemHealthModel> getHealth();
}

class HealthRepositoryImpl implements HealthRepository {
  final ApiClient _apiClient;

  HealthRepositoryImpl({required ApiClient apiClient})
      : _apiClient = apiClient;

  @override
  Future<SystemHealthModel> getHealth() async {
    final response = await _apiClient.get(ApiEndpoints.health);
    return SystemHealthModel.fromJson(response as Map<String, dynamic>);
  }
}
