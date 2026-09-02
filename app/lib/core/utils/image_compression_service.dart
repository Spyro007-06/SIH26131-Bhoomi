import 'dart:typed_data';
import 'package:flutter_image_compress/flutter_image_compress.dart';

/// Abstract image compressor to allow unit testing and mock injection.
abstract class ImageCompressor {
  Future<Uint8List> compress({
    required Uint8List bytes,
    int minWidth = 1080,
    int minHeight = 1080,
    int quality = 82,
  });
}

/// Production image compressor delegating to flutter_image_compress.
class DefaultImageCompressor implements ImageCompressor {
  const DefaultImageCompressor();

  @override
  Future<Uint8List> compress({
    required Uint8List bytes,
    int minWidth = 1080,
    int minHeight = 1080,
    int quality = 82,
  }) async {
    if (bytes.isEmpty) return bytes;

    try {
      final result = await FlutterImageCompress.compressWithList(
        bytes,
        minWidth: minWidth,
        minHeight: minHeight,
        quality: quality,
        format: CompressFormat.jpeg,
      );

      if (result.isNotEmpty) {
        return Uint8List.fromList(result);
      }
      return bytes;
    } catch (_) {
      // In headless unit tests or unsupported hardware formats, safely return original bytes
      return bytes;
    }
  }
}

/// Image compression service for preprocessing crop photographs prior to presigned upload.
/// Reduces 5-10MB high-res camera captures to ~150-350KB while preserving leaf disease lesion fidelity.
class ImageCompressionService {
  final ImageCompressor _compressor;

  const ImageCompressionService({ImageCompressor? compressor})
      : _compressor = compressor ?? const DefaultImageCompressor();

  /// Compresses raw image bytes to an upload-optimized JPEG.
  Future<Uint8List> compress(Uint8List rawBytes) async {
    if (rawBytes.isEmpty) return rawBytes;
    return await _compressor.compress(bytes: rawBytes);
  }
}
