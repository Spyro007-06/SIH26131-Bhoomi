import '../core/constants/api_endpoints.dart';
import '../core/network/api_client.dart';
import '../models/label_check_models.dart';

abstract class LabelCheckRepository {
  Future<LabelCheckResponse> checkLabel({
    required String problemId,
    required String imageAssetId,
    int? daysToHarvest,
  });
}

class LabelCheckRepositoryImpl implements LabelCheckRepository {
  final ApiClient _apiClient;

  LabelCheckRepositoryImpl({required ApiClient apiClient})
      : _apiClient = apiClient;

  @override
  Future<LabelCheckResponse> checkLabel({
    required String problemId,
    required String imageAssetId,
    int? daysToHarvest,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.labelCheck(problemId),
      data: {
        'image_asset_id': imageAssetId,
        if (daysToHarvest != null) 'days_to_harvest': daysToHarvest,
      },
    );
    return LabelCheckResponse.fromJson(response as Map<String, dynamic>);
  }
}
