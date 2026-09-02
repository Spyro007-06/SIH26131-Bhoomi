import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/diagnosis_models.dart';
import '../../../providers/repository_providers.dart';

enum DiagnosisStatus {
  idle,
  capturing,
  previewing,
  uploading,
  diagnosing,
  success,
  error,
}

class DiagnosisState {
  final DiagnosisStatus status;
  final Uint8List? imageBytes;
  final String? assetId;
  final DiagnoseResponse? response;
  final String? errorMessage;

  const DiagnosisState({
    this.status = DiagnosisStatus.idle,
    this.imageBytes,
    this.assetId,
    this.response,
    this.errorMessage,
  });

  bool get isIdle => status == DiagnosisStatus.idle;
  bool get isPreviewing => status == DiagnosisStatus.previewing;
  bool get isUploading => status == DiagnosisStatus.uploading;
  bool get isDiagnosing => status == DiagnosisStatus.diagnosing;
  bool get isProcessing => isUploading || isDiagnosing;
  bool get isSuccess => status == DiagnosisStatus.success && response != null;
  bool get isError => status == DiagnosisStatus.error;

  DiagnosisState copyWith({
    DiagnosisStatus? status,
    Uint8List? imageBytes,
    String? assetId,
    DiagnoseResponse? response,
    String? errorMessage,
  }) {
    return DiagnosisState(
      status: status ?? this.status,
      imageBytes: imageBytes ?? this.imageBytes,
      assetId: assetId ?? this.assetId,
      response: response ?? this.response,
      errorMessage: errorMessage,
    );
  }
}

class DiagnosisNotifier extends StateNotifier<DiagnosisState> {
  final Ref _ref;

  DiagnosisNotifier(this._ref) : super(const DiagnosisState());

  void setImage(Uint8List bytes) {
    state = state.copyWith(
      status: DiagnosisStatus.previewing,
      imageBytes: bytes,
      errorMessage: null,
    );
  }

  void retake() {
    state = const DiagnosisState(status: DiagnosisStatus.capturing);
  }

  void reset() {
    state = const DiagnosisState(status: DiagnosisStatus.idle);
  }

  Future<DiagnoseResponse?> submitDiagnosis({
    required String farmId,
    String lang = 'mr-IN',
  }) async {
    final bytes = state.imageBytes;
    if (bytes == null || bytes.isEmpty) {
      state = state.copyWith(
        status: DiagnosisStatus.error,
        errorMessage: 'No image selected for diagnosis',
      );
      return null;
    }

    try {
      // Step 1 & 2: Presign and direct binary PUT upload
      state = state.copyWith(status: DiagnosisStatus.uploading, errorMessage: null);
      final assetRepo = _ref.read(assetRepositoryProvider);
      
      String assetId;
      try {
        assetId = await assetRepo.uploadImage(
          bytes: bytes,
          contentType: 'image/jpeg',
          farmId: farmId,
        );
      } catch (uploadErr) {
        state = state.copyWith(
          status: DiagnosisStatus.error,
          errorMessage: 'PHOTO_UPLOAD_FAILED: ${uploadErr.toString()}',
        );
        return null;
      }

      // Step 3: Confidence-gated diagnosis request
      state = state.copyWith(
        status: DiagnosisStatus.diagnosing,
        assetId: assetId,
      );
      final diagnosisRepo = _ref.read(diagnosisRepositoryProvider);
      final response = await diagnosisRepo.diagnose(
        farmId: farmId,
        imageAssetId: assetId,
        lang: lang,
      );

      state = state.copyWith(
        status: DiagnosisStatus.success,
        response: response,
      );
      return response;
    } catch (e) {
      state = state.copyWith(
        status: DiagnosisStatus.error,
        errorMessage: 'DIAGNOSIS_FAILED: ${e.toString()}',
      );
      return null;
    }
  }
}

final diagnosisControllerProvider =
    StateNotifierProvider<DiagnosisNotifier, DiagnosisState>((ref) {
  return DiagnosisNotifier(ref);
});
