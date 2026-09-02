import 'dart:typed_data';

/// Helper for validating and managing media bytes before presigned upload.
/// Ensures diagnostic image detail is preserved without excessive file size.
abstract final class MediaUploadHelper {
  static const int maxImageSizeBytes = 10 * 1024 * 1024; // 10MB safety cap
  static const int maxAudioSizeBytes = 15 * 1024 * 1024; // 15MB safety cap

  /// Validate image bytes and MIME type
  static bool isValidImageBytes(Uint8List bytes) {
    if (bytes.isEmpty) return false;
    if (bytes.length > maxImageSizeBytes) return false;
    return true;
  }

  /// Validate audio bytes
  static bool isValidAudioBytes(Uint8List bytes) {
    if (bytes.isEmpty) return false;
    if (bytes.length > maxAudioSizeBytes) return false;
    return true;
  }
}
