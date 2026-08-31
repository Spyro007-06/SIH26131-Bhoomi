import '../core/constants/api_endpoints.dart';
import '../core/network/api_client.dart';
import '../models/voice_models.dart';

abstract class VoiceRepository {
  Future<VoiceTranscribeResult> transcribe({
    required String assetId,
    String lang = 'mr-IN',
    String? context, // onboarding | doubt_doctor | query
  });

  Future<VoiceSynthesizeResult> synthesize({
    required String text,
    String lang = 'mr-IN',
  });
}

class VoiceRepositoryImpl implements VoiceRepository {
  final ApiClient _apiClient;

  VoiceRepositoryImpl({required ApiClient apiClient}) : _apiClient = apiClient;

  @override
  Future<VoiceTranscribeResult> transcribe({
    required String assetId,
    String lang = 'mr-IN',
    String? context,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.voiceTranscribe,
      data: {
        'asset_id': assetId,
        'lang': lang,
        if (context != null) 'context': context,
      },
    );
    return VoiceTranscribeResult.fromJson(response as Map<String, dynamic>);
  }

  @override
  Future<VoiceSynthesizeResult> synthesize({
    required String text,
    String lang = 'mr-IN',
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.voiceSynthesize,
      data: {
        'text': text,
        'lang': lang,
      },
    );
    return VoiceSynthesizeResult.fromJson(response as Map<String, dynamic>);
  }
}
