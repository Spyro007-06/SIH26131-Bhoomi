import '../core/constants/api_endpoints.dart';
import '../core/constants/demo_fixtures.dart';
import '../core/network/api_client.dart';
import '../models/timeline_models.dart';

abstract class TimelineRepository {
  Future<TimelineResponse> getTimeline({
    required String farmId,
    int limit = 20,
    String? cursor,
  });
}

class TimelineRepositoryImpl implements TimelineRepository {
  final ApiClient _apiClient;

  TimelineRepositoryImpl({required ApiClient apiClient})
      : _apiClient = apiClient;

  @override
  Future<TimelineResponse> getTimeline({
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
        ApiEndpoints.timeline(farmId),
        queryParameters: queryParams,
      );
      return TimelineResponse.fromJson(response as Map<String, dynamic>);
    } catch (_) {
      if (farmId.startsWith('f_demo')) {
        return const TimelineResponse(events: DemoFixtures.demoTimeline);
      }
      rethrow;
    }
  }
}
