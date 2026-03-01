import 'dart:io';
import 'package:path/path.dart' as path;
import '../services/database_service.dart';
import '../services/image_storage_service.dart';

class ImageMigrationService {
  static Future<void> migrateExistingImages() async {
    final db = await DatabaseService.database;

    final mealsWithImages = await db.query(
      'meals',
      where: 'imagePath IS NOT NULL AND imagePath != ""',
    );

    print('Migrating ${mealsWithImages.length} meals with images...');

    for (final meal in mealsWithImages) {
      final mealId = meal['id'] as int;
      final oldPath = meal['imagePath'] as String;

      try {
        final oldFile = File(oldPath);
        if (!await oldFile.exists()) {
          print('Skipping meal $mealId - image not found');
          continue;
        }

        // Create meal-specific directory
        final baseDir = await ImageStorageService.imagesDirectory;
        final mealDir = Directory(path.join(baseDir.path, mealId.toString()));
        await mealDir.create(recursive: true);

        // Move image file
        final fileName = path.basename(oldPath);
        final newPath = path.join(mealDir.path, fileName);
        await oldFile.rename(newPath);

        // Insert into meal_images
        await db.insert('meal_images', {
          'mealId': mealId,
          'imagePath': newPath,
          'createdAt': DateTime.now().millisecondsSinceEpoch,
        });

        print('Migrated meal $mealId: $fileName');
      } catch (e) {
        print('Error migrating meal $mealId: $e');
      }
    }

    print('Migration complete!');
  }
}
