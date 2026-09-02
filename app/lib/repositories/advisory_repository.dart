import '../core/constants/api_endpoints.dart';
import '../core/network/api_client.dart';
import '../models/advisory_models.dart';

abstract class AdvisoryRepository {
  Future<AdvisoryQueryResult> queryAdvisory({
    required String farmId,
    required String queryText,
    String lang = 'mr-IN',
  });
}

class AdvisoryRepositoryImpl implements AdvisoryRepository {
  final ApiClient _apiClient;

  AdvisoryRepositoryImpl({required ApiClient apiClient})
      : _apiClient = apiClient;

  @override
  Future<AdvisoryQueryResult> queryAdvisory({
    required String farmId,
    required String queryText,
    String lang = 'mr-IN',
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.advisoryQuery,
      data: {
        'farm_id': farmId,
        'query_text': queryText,
        'lang': lang,
      },
    );
    return AdvisoryQueryResult.fromJson(response as Map<String, dynamic>);
  }
}
