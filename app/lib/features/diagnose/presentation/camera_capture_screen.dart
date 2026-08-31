import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/localization/locale_provider.dart';
import 'diagnosis_controller.dart';
import 'image_preview_screen.dart';

/// Farmer-friendly Camera Capture Screen for Crop Diagnosis.
class CameraCaptureScreen extends ConsumerStatefulWidget {
  final VoidCallback? onBack;

  const CameraCaptureScreen({
    super.key,
    this.onBack,
  });

  @override
  ConsumerState<CameraCaptureScreen> createState() => _CameraCaptureScreenState();
}

class _CameraCaptureScreenState extends ConsumerState<CameraCaptureScreen> {
  // Generate sample image bytes for demonstration / camera capture
  Uint8List _generateSampleLeafBytes() {
    return Uint8List.fromList([
      0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10, 0x4A, 0x46, 0x49, 0x46, 0x00, 0x01,
      0x01, 0x01, 0x00, 0x60, 0x00, 0x60, 0x00, 0x00, 0xFF, 0xDB, 0x00, 0x43,
      0x00, 0x08, 0x06, 0x06, 0x07, 0x06, 0x05, 0x08, 0x07, 0x07, 0x07, 0x09,
      0xFF, 0xD9
    ]);
  }

  void _onCapturePressed() {
    final sampleBytes = _generateSampleLeafBytes();
    ref.read(diagnosisControllerProvider.notifier).setImage(sampleBytes);

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ImagePreviewScreen(imageBytes: sampleBytes),
      ),
    );
  }

  void _onGalleryPressed() {
    final sampleBytes = _generateSampleLeafBytes();
    ref.read(diagnosisControllerProvider.notifier).setImage(sampleBytes);

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ImagePreviewScreen(imageBytes: sampleBytes),
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
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Top Farmer Instruction Banner
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.l20,
                vertical: AppSpacing.m12,
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

            // Camera Viewfinder & Framing Guide
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.l24),
                  child: AspectRatio(
                    aspectRatio: 3 / 4,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: AppRadius.card,
                        border: Border.all(
                          color: AppColors.primaryLight.withValues(alpha: 0.6),
                          width: 2,
                        ),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Leaf framing silhouette / helper
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
                                  'पाने / खोड चौकटीत ठेवा',
                                  style: AppTypography.caption.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          // Framing Reticle Corners
                          Positioned(
                            top: 16,
                            left: 16,
                            child: _CornerReticle(top: true, left: true),
                          ),
                          Positioned(
                            top: 16,
                            right: 16,
                            child: _CornerReticle(top: true, left: false),
                          ),
                          Positioned(
                            bottom: 16,
                            left: 16,
                            child: _CornerReticle(top: false, left: true),
                          ),
                          Positioned(
                            bottom: 16,
                            right: 16,
                            child: _CornerReticle(top: false, left: false),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Bottom Controls Bar
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xl32,
                vertical: AppSpacing.l24,
              ),
              color: Colors.black.withValues(alpha: 0.5),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  // Gallery Pick Button
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
                      onTap: _onCapturePressed,
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
                            child: const Icon(
                              Icons.camera_alt_rounded,
                              color: Colors.white,
                              size: 30,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Flash / Light Helper Button
                  Semantics(
                    label: strings.semanticsToggleFlash,
                    button: true,
                    child: IconButton(
                      iconSize: 32,
                      icon: const Icon(Icons.flash_auto_rounded, color: Colors.white),
                      tooltip: 'Flash',
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Camera lighting optimized for field sunlight.'),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      },
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
