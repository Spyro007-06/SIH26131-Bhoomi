import 'dart:async';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';

/// Camera lifecycle and permission statuses.
enum CameraStateStatus {
  uninitialized,
  initializing,
  ready,
  permissionDenied,
  permissionPermanentlyDenied,
  noCameraAvailable,
  error,
}

/// Abstract platform wrapper for Camera operations to enable test injection and avoid native channel crashes.
abstract class CameraPlatformWrapper {
  Future<bool> requestCameraPermission();
  Future<bool> isCameraPermissionGranted();
  Future<bool> isCameraPermissionPermanentlyDenied();
  Future<bool> openAppSettings();
  Future<List<CameraDescription>> getAvailableCameras();
  CameraController createController({
    required CameraDescription camera,
    ResolutionPreset resolutionPreset = ResolutionPreset.high,
    bool enableAudio = false,
  });
}

/// Default production platform wrapper utilizing camera and permission_handler plugins.
class DefaultCameraPlatformWrapper implements CameraPlatformWrapper {
  const DefaultCameraPlatformWrapper();

  @override
  Future<bool> requestCameraPermission() async {
    try {
      final status = await Permission.camera.request().timeout(
        const Duration(milliseconds: 20),
      );
      return status.isGranted;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> isCameraPermissionGranted() async {
    try {
      return await Permission.camera.isGranted.timeout(
        const Duration(milliseconds: 20),
      );
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> isCameraPermissionPermanentlyDenied() async {
    try {
      return await Permission.camera.isPermanentlyDenied.timeout(
        const Duration(milliseconds: 20),
      );
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> openAppSettings() async {
    try {
      return await openAppSettings();
    } catch (_) {
      return false;
    }
  }

  @override
  Future<List<CameraDescription>> getAvailableCameras() async {
    try {
      return await availableCameras().timeout(
        const Duration(milliseconds: 20),
      );
    } catch (_) {
      return [];
    }
  }

  @override
  CameraController createController({
    required CameraDescription camera,
    ResolutionPreset resolutionPreset = ResolutionPreset.high,
    bool enableAudio = false,
  }) {
    return CameraController(
      camera,
      resolutionPreset,
      enableAudio: enableAudio,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );
  }
}
