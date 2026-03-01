import '../models/meal_image.dart';
import '../services/database_service.dart';

class MealImageRepository {
  Future<List<MealImage>> getImagesForMeal(int mealId) async {
    final db = await DatabaseService.database;
    final maps = await db.query(
      'meal_images',
      where: 'mealId = ?',
      whereArgs: [mealId],
      orderBy: 'createdAt DESC',
    );

    return maps.map((map) => MealImage.fromMap(map)).toList();
  }

  Future<MealImage> addImage(int mealId, String imagePath) async {
    final db = await DatabaseService.database;
    final now = DateTime.now();
    final image = MealImage(
      mealId: mealId,
      imagePath: imagePath,
      createdAt: now,
    );

    final id = await db.insert('meal_images', image.toMap()..remove('id'));
    await DatabaseService.notifyChange(table: 'meal_images');

    return image.copyWith(id: id);
  }

  Future<void> deleteImage(int imageId) async {
    final db = await DatabaseService.database;
    await db.delete('meal_images', where: 'id = ?', whereArgs: [imageId]);
    await DatabaseService.notifyChange(table: 'meal_images');
  }

  Future<void> deleteAllImagesForMeal(int mealId) async {
    final db = await DatabaseService.database;
    await db.delete('meal_images', where: 'mealId = ?', whereArgs: [mealId]);
    await DatabaseService.notifyChange(table: 'meal_images');
  }
}

extension MealImageCopyWith on MealImage {
  MealImage copyWith({
    int? id,
    int? mealId,
    String? imagePath,
    DateTime? createdAt,
  }) {
    return MealImage(
      id: id ?? this.id,
      mealId: mealId ?? this.mealId,
      imagePath: imagePath ?? this.imagePath,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
