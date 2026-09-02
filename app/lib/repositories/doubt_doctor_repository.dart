import '../core/constants/api_endpoints.dart';
import '../core/network/api_client.dart';
import '../models/diagnosis_models.dart';

abstract class DoubtDoctorRepository {
  Future<DoubtDoctorAnswerResult> submitAnswer({
    required String problemId,
    required String cueId,
    required String answer, // yes | no | unknown
  });
}

class DoubtDoctorRepositoryImpl implements DoubtDoctorRepository {
  final ApiClient _apiClient;

  DoubtDoctorRepositoryImpl({required ApiClient apiClient})
      : _apiClient = apiClient;

  @override
  Future<DoubtDoctorAnswerResult> submitAnswer({
    required String problemId,
    required String cueId,
    required String answer,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.clarify(problemId),
      data: {
        'cue_id': cueId,
        'answer': answer,
      },
    );
    return DoubtDoctorAnswerResult.fromJson(response as Map<String, dynamic>);
  }
}
