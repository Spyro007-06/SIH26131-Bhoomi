import '../core/constants/api_endpoints.dart';
import '../core/network/api_client.dart';
import '../models/diagnosis_models.dart';

abstract class DiagnosisRepository {
  Future<DiagnoseResponse> diagnose({
    required String farmId,
    required String imageAssetId,
    String? descriptionAssetId,
    String? descriptionText,
    String lang = 'mr-IN',
  });
}

class DiagnosisRepositoryImpl implements DiagnosisRepository {
  final ApiClient _apiClient;

  DiagnosisRepositoryImpl({required ApiClient apiClient})
      : _apiClient = apiClient;

  @override
  Future<DiagnoseResponse> diagnose({
    required String farmId,
    required String imageAssetId,
    String? descriptionAssetId,
    String? descriptionText,
    String lang = 'mr-IN',
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.diagnose(farmId),
      data: {
        'image_asset_id': imageAssetId,
        if (descriptionAssetId != null)
          'description_asset_id': descriptionAssetId,
        if (descriptionText != null) 'description_text': descriptionText,
        'lang': lang,
      },
    );
    return DiagnoseResponse.fromJson(response as Map<String, dynamic>);
  }
}
