import '../core/constants/api_endpoints.dart';
import '../core/constants/demo_fixtures.dart';
import '../core/network/api_client.dart';
import '../models/referral_models.dart';

abstract class ReferralRepository {
  Future<ReferralsResponse> getReferrals(String farmId);
}

class ReferralRepositoryImpl implements ReferralRepository {
  final ApiClient _apiClient;

  ReferralRepositoryImpl({required ApiClient apiClient})
      : _apiClient = apiClient;

  @override
  Future<ReferralsResponse> getReferrals(String farmId) async {
    try {
      final response = await _apiClient.get(ApiEndpoints.referrals(farmId));
      return ReferralsResponse.fromJson(response as Map<String, dynamic>);
    } catch (_) {
      if (farmId.startsWith('f_demo')) {
        return ReferralsResponse(referrals: DemoFixtures.demoReferrals);
      }
      rethrow;
    }
  }
}
