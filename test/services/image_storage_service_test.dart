import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:v32/data/services/image_storage_service.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const MethodChannel channel = MethodChannel(
    'plugins.flutter.io/path_provider',
  );

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          if (call.method == 'getApplicationDocumentsDirectory') {
            return Directory.systemTemp.path;
          }
          return null;
        });
  });
  Future<File> createTestImage() async {
    final image = img.Image(width: 20, height: 20);
    final bytes = img.encodeJpg(image);
    final file = File('${Directory.systemTemp.path}/diet_test_image.jpg');
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  test('saveImage returns null on invalid data', () async {
    final file = File('${Directory.systemTemp.path}/diet_invalid_image.txt');
    await file.writeAsString('not an image', flush: true);

    final result = await ImageStorageService.saveImage(file);
    expect(result, isNull);
  });

  test('saveImage stores file and imageExists returns true', () async {
    final file = await createTestImage();
    final path = await ImageStorageService.saveImage(file, maxWidth: 10);

    expect(path, isNotNull);
    expect(await ImageStorageService.imageExists(path), isTrue);
  });

  test('deleteImage returns false for null or empty path', () async {
    expect(await ImageStorageService.deleteImage(null), isFalse);
    expect(await ImageStorageService.deleteImage(''), isFalse);
  });

  test('getImage returns null for missing file', () async {
    final file = await ImageStorageService.getImage('/nope/file.jpg');
    expect(file, isNull);
  });

  test('cleanupOrphanedImages deletes unreferenced files', () async {
    final file = await createTestImage();
    final path = await ImageStorageService.saveImage(file);
    final another = await createTestImage();
    final orphanPath = await ImageStorageService.saveImage(another);

    if (path == null) {
      fail('Expected saveImage to return a path');
    }

    final deleted = await ImageStorageService.cleanupOrphanedImages([path]);

    expect(deleted, greaterThanOrEqualTo(1));
    expect(await ImageStorageService.imageExists(orphanPath), isFalse);
  });

  test('getTotalStorageSize returns non-zero for saved images', () async {
    final file = await createTestImage();
    await ImageStorageService.saveImage(file);

    final size = await ImageStorageService.getTotalStorageSize();
    expect(size, greaterThan(0));
  });
}
