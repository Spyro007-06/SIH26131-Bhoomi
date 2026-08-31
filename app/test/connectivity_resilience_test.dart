import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:bhoomi/main.dart';
import 'package:bhoomi/features/diagnose/presentation/diagnosis_loading_screen.dart';
import 'package:bhoomi/features/diagnose/presentation/diagnosis_controller.dart';
import 'package:bhoomi/repositories/asset_repository.dart';
import 'package:bhoomi/repositories/diagnosis_repository.dart';
import 'package:bhoomi/providers/repository_providers.dart';
import 'package:bhoomi/models/asset_models.dart';
import 'package:bhoomi/models/diagnosis_models.dart';

class FailingUploadAssetRepo extends AssetRepository {
  @override
  Future<PresignedAssetModel> presignAsset({
    required String kind,
    required String contentType,
    String? farmId,
  }) async => throw Exception('S3 upload connection timed out');

  @override
  Future<void> uploadBinary({
    required String uploadUrl,
    required Uint8List bytes,
    required String contentType,
    ProgressCallback? onProgress,
  }) async => throw Exception('Binary stream broken');

  @override
  Future<String> uploadImage({
    required Uint8List bytes,
    String contentType = 'image/jpeg',
    String? farmId,
    ProgressCallback? onProgress,
  }) async {
    throw Exception('Network unreachable during photo upload');
  }

  @override
  Future<String> uploadAudio({
    required Uint8List bytes,
    String contentType = 'audio/wav',
    String? farmId,
    ProgressCallback? onProgress,
  }) => throw UnimplementedError();
}

class FailingDiagnosisRepo extends DiagnosisRepository {
  @override
  Future<DiagnoseResponse> diagnose({
    required String farmId,
    required String imageAssetId,
    String? descriptionAssetId,
    String? descriptionText,
    String lang = 'mr-IN',
  }) async {
    throw Exception('Gateway timeout 504');
  }
}

class SuccessAssetRepo extends AssetRepository {
  @override
  Future<PresignedAssetModel> presignAsset({
    required String kind,
    required String contentType,
    String? farmId,
  }) async => throw UnimplementedError();

  @override
  Future<void> uploadBinary({
    required String uploadUrl,
    required Uint8List bytes,
    required String contentType,
    ProgressCallback? onProgress,
  }) async => throw UnimplementedError();

  @override
  Future<String> uploadImage({
    required Uint8List bytes,
    String contentType = 'image/jpeg',
    String? farmId,
    ProgressCallback? onProgress,
  }) async => 'asset_ok_123';

  @override
  Future<String> uploadAudio({
    required Uint8List bytes,
    String contentType = 'audio/wav',
    String? farmId,
    ProgressCallback? onProgress,
  }) async => 'audio_ok_123';
}

void main() {
  group('Low-Connectivity & Upload Resilience Tests (Step 6)', () {
    testWidgets('Photo upload failure renders honest rural error state with retry and change photo actions',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      final container = ProviderContainer(
        overrides: [
          assetRepositoryProvider.overrideWithValue(FailingUploadAssetRepo()),
        ],
      );
      addTearDown(container.dispose);

      // Pre-set sample image bytes in controller
      container.read(diagnosisControllerProvider.notifier).setImage(
            Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xD9]),
          );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const BhoomiApp(
            homeOverride: DiagnosisLoadingScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify human-friendly rural error message is displayed
      expect(find.text('फोटो अपलोड अयशस्वी झाला'), findsOneWidget);
      expect(find.textContaining('तुमचा फोटो सुरक्षित आहे'), findsOneWidget);

      // Verify Retry and Change Photo action buttons exist
      expect(find.text('पुन्हा प्रयत्न करा'), findsOneWidget);
      expect(find.text('दुसरा फोटो निवडा'), findsOneWidget);
    });

    testWidgets('Diagnosis inference failure renders timeout error and allows retry',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      final container = ProviderContainer(
        overrides: [
          assetRepositoryProvider.overrideWithValue(SuccessAssetRepo()),
          diagnosisRepositoryProvider.overrideWithValue(FailingDiagnosisRepo()),
        ],
      );
      addTearDown(container.dispose);

      container.read(diagnosisControllerProvider.notifier).setImage(
            Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xD9]),
          );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const BhoomiApp(
            homeOverride: DiagnosisLoadingScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify diagnosis timeout title and explanation
      expect(find.text('निदान प्रक्रियेस वेळ लागत आहे'), findsOneWidget);
      expect(find.textContaining('नेटवर्क धीमे असल्याने वेळ लागत आहे'), findsOneWidget);
      expect(find.text('पुन्हा प्रयत्न करा'), findsOneWidget);
    });
  });
}
