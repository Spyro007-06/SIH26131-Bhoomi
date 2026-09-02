import '../core/constants/api_endpoints.dart';
import '../core/constants/demo_fixtures.dart';
import '../core/network/api_client.dart';
import '../models/followup_models.dart';

abstract class FollowUpRepository {
  Future<PendingFollowUpsResponse> getPendingFollowUps(String farmId);

  Future<FollowUpResultModel> respondToFollowUp({
    required String followUpId,
    required String response, // improved | no_change | got_worse
    String? imageAssetId,
  });
}

class FollowUpRepositoryImpl implements FollowUpRepository {
  final ApiClient _apiClient;

  FollowUpRepositoryImpl({required ApiClient apiClient})
      : _apiClient = apiClient;

  @override
  Future<PendingFollowUpsResponse> getPendingFollowUps(String farmId) async {
    try {
      final response = await _apiClient.get(ApiEndpoints.pendingFollowUps(farmId));
      return PendingFollowUpsResponse.fromJson(response as Map<String, dynamic>);
    } catch (_) {
      if (farmId.startsWith('f_demo')) {
        return const PendingFollowUpsResponse(followups: DemoFixtures.demoPendingFollowUps);
      }
      rethrow;
    }
  }

  @override
  Future<FollowUpResultModel> respondToFollowUp({
    required String followUpId,
    required String response,
    String? imageAssetId,
  }) async {
    final res = await _apiClient.post(
      ApiEndpoints.followUpRespond(followUpId),
      data: {
        'response': response,
        if (imageAssetId != null) 'image_asset_id': imageAssetId,
      },
    );
    return FollowUpResultModel.fromJson(res as Map<String, dynamic>);
  }
}
