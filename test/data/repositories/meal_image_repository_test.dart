import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:v32/data/repositories/meal_image_repository.dart';
import 'package:v32/data/services/database_service.dart';

void main() {
  // Initialize sqflite_ffi for testing
  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    await DatabaseService.useInMemoryDatabaseForTesting();
  });

  tearDown(() async {
    // Clean up between tests
    final db = await DatabaseService.database;
    await db.delete('meal_images');
  });

  tearDownAll(() async {
    await DatabaseService.close();
  });

  group('MealImageRepository', () {
    test('getImagesForMeal returns empty list when no images', () async {
      final repository = MealImageRepository();
      final images = await repository.getImagesForMeal(999);
      expect(images, isEmpty);
    });

    test('addImage adds image and returns image with id set', () async {
      final repository = MealImageRepository();
      const mealId = 1;
      const imagePath = '/path/to/image1.jpg';

      final image = await repository.addImage(mealId, imagePath);

      expect(image.id, isNotNull);
      expect(image.mealId, equals(mealId));
      expect(image.imagePath, equals(imagePath));
      expect(image.createdAt, isA<DateTime>());
    });

    test(
      'getImagesForMeal returns images in descending order by createdAt',
      () async {
        final repository = MealImageRepository();
        const mealId = 1;

        // Add images with slight delay to ensure different timestamps
        final image1 = await repository.addImage(mealId, '/path/to/image1.jpg');
        await Future.delayed(const Duration(milliseconds: 10));
        final image2 = await repository.addImage(mealId, '/path/to/image2.jpg');
        await Future.delayed(const Duration(milliseconds: 10));
        final image3 = await repository.addImage(mealId, '/path/to/image3.jpg');

        final images = await repository.getImagesForMeal(mealId);

        expect(images.length, equals(3));
        // Should be in descending order (newest first)
        expect(images[0].id, equals(image3.id));
        expect(images[1].id, equals(image2.id));
        expect(images[2].id, equals(image1.id));
      },
    );

    test('getImagesForMeal only returns images for specified meal', () async {
      final repository = MealImageRepository();
      const mealId1 = 1;
      const mealId2 = 2;

      await repository.addImage(mealId1, '/path/to/meal1_image.jpg');
      await repository.addImage(mealId2, '/path/to/meal2_image.jpg');
      await repository.addImage(mealId1, '/path/to/meal1_image2.jpg');

      final meal1Images = await repository.getImagesForMeal(mealId1);
      final meal2Images = await repository.getImagesForMeal(mealId2);

      expect(meal1Images.length, equals(2));
      expect(meal2Images.length, equals(1));
      expect(meal2Images.first.imagePath, equals('/path/to/meal2_image.jpg'));
    });

    test('deleteImage removes specific image', () async {
      final repository = MealImageRepository();
      const mealId = 1;

      final image1 = await repository.addImage(mealId, '/path/to/image1.jpg');
      final image2 = await repository.addImage(mealId, '/path/to/image2.jpg');

      await repository.deleteImage(image1.id!);

      final images = await repository.getImagesForMeal(mealId);
      expect(images.length, equals(1));
      expect(images.first.id, equals(image2.id));
    });

    test('deleteImage does nothing when image does not exist', () async {
      final repository = MealImageRepository();

      // Should not throw
      await expectLater(repository.deleteImage(999), completes);
    });

    test('deleteAllImagesForMeal removes all images for a meal', () async {
      final repository = MealImageRepository();
      const mealId1 = 1;
      const mealId2 = 2;

      await repository.addImage(mealId1, '/path/to/meal1_image1.jpg');
      await repository.addImage(mealId1, '/path/to/meal1_image2.jpg');
      await repository.addImage(mealId2, '/path/to/meal2_image.jpg');

      await repository.deleteAllImagesForMeal(mealId1);

      final meal1Images = await repository.getImagesForMeal(mealId1);
      final meal2Images = await repository.getImagesForMeal(mealId2);

      expect(meal1Images, isEmpty);
      expect(meal2Images.length, equals(1));
    });

    test(
      'deleteAllImagesForMeal does nothing when meal has no images',
      () async {
        final repository = MealImageRepository();

        // Should not throw
        await expectLater(repository.deleteAllImagesForMeal(999), completes);
      },
    );

    test('multiple repository instances share the same database', () async {
      final repository1 = MealImageRepository();
      final repository2 = MealImageRepository();
      const mealId = 1;

      await repository1.addImage(mealId, '/path/to/image.jpg');

      final images = await repository2.getImagesForMeal(mealId);
      expect(images.length, equals(1));
    });
  });
}
