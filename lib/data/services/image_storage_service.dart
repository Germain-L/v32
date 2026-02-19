import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:image/image.dart' as img;

class ImageStorageService {
  static Directory? _imagesDir;

  static Future<Directory> get _directory async {
    _imagesDir ??= await _initDirectory();
    return _imagesDir!;
  }

  static Future<Directory> _initDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final imagesDir = Directory(path.join(appDir.path, 'meal_images'));

    if (!await imagesDir.exists()) {
      await imagesDir.create(recursive: true);
    }

    return imagesDir;
  }

  /// Save an image file to app storage with optional compression
  static Future<String?> saveImage(
    File sourceFile, {
    int maxWidth = 1200,
    int quality = 85,
  }) async {
    try {
      final dir = await _directory;
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final randomBits = timestamp.remainder(1000000);
      final fileName = '${timestamp}_$randomBits.jpg';
      final targetPath = path.join(dir.path, fileName);

      // Read and decode image
      final bytes = await sourceFile.readAsBytes();
      img.Image? image = img.decodeImage(bytes);

      if (image == null) return null;

      // Resize if too large
      if (image.width > maxWidth) {
        image = img.copyResize(image, width: maxWidth);
      }

      // Compress and save
      final compressedBytes = img.encodeJpg(image, quality: quality);
      final targetFile = File(targetPath);
      await targetFile.writeAsBytes(compressedBytes);

      return targetPath;
    } catch (e) {
      return null;
    }
  }

  /// Delete an image file
  static Future<bool> deleteImage(String? imagePath) async {
    if (imagePath == null || imagePath.isEmpty) return false;

    try {
      final file = File(imagePath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Get image file if it exists
  static Future<File?> getImage(String? imagePath) async {
    if (imagePath == null || imagePath.isEmpty) return null;

    final file = File(imagePath);
    if (await file.exists()) {
      return file;
    }
    return null;
  }

  /// Check if image exists
  static Future<bool> imageExists(String? imagePath) async {
    if (imagePath == null || imagePath.isEmpty) return false;

    final file = File(imagePath);
    return await file.exists();
  }

  /// Get total size of all stored images in bytes
  static Future<int> getTotalStorageSize() async {
    try {
      final dir = await _directory;
      int totalSize = 0;

      await for (final entity in dir.list()) {
        if (entity is File) {
          totalSize += await entity.length();
        }
      }

      return totalSize;
    } catch (e) {
      return 0;
    }
  }

  /// Clean up orphaned images (not referenced in database)
  static Future<int> cleanupOrphanedImages(List<String> validPaths) async {
    try {
      final dir = await _directory;
      int deletedCount = 0;

      await for (final entity in dir.list()) {
        if (entity is File) {
          if (!validPaths.contains(entity.path)) {
            await entity.delete();
            deletedCount++;
          }
        }
      }

      return deletedCount;
    } catch (e) {
      return 0;
    }
  }
}
