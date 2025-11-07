// lib/services/image_compression_service.dart

import 'dart:io';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'dart:developer' as developer;

/// Enum to define different image types with their compression settings
enum ImageType {
  profilePhoto,
  galleryImage,
}

/// Service for compressing images with progress tracking
class ImageCompressionService {
  final List<File> _tempFiles = [];

  /// Compress an image file with progress tracking
  /// 
  /// [file] - The image file to compress
  /// [type] - The type of image (profilePhoto or galleryImage)
  /// [onProgress] - Optional callback for compression progress (0.0 to 1.0)
  /// 
  /// Returns the compressed file
  Future<File> compressImage(
    File file,
    ImageType type, {
    void Function(double)? onProgress,
  }) async {
    try {
      onProgress?.call(0.1);
      
      // Read original file
      final imageBytes = await file.readAsBytes();
      onProgress?.call(0.3);
      
      // Decode image
      final originalImage = img.decodeImage(imageBytes);
      if (originalImage == null) {
        developer.log('Failed to decode image, returning original', name: 'ImageCompressionService');
        return file;
      }
      onProgress?.call(0.5);
      
      // Get compression settings based on image type
      final settings = _getCompressionSettings(type);
      
      // Resize if needed
      img.Image resizedImage = originalImage;
      if (originalImage.width > settings.maxWidth || originalImage.height > settings.maxHeight) {
        resizedImage = img.copyResize(
          originalImage,
          width: settings.maxWidth,
          height: settings.maxHeight,
          maintainAspect: true,
        );
      }
      onProgress?.call(0.7);
      
      // Encode with compression
      final compressedImageBytes = img.encodeJpg(
        resizedImage,
        quality: settings.quality,
      );
      onProgress?.call(0.9);
      
      // Save to temporary file
      final tempDir = await getTemporaryDirectory();
      final compressedFile = File(
        '${tempDir.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg'
      );
      await compressedFile.writeAsBytes(compressedImageBytes);
      
      // Track temp file for cleanup
      _tempFiles.add(compressedFile);
      
      onProgress?.call(1.0);
      
      final originalSize = file.lengthSync();
      final compressedSize = compressedFile.lengthSync();
      final compressionRatio = ((1 - compressedSize / originalSize) * 100).toStringAsFixed(1);
      
      developer.log(
        'Image compressed: ${originalSize} bytes -> ${compressedSize} bytes ($compressionRatio% reduction)',
        name: 'ImageCompressionService'
      );
      
      return compressedFile;
    } catch (e) {
      developer.log('Error compressing image: $e', name: 'ImageCompressionService');
      // Return original file if compression fails
      return file;
    }
  }

  /// Get compression settings based on image type
  _CompressionSettings _getCompressionSettings(ImageType type) {
    switch (type) {
      case ImageType.profilePhoto:
        return _CompressionSettings(
          maxWidth: 800,
          maxHeight: 800,
          quality: 85,
        );
      case ImageType.galleryImage:
        return _CompressionSettings(
          maxWidth: 800,
          maxHeight: 800,
          quality: 80,
        );
    }
  }

  /// Clean up temporary compressed files
  void cleanupTempFiles() {
    for (final file in _tempFiles) {
      try {
        if (file.existsSync()) {
          file.deleteSync();
        }
      } catch (e) {
        developer.log('Error deleting temp file: $e', name: 'ImageCompressionService');
      }
    }
    _tempFiles.clear();
  }
}

/// Internal class to hold compression settings
class _CompressionSettings {
  final int maxWidth;
  final int maxHeight;
  final int quality;

  _CompressionSettings({
    required this.maxWidth,
    required this.maxHeight,
    required this.quality,
  });
}

