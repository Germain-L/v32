import '../models/meal_image.dart';
import '../services/database_service.dart';
import '../services/sync_service.dart';

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

    final saved = image.copyWith(id: id);

    if (SyncService.isInitialized) {
      await SyncService.instance.queueUploadMealImage(mealId, id, imagePath);
    }

    return saved;
  }

  Future<void> deleteImage(int imageId) async {
    final db = await DatabaseService.database;
    String? remoteUrl;
    if (SyncService.isInitialized) {
      final existing = await db.query(
        'meal_images',
        columns: ['remote_url'],
        where: 'id = ?',
        whereArgs: [imageId],
        limit: 1,
      );
      if (existing.isNotEmpty) {
        remoteUrl = existing.first['remote_url'] as String?;
      }
    }

    await db.delete('meal_images', where: 'id = ?', whereArgs: [imageId]);
    await DatabaseService.notifyChange(table: 'meal_images');

    if (remoteUrl != null && SyncService.isInitialized) {
      await SyncService.instance.queueDeleteRemoteImage(remoteUrl);
      final deleted = await SyncService.instance.deleteRemoteImage(remoteUrl);
      if (deleted) {
        await SyncService.instance.completeQueuedOperation(
          'remote_image_delete:$remoteUrl',
        );
      }
    }
  }

  Future<void> deleteAllImagesForMeal(int mealId) async {
    final db = await DatabaseService.database;
    List<String> remoteUrls = const [];
    if (SyncService.isInitialized) {
      final existing = await db.query(
        'meal_images',
        columns: ['remote_url'],
        where: 'mealId = ? AND remote_url IS NOT NULL',
        whereArgs: [mealId],
      );
      remoteUrls = existing
          .map((row) => row['remote_url'] as String?)
          .whereType<String>()
          .toList(growable: false);
    }

    await db.delete('meal_images', where: 'mealId = ?', whereArgs: [mealId]);
    await DatabaseService.notifyChange(table: 'meal_images');

    if (SyncService.isInitialized) {
      for (final remoteUrl in remoteUrls) {
        await SyncService.instance.queueDeleteRemoteImage(remoteUrl);
        final deleted = await SyncService.instance.deleteRemoteImage(remoteUrl);
        if (deleted) {
          await SyncService.instance.completeQueuedOperation(
            'remote_image_delete:$remoteUrl',
          );
        }
      }
    }
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
