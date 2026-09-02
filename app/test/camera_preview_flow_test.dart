import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:camera/camera.dart';
import 'package:bhoomi/main.dart';
import 'package:bhoomi/models/asset_models.dart';
import 'package:bhoomi/models/advisory_models.dart';
import 'package:bhoomi/models/diagnosis_models.dart';
import 'package:bhoomi/models/gate_models.dart';
import 'package:bhoomi/core/utils/camera_service.dart';
import 'package:bhoomi/core/utils/image_compression_service.dart';
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

class FakeCameraController extends CameraController {
  bool initializeCalled = false;
  bool takePictureCalled = false;
  bool disposeCalled = false;
  XFile? photoToReturn;

  FakeCameraController({
    required CameraDescription description,
    this.photoToReturn,
  }) : super(
          description,
          ResolutionPreset.high,
          enableAudio: false,
        ) {
    value = CameraValue.uninitialized(description).copyWith(
      isInitialized: true,
      previewSize: const Size(1920, 1080),
      flashMode: FlashMode.auto,
    );
  }

  @override
  Future<void> initialize() async {
    initializeCalled = true;
  }

  @override
  Future<XFile> takePicture() async {
    takePictureCalled = true;
    return photoToReturn ??
        XFile.fromData(
          Uint8List.fromList([10, 20, 30, 40, 50, 60, 70, 80]),
          name: 'leaf.jpg',
          mimeType: 'image/jpeg',
        );
  }

  @override
  Future<void> setFlashMode(FlashMode mode) async {
    value = value.copyWith(flashMode: mode);
  }

  @override
  Widget buildPreview() {
    return const SizedBox.expand(
      child: ColoredBox(color: Colors.black87),
    );
  }

  @override
  Future<void> dispose() async {
    disposeCalled = true;
    super.dispose();
  }
}

class FakeCameraPlatformWrapper implements CameraPlatformWrapper {
  bool permissionGranted = true;
  bool permissionPermanentlyDenied = false;
  bool appSettingsOpened = false;
  List<CameraDescription> cameras = [
    const CameraDescription(
      name: '0',
      lensDirection: CameraLensDirection.back,
      sensorOrientation: 90,
    ),
  ];
  FakeCameraController? lastCreatedController;
  XFile? photoToReturn;

  @override
  Future<bool> requestCameraPermission() async => permissionGranted;

  @override
  Future<bool> isCameraPermissionGranted() async => permissionGranted;

  @override
  Future<bool> isCameraPermissionPermanentlyDenied() async => permissionPermanentlyDenied;

  @override
  Future<bool> openAppSettings() async {
    appSettingsOpened = true;
    return true;
  }

  @override
  Future<List<CameraDescription>> getAvailableCameras() async => cameras;

  @override
  CameraController createController({
    required CameraDescription camera,
    ResolutionPreset resolutionPreset = ResolutionPreset.high,
    bool enableAudio = false,
  }) {
    lastCreatedController = FakeCameraController(
      description: camera,
      photoToReturn: photoToReturn,
    );
    return lastCreatedController!;
  }
}

class FakeImageCompressor implements ImageCompressor {
  bool compressCalled = false;
  Uint8List? compressedResult;

  @override
  Future<Uint8List> compress({
    required Uint8List bytes,
    int minWidth = 1080,
    int minHeight = 1080,
    int quality = 82,
  }) async {
    compressCalled = true;
    return compressedResult ?? Uint8List.fromList([100, 200, 255]);
  }
}

void main() {
  group('Image Compression Service Unit Tests', () {
    test('Compresses raw bytes using injected compressor', () async {
      final fakeCompressor = FakeImageCompressor();
      final compressionService = ImageCompressionService(compressor: fakeCompressor);

      final rawBytes = Uint8List.fromList([1, 2, 3, 4]);
      final result = await compressionService.compress(rawBytes);

      expect(fakeCompressor.compressCalled, isTrue);
      expect(result, Uint8List.fromList([100, 200, 255]));
    });

    test('Returns empty bytes without invoking compressor when input is empty', () async {
      final fakeCompressor = FakeImageCompressor();
      final compressionService = ImageCompressionService(compressor: fakeCompressor);

      final result = await compressionService.compress(Uint8List(0));
      expect(fakeCompressor.compressCalled, isFalse);
      expect(result.isEmpty, isTrue);
    });
  });

  group('Real Camera Capture, Preview, Compression & Upload Flow Tests (P2)', () {
    late FakeAssetRepository fakeAssetRepo;
    late FakeDiagnosisRepository fakeDiagnosisRepo;
    late FakeCameraPlatformWrapper fakeCameraPlatform;
    late FakeImageCompressor fakeImageCompressor;

    setUp(() {
      fakeAssetRepo = FakeAssetRepository();
      fakeDiagnosisRepo = FakeDiagnosisRepository();
      fakeCameraPlatform = FakeCameraPlatformWrapper();
      fakeImageCompressor = FakeImageCompressor();
    });

    testWidgets('Complete camera capture -> compression -> preview -> presigned upload -> diagnosis flow',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      fakeImageCompressor.compressedResult = Uint8List.fromList([
        0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D,
        0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
        0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
        0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
        0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49,
        0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
      ]);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            assetRepositoryProvider.overrideWithValue(fakeAssetRepo),
            diagnosisRepositoryProvider.overrideWithValue(fakeDiagnosisRepo),
            activeFarmIdProvider.overrideWith((ref) => ActiveFarmIdNotifier(null, 'f_nashik_001')),
          ],
          child: BhoomiApp(
            homeOverride: CameraCaptureScreen(
              cameraPlatformWrapper: fakeCameraPlatform,
              imageCompressor: fakeImageCompressor,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Real Camera Capture Screen is active and initialized
      expect(find.text('पीक तपासा (फोटो घ्या)'), findsOneWidget);
      expect(find.text('पानावरील किंवा खोडावरील डाग स्पष्ट दिसतील असा फोटो घ्या.'), findsOneWidget);
      expect(find.text('पाने किंवा बाधित भाग चौकटीत ठेवा'), findsOneWidget);

      // 2. Tap Shutter Capture Button
      await tester.tap(find.byIcon(Icons.camera_alt_rounded));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 300));

      // Verify camera took picture and compressed bytes
      expect(fakeCameraPlatform.lastCreatedController?.takePictureCalled, isTrue);
      expect(fakeImageCompressor.compressCalled, isTrue);

      // 3. Navigated to ImagePreviewScreen
      expect(find.byType(ImagePreviewScreen), findsOneWidget);
      expect(find.text('फोटोची खात्री करा'), findsOneWidget);
      expect(find.text('हा फोटो वापरा (तपासा)'), findsOneWidget);
      expect(find.text('पुन्हा फोटो घ्या'), findsOneWidget);

      // 4. Confirm with "Use this Photo"
      await tester.tap(find.text('हा फोटो वापरा (तपासा)'));
      await tester.pump();
      await tester.pumpAndSettle();

      // 5. Verify 2-step Presigned upload received the COMPRESSED bytes rather than mock bytes
      expect(fakeAssetRepo.lastUploadedBytes, fakeImageCompressor.compressedResult);
      expect(fakeAssetRepo.lastUploadedContentType, 'image/jpeg');
      expect(fakeDiagnosisRepo.lastFarmId, 'f_nashik_001');
      expect(fakeDiagnosisRepo.lastImageAssetId, 'asset_leaf_photo_99');

      // 6. Rendered AdvisoryResultScreen
      expect(find.byType(AdvisoryResultScreen), findsOneWidget);
      expect(find.text('BLAST'), findsOneWidget);
    });

    testWidgets('Handles camera permission denied state and allows retry',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      fakeCameraPlatform.permissionGranted = false;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            assetRepositoryProvider.overrideWithValue(fakeAssetRepo),
            diagnosisRepositoryProvider.overrideWithValue(fakeDiagnosisRepo),
          ],
          child: BhoomiApp(
            homeOverride: CameraCaptureScreen(
              cameraPlatformWrapper: fakeCameraPlatform,
              imageCompressor: fakeImageCompressor,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify permission denied message & Grant Permission button
      expect(find.text('पिकाचा फोटो घेण्यासाठी कॅमेरा परवानगी आवश्यक आहे.'), findsOneWidget);
      expect(find.text('परवानगी द्या'), findsOneWidget);

      // Grant permission and tap retry
      fakeCameraPlatform.permissionGranted = true;
      await tester.tap(find.text('परवानगी द्या'));
      await tester.pumpAndSettle();

      // Camera initializes successfully
      expect(find.text('पाने किंवा बाधित भाग चौकटीत ठेवा'), findsOneWidget);
    });

    testWidgets('Handles permanently denied permission state with settings action',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      fakeCameraPlatform.permissionPermanentlyDenied = true;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            assetRepositoryProvider.overrideWithValue(fakeAssetRepo),
            diagnosisRepositoryProvider.overrideWithValue(fakeDiagnosisRepo),
          ],
          child: BhoomiApp(
            homeOverride: CameraCaptureScreen(
              cameraPlatformWrapper: fakeCameraPlatform,
              imageCompressor: fakeImageCompressor,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify permanently denied message & Open Settings button
      expect(find.text('कॅमेरा परवानगी कायमची नाकारली आहे. कृपया ॲप सेटिंग्जमधून परवानगी द्या.'), findsOneWidget);
      expect(find.text('सेटिंग्ज उघडा'), findsOneWidget);

      // Tap settings button and verify platform wrapper received call
      await tester.tap(find.text('सेटिंग्ज उघडा'));
      await tester.pumpAndSettle();
      expect(fakeCameraPlatform.appSettingsOpened, isTrue);
    });

    testWidgets('Handles no available camera hardware on device',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      fakeCameraPlatform.cameras = [];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            assetRepositoryProvider.overrideWithValue(fakeAssetRepo),
            diagnosisRepositoryProvider.overrideWithValue(fakeDiagnosisRepo),
          ],
          child: BhoomiApp(
            homeOverride: CameraCaptureScreen(
              cameraPlatformWrapper: fakeCameraPlatform,
              imageCompressor: fakeImageCompressor,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify no camera available warning
      expect(find.text('डिव्हाइसवर कॅमेरा उपलब्ध नाही.'), findsOneWidget);
    });
  });
}
