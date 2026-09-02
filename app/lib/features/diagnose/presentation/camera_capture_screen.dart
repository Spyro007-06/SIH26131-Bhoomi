import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/localization/locale_provider.dart';
import '../../../core/utils/camera_service.dart';
import '../../../core/utils/image_compression_service.dart';
import '../../../core/error/app_exception.dart';
import '../../../widgets/app_button.dart';
import '../../../widgets/language_selector_button.dart';
import 'diagnosis_controller.dart';
import 'image_preview_screen.dart';

/// Farmer-friendly Real Device Camera Capture Screen for Crop Diagnosis.
class CameraCaptureScreen extends ConsumerStatefulWidget {
  final VoidCallback? onBack;
  final CameraPlatformWrapper? cameraPlatformWrapper;
  final ImageCompressor? imageCompressor;
  final CameraController? cameraControllerOverride;

  const CameraCaptureScreen({
    super.key,
    this.onBack,
    this.cameraPlatformWrapper,
    this.imageCompressor,
    this.cameraControllerOverride,
  });

  @override
  ConsumerState<CameraCaptureScreen> createState() => _CameraCaptureScreenState();
}

class _CameraCaptureScreenState extends ConsumerState<CameraCaptureScreen>
    with WidgetsBindingObserver {
  CameraController? _cameraController;
  CameraStateStatus _cameraStatus = CameraStateStatus.uninitialized;
  String? _errorMessage;
  bool _isProcessingCapture = false;
  FlashMode _currentFlashMode = FlashMode.auto;

  late final CameraPlatformWrapper _cameraPlatform;
  late final ImageCompressor _imageCompressor;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _cameraPlatform = widget.cameraPlatformWrapper ?? const DefaultCameraPlatformWrapper();
    _imageCompressor = widget.imageCompressor ?? const DefaultImageCompressor();

    if (widget.cameraControllerOverride != null) {
      _cameraController = widget.cameraControllerOverride;
      _cameraStatus = CameraStateStatus.ready;
    } else {
      _initializeCamera();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (widget.cameraControllerOverride == null) {
      _cameraController?.dispose();
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (widget.cameraControllerOverride != null) return;

    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      // Free camera hardware resources while app is backgrounded
      controller.dispose();
      _cameraController = null;
      if (mounted) {
        setState(() => _cameraStatus = CameraStateStatus.uninitialized);
      }
    } else if (state == AppLifecycleState.resumed) {
      // Re-initialize camera upon user returning to app
      _initializeCamera();
    }
  }

  Future<void> _initializeCamera() async {
    if (!mounted) return;
    setState(() {
      _cameraStatus = CameraStateStatus.initializing;
      _errorMessage = null;
    });

    try {
      // 1. Check & request camera runtime permission
      final isPermanentlyDenied = await _cameraPlatform.isCameraPermissionPermanentlyDenied();
      if (isPermanentlyDenied) {
        if (mounted) {
          setState(() => _cameraStatus = CameraStateStatus.permissionPermanentlyDenied);
        }
        return;
      }

      var isGranted = await _cameraPlatform.isCameraPermissionGranted();
      if (!isGranted) {
        isGranted = await _cameraPlatform.requestCameraPermission();
      }

      if (!isGranted) {
        final permDeniedForever = await _cameraPlatform.isCameraPermissionPermanentlyDenied();
        if (mounted) {
          setState(() {
            _cameraStatus = permDeniedForever
                ? CameraStateStatus.permissionPermanentlyDenied
                : CameraStateStatus.permissionDenied;
          });
        }
        return;
      }

      // 2. Discover available cameras on device
      final cameras = await _cameraPlatform.getAvailableCameras();
      if (cameras.isEmpty) {
        if (mounted) {
          setState(() => _cameraStatus = CameraStateStatus.noCameraAvailable);
        }
        return;
      }

      // 3. Select back/rear camera if available, otherwise first camera
      final selectedCamera = cameras.firstWhere(
        (cam) => cam.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      // 4. Dispose previous controller if any
      await _cameraController?.dispose();

      // 5. Initialize camera controller
      final controller = _cameraPlatform.createController(
        camera: selectedCamera,
        resolutionPreset: ResolutionPreset.high,
        enableAudio: false,
      );

      await controller.initialize();

      if (!mounted) {
        await controller.dispose();
        return;
      }

      setState(() {
        _cameraController = controller;
        _cameraStatus = CameraStateStatus.ready;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _cameraStatus = CameraStateStatus.error;
          _errorMessage = e.toString();
        });
      }
    }
  }

  Future<void> _onCapturePressed() async {
    if (_isProcessingCapture) return;

    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) {
      final strings = ref.read(stringsProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.cameraInitializing)),
      );
      return;
    }

    setState(() => _isProcessingCapture = true);

    try {
      // 1. Capture real photograph through camera hardware
      final xFile = await controller.takePicture();
      final rawBytes = await xFile.readAsBytes();

      if (rawBytes.isEmpty) {
        throw const CameraServiceException(
          message: 'Captured image was empty. Please try again.',
        );
      }

      // 2. Compress photo for optimal network transmission and ML diagnosis accuracy
      final compressedBytes = await _imageCompressor.compress(bytes: rawBytes);

      // 3. Clean up temporary photo file on disk
      try {
        final path = xFile.path;
        if (path.isNotEmpty) {
          final tempFile = File(path);
          if (await tempFile.exists()) {
            await tempFile.delete();
          }
        }
      } catch (_) {}

      // 4. Update Riverpod diagnosis state
      ref.read(diagnosisControllerProvider.notifier).setImage(compressedBytes);

      setState(() => _isProcessingCapture = false);

      // 5. Navigate to preview and confirmation screen
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => ImagePreviewScreen(imageBytes: compressedBytes),
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessingCapture = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  Future<void> _toggleFlash() async {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) return;

    try {
      FlashMode nextMode;
      switch (_currentFlashMode) {
        case FlashMode.auto:
          nextMode = FlashMode.always;
          break;
        case FlashMode.always:
          nextMode = FlashMode.off;
          break;
        case FlashMode.off:
        default:
          nextMode = FlashMode.auto;
          break;
      }
      await controller.setFlashMode(nextMode);
      if (mounted) {
        setState(() => _currentFlashMode = nextMode);
      }
    } catch (_) {
      // Flash mode not supported by device hardware
    }
  }

  void _onGalleryPressed() {
    final strings = ref.read(stringsProvider);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(strings.cameraInstruction),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(stringsProvider);

    return Scaffold(
      backgroundColor: AppColors.soilCharcoal,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          tooltip: 'Back',
          onPressed: () {
            if (widget.onBack != null) {
              widget.onBack!();
            } else if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            }
          },
        ),
        title: Text(
          strings.cameraTitle,
          style: AppTypography.subheading.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: const [
          LanguageSelectorButton(isDarkBackground: true),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Top Farmer Instruction Banner
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.l16,
                vertical: AppSpacing.s8,
              ),
              color: Colors.black.withValues(alpha: 0.4),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, color: AppColors.turmeric, size: 20),
                  const SizedBox(width: AppSpacing.s8),
                  Expanded(
                    child: Text(
                      strings.cameraInstruction,
                      style: AppTypography.bodySmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Camera Viewfinder & Framing Reticle
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.m16,
                        vertical: AppSpacing.s8,
                      ),
                      child: AspectRatio(
                        aspectRatio: 3 / 4,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.8),
                            borderRadius: AppRadius.card,
                            border: Border.all(
                              color: AppColors.primaryLight.withValues(alpha: 0.6),
                              width: 2,
                            ),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Stack(
                            fit: StackFit.expand,
                            alignment: Alignment.center,
                            children: [
                              // 1. Camera Preview or State Widget
                              _buildCameraViewfinderContent(strings),

                              // 2. Leaf framing guidance overlay
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.eco_rounded,
                                    size: 96,
                                    color: Colors.white.withValues(alpha: 0.2),
                                  ),
                                  const SizedBox(height: AppSpacing.m16),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppSpacing.m16,
                                      vertical: AppSpacing.s6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(alpha: 0.5),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: Colors.white.withValues(alpha: 0.3),
                                      ),
                                    ),
                                    child: Text(
                                      strings.cameraFrameGuide,
                                      style: AppTypography.caption.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              // 3. Reticle Framing Corners
                              const Positioned(
                                top: 16,
                                left: 16,
                                child: _CornerReticle(top: true, left: true),
                              ),
                              const Positioned(
                                top: 16,
                                right: 16,
                                child: _CornerReticle(top: true, left: false),
                              ),
                              const Positioned(
                                bottom: 16,
                                left: 16,
                                child: _CornerReticle(top: false, left: true),
                              ),
                              const Positioned(
                                bottom: 16,
                                right: 16,
                                child: _CornerReticle(top: false, left: false),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // Bottom Controls Bar
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.l24,
                vertical: AppSpacing.m12,
              ),
              color: Colors.black.withValues(alpha: 0.5),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  // Gallery Button
                  Semantics(
                    label: strings.galleryButton,
                    button: true,
                    child: IconButton(
                      iconSize: 32,
                      icon: const Icon(Icons.photo_library_outlined, color: Colors.white),
                      tooltip: strings.galleryButton,
                      onPressed: _onGalleryPressed,
                    ),
                  ),

                  // Dominant Shutter Button
                  Semantics(
                    label: strings.semanticsCapturePhoto,
                    button: true,
                    child: GestureDetector(
                      onTap: _isProcessingCapture ? null : _onCapturePressed,
                      child: Container(
                        width: 76,
                        height: 76,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.ricePaper,
                          border: Border.all(color: AppColors.forest, width: 4),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.white.withValues(alpha: 0.3),
                              blurRadius: 12,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Container(
                            width: 58,
                            height: 58,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.forest,
                            ),
                            child: _isProcessingCapture
                                ? const Center(
                                    child: SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2.5,
                                      ),
                                    ),
                                  )
                                : const Icon(
                                    Icons.camera_alt_rounded,
                                    color: Colors.white,
                                    size: 30,
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Flash Mode Toggle Button
                  Semantics(
                    label: strings.semanticsToggleFlash,
                    button: true,
                    child: IconButton(
                      iconSize: 32,
                      icon: Icon(
                        _currentFlashMode == FlashMode.always
                            ? Icons.flash_on_rounded
                            : (_currentFlashMode == FlashMode.off
                                ? Icons.flash_off_rounded
                                : Icons.flash_auto_rounded),
                        color: Colors.white,
                      ),
                      tooltip: strings.semanticsToggleFlash,
                      onPressed: _toggleFlash,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraViewfinderContent(dynamic strings) {
    if (_cameraStatus == CameraStateStatus.ready &&
        _cameraController != null &&
        _cameraController!.value.isInitialized) {
      return FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: _cameraController!.value.previewSize?.height ?? 1,
          height: _cameraController!.value.previewSize?.width ?? 1,
          child: _cameraController!.buildPreview(),
        ),
      );
    }

    if (_cameraStatus == CameraStateStatus.initializing) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: AppColors.primaryLight),
            const SizedBox(height: AppSpacing.m16),
            Text(
              strings.cameraInitializing,
              style: AppTypography.bodySmall.copyWith(color: Colors.white),
            ),
          ],
        ),
      );
    }

    if (_cameraStatus == CameraStateStatus.permissionDenied) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.l20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.videocam_off_rounded, color: AppColors.turmeric, size: 54),
            const SizedBox(height: AppSpacing.m16),
            Text(
              strings.cameraPermissionRequired,
              style: AppTypography.bodySmall.copyWith(color: Colors.white),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.m16),
            AppButton.outline(
              label: strings.grantPermissionButton,
              onPressed: _initializeCamera,
            ),
          ],
        ),
      );
    }

    if (_cameraStatus == CameraStateStatus.permissionPermanentlyDenied) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.l20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.settings_suggest_rounded, color: AppColors.turmeric, size: 54),
            const SizedBox(height: AppSpacing.m16),
            Text(
              strings.cameraPermissionDeniedForever,
              style: AppTypography.bodySmall.copyWith(color: Colors.white),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.m16),
            AppButton.outline(
              label: strings.openSettingsButton,
              onPressed: () => _cameraPlatform.openAppSettings(),
            ),
          ],
        ),
      );
    }

    if (_cameraStatus == CameraStateStatus.noCameraAvailable) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.l20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.no_photography_rounded, color: AppColors.turmeric, size: 54),
            const SizedBox(height: AppSpacing.m16),
            Text(
              strings.cameraUnavailable,
              style: AppTypography.bodySmall.copyWith(color: Colors.white),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.l20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline_rounded, color: AppColors.danger, size: 54),
          const SizedBox(height: AppSpacing.m16),
          Text(
            _errorMessage ?? strings.cameraError,
            style: AppTypography.bodySmall.copyWith(color: Colors.white),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.m16),
          AppButton.outline(
            label: strings.retakeButton,
            onPressed: _initializeCamera,
          ),
        ],
      ),
    );
  }
}

class _CornerReticle extends StatelessWidget {
  final bool top;
  final bool left;

  const _CornerReticle({required this.top, required this.left});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        border: Border(
          top: top ? const BorderSide(color: AppColors.turmeric, width: 3) : BorderSide.none,
          bottom: !top ? const BorderSide(color: AppColors.turmeric, width: 3) : BorderSide.none,
          left: left ? const BorderSide(color: AppColors.turmeric, width: 3) : BorderSide.none,
          right: !left ? const BorderSide(color: AppColors.turmeric, width: 3) : BorderSide.none,
        ),
      ),
    );
  }
}
