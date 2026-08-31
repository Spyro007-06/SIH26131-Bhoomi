import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bhoomi/core/network/api_client.dart';
import 'package:bhoomi/core/network/api_config.dart';
import 'package:bhoomi/core/storage/token_storage.dart';
import 'package:bhoomi/repositories/asset_repository.dart';

class FakeApiClient extends ApiClient {
  String? lastPostPath;
  dynamic lastPostData;
  String? lastUploadUrl;
  Uint8List? lastUploadBytes;
  String? lastUploadContentType;

  FakeApiClient()
      : super(
          config: const ApiConfig(),
          tokenStorage: TokenStorage(),
        );

  @override
  Future<dynamic> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    lastPostPath = path;
    lastPostData = data;
    return {
      'asset_id': 'a_test_999',
      'upload_url': 'https://s3.bhoomi.internal/crops/a_test_999.jpg',
      'method': 'PUT',
      'expires_in': 600,
    };
  }

  @override
  Future<void> uploadBinary({
    required String uploadUrl,
    required Uint8List bytes,
    required String contentType,
    ProgressCallback? onProgress,
  }) async {
    lastUploadUrl = uploadUrl;
    lastUploadBytes = bytes;
    lastUploadContentType = contentType;
  }
}

void main() {
  group('Presigned Media Upload Workflow Tests', () {
    late FakeApiClient fakeApiClient;
    late AssetRepository assetRepository;

    setUp(() {
      fakeApiClient = FakeApiClient();
      assetRepository = AssetRepositoryImpl(apiClient: fakeApiClient);
    });

    test('uploadImage executes 2-step presigned flow and returns asset_id',
        () async {
      final sampleImageBytes = Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0, 1, 2, 3]);

      final assetId = await assetRepository.uploadImage(
        bytes: sampleImageBytes,
        contentType: 'image/jpeg',
        farmId: 'f_nashik_1',
      );

      // Verify Step 1: POST /assets/presign was called with exact JSON
      expect(fakeApiClient.lastPostPath, '/assets/presign');
      expect(fakeApiClient.lastPostData, {
        'kind': 'image',
        'content_type': 'image/jpeg',
        'farm_id': 'f_nashik_1',
      });

      // Verify Step 2: Binary PUT directly to upload_url
      expect(fakeApiClient.lastUploadUrl,
          'https://s3.bhoomi.internal/crops/a_test_999.jpg');
      expect(fakeApiClient.lastUploadBytes, sampleImageBytes);
      expect(fakeApiClient.lastUploadContentType, 'image/jpeg');

      // Verify Step 3: Returns asset_id for downstream diagnosis
      expect(assetId, 'a_test_999');
    });

    test('uploadAudio executes 2-step presigned flow and returns asset_id',
        () async {
      final sampleAudioBytes = Uint8List.fromList([0x52, 0x49, 0x46, 0x46, 10, 20]);

      final assetId = await assetRepository.uploadAudio(
        bytes: sampleAudioBytes,
        contentType: 'audio/wav',
        farmId: 'f_nashik_1',
      );

      // Verify Step 1: POST /assets/presign was called with exact JSON
      expect(fakeApiClient.lastPostPath, '/assets/presign');
      expect(fakeApiClient.lastPostData, {
        'kind': 'audio',
        'content_type': 'audio/wav',
        'farm_id': 'f_nashik_1',
      });

      // Verify Step 2: Binary PUT directly to upload_url
      expect(fakeApiClient.lastUploadUrl,
          'https://s3.bhoomi.internal/crops/a_test_999.jpg');
      expect(fakeApiClient.lastUploadBytes, sampleAudioBytes);
      expect(fakeApiClient.lastUploadContentType, 'audio/wav');

      // Verify Step 3: Returns asset_id
      expect(assetId, 'a_test_999');
    });
  });
}
