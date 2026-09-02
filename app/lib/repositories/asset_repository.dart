import 'dart:typed_data';
import 'package:dio/dio.dart';
import '../core/constants/api_endpoints.dart';
import '../core/network/api_client.dart';
import '../models/asset_models.dart';

abstract class AssetRepository {
  Future<PresignedAssetModel> presignAsset({
    required String kind, // image | audio
    required String contentType,
    String? farmId,
  });

  Future<void> uploadBinary({
    required String uploadUrl,
    required Uint8List bytes,
    required String contentType,
    ProgressCallback? onProgress,
  });

  /// Complete 2-step presigned image upload workflow:
  /// 1. POST /assets/presign
  /// 2. PUT raw binary bytes to upload_url
  /// 3. Returns asset_id
  Future<String> uploadImage({
    required Uint8List bytes,
    String contentType = 'image/jpeg',
    String? farmId,
    ProgressCallback? onProgress,
  });

  /// Complete 2-step presigned audio upload workflow:
  /// 1. POST /assets/presign
  /// 2. PUT raw binary bytes to upload_url
  /// 3. Returns asset_id
  Future<String> uploadAudio({
    required Uint8List bytes,
    String contentType = 'audio/wav',
    String? farmId,
    ProgressCallback? onProgress,
  });
}

class AssetRepositoryImpl implements AssetRepository {
  final ApiClient _apiClient;

  AssetRepositoryImpl({required ApiClient apiClient}) : _apiClient = apiClient;

  @override
  Future<PresignedAssetModel> presignAsset({
    required String kind,
    required String contentType,
    String? farmId,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.assetsPresign,
      data: {
        'kind': kind,
        'content_type': contentType,
        if (farmId != null) 'farm_id': farmId,
      },
    );
    return PresignedAssetModel.fromJson(response as Map<String, dynamic>);
  }

  @override
  Future<void> uploadBinary({
    required String uploadUrl,
    required Uint8List bytes,
    required String contentType,
    ProgressCallback? onProgress,
  }) async {
    await _apiClient.uploadBinary(
      uploadUrl: uploadUrl,
      bytes: bytes,
      contentType: contentType,
      onProgress: onProgress,
    );
  }

  @override
  Future<String> uploadImage({
    required Uint8List bytes,
    String contentType = 'image/jpeg',
    String? farmId,
    ProgressCallback? onProgress,
  }) async {
    // Step 1: Request presigned upload URL
    final presigned = await presignAsset(
      kind: 'image',
      contentType: contentType,
      farmId: farmId,
    );

    // Step 2: Directly upload raw bytes to presigned storage URL
    await uploadBinary(
      uploadUrl: presigned.uploadUrl,
      bytes: bytes,
      contentType: contentType,
      onProgress: onProgress,
    );

    // Step 3: Return asset_id reference for downstream diagnosis
    return presigned.assetId;
  }

  @override
  Future<String> uploadAudio({
    required Uint8List bytes,
    String contentType = 'audio/wav',
    String? farmId,
    ProgressCallback? onProgress,
  }) async {
    // Step 1: Request presigned upload URL
    final presigned = await presignAsset(
      kind: 'audio',
      contentType: contentType,
      farmId: farmId,
    );

    // Step 2: Directly upload raw bytes to presigned storage URL
    await uploadBinary(
      uploadUrl: presigned.uploadUrl,
      bytes: bytes,
      contentType: contentType,
      onProgress: onProgress,
    );

    // Step 3: Return asset_id reference for downstream transcription
    return presigned.assetId;
  }
}
