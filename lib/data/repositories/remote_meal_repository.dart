import 'dart:developer' as dev;
import '../models/meal.dart';
import '../models/sync_operation.dart';
import '../services/database_service.dart';
import '../services/sync_config.dart';
import '../services/sync_service.dart';
import 'local_meal_repository.dart';
import 'meal_repository_interface.dart';

/// A meal repository that treats the backend as source of truth.
/// Local storage acts as a cache.
/// Handles offline gracefully by queuing changes for later sync.
class RemoteMealRepository implements MealRepository {
  final LocalMealRepository _cache;
  final SyncService? _syncService;

  RemoteMealRepository({
    LocalMealRepository? cache,
    SyncService? syncService,
  })  : _cache = cache ?? LocalMealRepository(),
        _syncService = syncService;

  /// Create with sync enabled (if configured).
  factory RemoteMealRepository.withSync() {
    _log(
      'Creating RemoteMealRepository, sync enabled: ${SyncConfig.enabled && SyncConfig.hasCredentials}',
    );

    if (!SyncConfig.enabled || !SyncConfig.hasCredentials) {
      _log('Sync disabled by config - using local-only mode');
      return RemoteMealRepository(syncService: null);
    }

    try {
      final syncService = SyncService.instance;
      _log('SyncService obtained successfully');
      return RemoteMealRepository(syncService: syncService);
    } catch (e) {
      _log('SyncService not initialized - sync disabled: $e');
      return RemoteMealRepository(syncService: null);
    }
  }

  static void _log(String message) {
    dev.log('[REMOTE_REPO] $message', name: 'v32');
  }

  Future<String?> _getRemotePrimaryImageUrl(int mealId) async {
    final db = await DatabaseService.database;
    final results = await db.query(
      'meals',
      columns: ['remote_image_url'],
      where: 'id = ?',
      whereArgs: [mealId],
      limit: 1,
    );
    if (results.isEmpty) {
      return null;
    }
    return results.first['remote_image_url'] as String?;
  }

  Future<void> _clearRemotePrimaryImageUrl(int mealId) async {
    final db = await DatabaseService.database;
    await db.update(
      'meals',
      {'remote_image_url': null},
      where: 'id = ?',
      whereArgs: [mealId],
    );
  }

  Future<List<String>> _getRemoteGalleryImageUrls(int mealId) async {
    final db = await DatabaseService.database;
    final results = await db.query(
      'meal_images',
      columns: ['remote_url'],
      where: 'mealId = ? AND remote_url IS NOT NULL',
      whereArgs: [mealId],
    );
    return results
        .map((row) => row['remote_url'] as String?)
        .whereType<String>()
        .toList(growable: false);
  }

  @override
  Future<Meal> saveMeal(Meal meal) async {
    _log('saveMeal: slot=${meal.slot.name}, id=${meal.id}');

    final existingMeal =
        meal.id != null ? await _cache.getMealById(meal.id!) : null;
    final syncService = _syncService;
    if (existingMeal?.imagePath != null &&
        existingMeal!.imagePath != meal.imagePath &&
        syncService != null &&
        meal.id != null) {
      final remoteUrl = await _getRemotePrimaryImageUrl(meal.id!);
      if (remoteUrl != null) {
        await syncService.queueDeleteRemoteImage(remoteUrl);
        final deleted = await syncService.deleteRemoteImage(remoteUrl);
        if (deleted) {
          await syncService
              .completeQueuedOperation('remote_image_delete:$remoteUrl');
          await _clearRemotePrimaryImageUrl(meal.id!);
        }
      }
    }

    // Save to cache with pendingSync=true
    final mealToSave = meal.copyWith(
      updatedAt: DateTime.now(),
      pendingSync: true,
    );

    final saved = await _cache.saveMeal(mealToSave);
    _log('Meal saved to cache: id=${saved.id}, pendingSync=true');

    // Mark for sync
    final savedId = saved.id;
    if (_syncService != null && savedId != null) {
      await _syncService.markPendingSync(savedId);
      if (saved.hasImage && saved.imagePath != null) {
        await _syncService.queueUploadPrimaryMealImage(
            savedId, saved.imagePath!);
      }
    }

    // Try to sync immediately (non-blocking)
    if (_syncService != null) {
      _log('Attempting immediate sync...');
      _syncService
          .syncMeal(
        saved,
        meal.id == null ? OperationType.create : OperationType.update,
      )
          .then((success) {
        _log(
            'Immediate sync ${success ? "succeeded" : "failed (will retry later)"}');
      });
    }

    return saved;
  }

  @override
  Future<Meal?> getMealById(int id) => _cache.getMealById(id);

  @override
  Future<void> deleteMeal(int id) async {
    _log('deleteMeal: id=$id');

    // Get the meal first to know the server_id
    final meal = await _cache.getMealById(id);
    if (meal == null) return;

    // Delete from cache
    await _cache.deleteMeal(id);

    // If we have a server ID, try to delete from backend
    final syncService = _syncService;
    final serverId = meal.serverId;
    if (syncService != null && meal.id != null) {
      final primaryImageUrl = await _getRemotePrimaryImageUrl(meal.id!);
      if (primaryImageUrl != null) {
        await syncService.queueDeleteRemoteImage(primaryImageUrl);
        final deletedPrimary =
            await syncService.deleteRemoteImage(primaryImageUrl);
        if (deletedPrimary) {
          await syncService.completeQueuedOperation(
            'remote_image_delete:$primaryImageUrl',
          );
        }
      }

      final galleryImageUrls = await _getRemoteGalleryImageUrls(meal.id!);
      for (final imageUrl in galleryImageUrls) {
        await syncService.queueDeleteRemoteImage(imageUrl);
        final deletedImage = await syncService.deleteRemoteImage(imageUrl);
        if (deletedImage) {
          await syncService.completeQueuedOperation(
            'remote_image_delete:$imageUrl',
          );
        }
      }
    }

    if (syncService != null && serverId != null) {
      _log('Deleting from backend: serverId=${meal.serverId}');
      await syncService.queueDeleteMeal(serverId);
      final deleted = await syncService.deleteMeal(serverId);
      if (deleted) {
        await syncService.completeQueuedOperation(
          'meal_delete:${meal.serverId}',
        );
      }
    }
  }

  @override
  Stream<List<Meal>> watchTodayMeals() => _cache.watchTodayMeals();

  @override
  Future<List<Meal>> getMealsForDate(DateTime date) =>
      _cache.getMealsForDate(date);

  @override
  Future<bool> hasMealsForDate(DateTime date) => _cache.hasMealsForDate(date);

  @override
  Future<List<Meal>> getMealsBefore(DateTime date, {int limit = 20}) =>
      _cache.getMealsBefore(date, limit: limit);

  @override
  Future<List<Meal>> getMealsBeforeCursor(
    DateTime date, {
    int? id,
    int limit = 20,
  }) =>
      _cache.getMealsBeforeCursor(date, id: id, limit: limit);

  @override
  Future<List<Meal>> getMealsForMonth(int year, int month) =>
      _cache.getMealsForMonth(year, month);

  /// Force a full sync
  Future<void> sync() async {
    if (_syncService != null) {
      await _syncService.fullSync();
    }
  }
}
