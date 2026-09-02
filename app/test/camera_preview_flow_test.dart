import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bhoomi/main.dart';
import 'package:bhoomi/models/asset_models.dart';
import 'package:bhoomi/models/advisory_models.dart';
import 'package:bhoomi/models/diagnosis_models.dart';
import 'package:bhoomi/models/gate_models.dart';
import 'package:bhoomi/repositories/asset_repository.dart';
import 'package:bhoomi/repositories/diagnosis_repository.dart';
import 'package:bhoomi/providers/repository_providers.dart';
import 'package:bhoomi/providers/farm_providers.dart';
import 'package:bhoomi/features/diagnose/presentation/camera_capture_screen.dart';
import 'package:bhoomi/features/diagnose/presentation/image_preview_screen.dart';
import 'package:bhoomi/features/diagnose/presentation/advisory_result_screen.dart';

class FakeAssetRepository extends AssetRepository {
  Uint8List? lastUploadedBytes;
  String? lastUploadedContentType;

  @override
  Future<String> uploadImage({
    required Uint8List bytes,
    String contentType = 'image/jpeg',
    String? farmId,
    dynamic onProgress,
  }) async {
    lastUploadedBytes = bytes;
    lastUploadedContentType = contentType;
    return 'asset_leaf_photo_99';
  }

  @override
  Future<String> uploadAudio({required Uint8List bytes, String contentType = 'audio/wav', String? farmId, dynamic onProgress}) =>
      throw UnimplementedError();

  @override
  Future<PresignedAssetModel> presignAsset({required String kind, required String contentType, String? farmId}) =>
      throw UnimplementedError();

  @override
  Future<void> uploadBinary({required String uploadUrl, required Uint8List bytes, required String contentType, dynamic onProgress}) =>
      throw UnimplementedError();
}

class FakeDiagnosisRepository extends DiagnosisRepository {
  String? lastImageAssetId;
  String? lastFarmId;

  @override
  Future<DiagnoseResponse> diagnose({
    required String farmId,
    required String imageAssetId,
    String? descriptionAssetId,
    String? descriptionText,
    String lang = 'mr-IN',
  }) async {
    lastFarmId = farmId;
    lastImageAssetId = imageAssetId;

    return const DiagnoseResponse(
      gate: GateDecision(
        outcome: 'advise',
        confidence: 0.88,
        thresholdApplied: 0.70,
        reasonCode: 'ABOVE_GATE',
        alternatives: [Prediction(label: 'blast', confidence: 0.88)],
        isStub: false,
      ),
      problemId: 'p_101',
      problemType: 'disease',
      diagnosis: DiagnosisDetail(
        label: 'blast',
        severity: 'early',
        confidence: 0.88,
      ),
      advisory: AdvisoryModel(
        possibleIssue: 'Early Paddy Blast',
        whatToAvoid: 'Do not top-dress nitrogen now.',
        whatToCheck: 'Diamond shaped lesions.',
        ladder: [],
      ),
      spokenSummary: 'करपा रोगाची लक्षणे आढळली आहेत.',
    );
  }
}

void main() {
  group('Camera Capture, Preview, and Upload Flow Tests (Step 4)', () {
    late FakeAssetRepository fakeAssetRepo;
    late FakeDiagnosisRepository fakeDiagnosisRepo;

    setUp(() {
      fakeAssetRepo = FakeAssetRepository();
      fakeDiagnosisRepo = FakeDiagnosisRepository();
    });

    testWidgets('Complete camera capture -> preview -> 2-step presigned upload -> diagnosis flow',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            assetRepositoryProvider.overrideWithValue(fakeAssetRepo),
            diagnosisRepositoryProvider.overrideWithValue(fakeDiagnosisRepo),
            activeFarmIdProvider.overrideWith((ref) => ActiveFarmIdNotifier(null, 'f_nashik_001')),
          ],
          child: const BhoomiApp(homeOverride: CameraCaptureScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Camera Capture Screen is active
      expect(find.text('पीक तपासा (फोटो घ्या)'), findsOneWidget);
      expect(find.text('पानावरील किंवा खोडावरील डाग स्पष्ट दिसतील असा फोटो घ्या.'), findsOneWidget);

      // 2. Tap Shutter Capture Button
      await tester.tap(find.byIcon(Icons.camera_alt_rounded));
      await tester.pumpAndSettle();

      // 3. Navigated to ImagePreviewScreen
      expect(find.byType(ImagePreviewScreen), findsOneWidget);
      expect(find.text('फोटोची खात्री करा'), findsOneWidget);
      expect(find.text('हा फोटो वापरा (तपासा)'), findsOneWidget);
      expect(find.text('पुन्हा फोटो घ्या'), findsOneWidget);

      // 4. Confirm with "Use this Photo"
      await tester.tap(find.text('हा फोटो वापरा (तपासा)'));
      await tester.pumpAndSettle();

      // 5. Verify 2-step Presigned upload and Diagnosis API invocations
      expect(fakeAssetRepo.lastUploadedBytes, isNotNull);
      expect(fakeAssetRepo.lastUploadedContentType, 'image/jpeg');
      expect(fakeDiagnosisRepo.lastFarmId, 'f_nashik_001');
      expect(fakeDiagnosisRepo.lastImageAssetId, 'asset_leaf_photo_99');

      // 6. Rendered AdvisoryResultScreen
      expect(find.byType(AdvisoryResultScreen), findsOneWidget);
      expect(find.text('BLAST'), findsOneWidget);
    });
  });
}
