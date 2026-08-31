import '../core/constants/api_endpoints.dart';
import '../core/network/api_client.dart';
import '../models/problem_models.dart';
import '../models/diagnosis_models.dart';

abstract class ProblemRepository {
  Future<ProblemsResponse> getProblems({
    required String farmId,
    String? status, // open | resolved
    String? type, // disease | pest
    int limit = 20,
    String? cursor,
  });

  Future<ProblemDetailModel> getProblemDetail(String problemId);

  Future<EscalationModel> escalateProblem(String problemId);
}

class ProblemRepositoryImpl implements ProblemRepository {
  final ApiClient _apiClient;

  ProblemRepositoryImpl({required ApiClient apiClient})
      : _apiClient = apiClient;

  @override
  Future<ProblemsResponse> getProblems({
    required String farmId,
    String? status,
    String? type,
    int limit = 20,
    String? cursor,
  }) async {
    final queryParams = <String, dynamic>{
      if (status != null) 'status': status,
      if (type != null) 'type': type,
      'limit': limit,
      if (cursor != null) 'cursor': cursor,
    };

    final response = await _apiClient.get(
      ApiEndpoints.problems(farmId),
      queryParameters: queryParams,
    );
    return ProblemsResponse.fromJson(response as Map<String, dynamic>);
  }

  @override
  Future<ProblemDetailModel> getProblemDetail(String problemId) async {
    final response = await _apiClient.get(ApiEndpoints.problemDetail(problemId));
    return ProblemDetailModel.fromJson(response as Map<String, dynamic>);
  }

  @override
  Future<EscalationModel> escalateProblem(String problemId) async {
    final response = await _apiClient.post(ApiEndpoints.escalate(problemId));
    return EscalationModel.fromJson(response as Map<String, dynamic>);
  }
}
