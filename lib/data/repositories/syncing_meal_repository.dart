import 'dart:developer' as dev;
import '../models/meal.dart';
import '../models/sync_operation.dart';
import '../services/sync_config.dart';
import '../services/sync_service.dart';
import 'local_meal_repository.dart';
import 'meal_repository_interface.dart';

/// A meal repository that syncs to the backend.
/// Wraps LocalMealRepository and adds sync functionality.
class SyncingMealRepository implements MealRepository {
  final LocalMealRepository _localRepo;
  final SyncService? _syncService;

  SyncingMealRepository({
    LocalMealRepository? localRepo,
    SyncService? syncService,
  })  : _localRepo = localRepo ?? LocalMealRepository(),
        _syncService = syncService;

  /// Create with sync enabled (if configured).
  factory SyncingMealRepository.withSync() {
    _log(
      'Creating SyncingMealRepository, sync enabled: ${SyncConfig.enabled && SyncConfig.hasCredentials}',
    );

    if (!SyncConfig.enabled || !SyncConfig.hasCredentials) {
      _log('Sync disabled by config');
      return SyncingMealRepository(syncService: null);
    }

    try {
      final syncService = SyncService.instance;
      _log('SyncService obtained successfully');
      return SyncingMealRepository(syncService: syncService);
    } catch (e) {
      _log('SyncService not initialized - sync disabled: $e');
      return SyncingMealRepository(syncService: null);
    }
  }

  static void _log(String message) {
    dev.log('[REPO] $message', name: 'v32');
  }

  @override
  Future<Meal> saveMeal(Meal meal) async {
    _log('saveMeal called: slot=${meal.slot.name}, id=${meal.id}');

    // Save locally first
    final saved = await _localRepo.saveMeal(meal);
    _log('Meal saved locally: id=${saved.id}');

    // Then sync in background (don't await)
    if (_syncService != null) {
      _log('Triggering sync...');
      _syncService.syncMeal(
        saved,
        meal.id == null ? OperationType.create : OperationType.update,
      );
    } else {
      _log('No sync service - skipping sync');
    }

    return saved;
  }

  @override
  Future<Meal?> getMealById(int id) => _localRepo.getMealById(id);

  @override
  Future<void> deleteMeal(int id) async {
    _log('deleteMeal called: id=$id');
    // Delete locally first
    await _localRepo.deleteMeal(id);

    // Queue delete operation for sync
    // Note: We'd need to fetch the meal first to have the payload
    // For now, we'll just skip syncing deletes (backend will handle it)
  }

  @override
  Stream<List<Meal>> watchTodayMeals() => _localRepo.watchTodayMeals();

  @override
  Future<List<Meal>> getMealsForDate(DateTime date) =>
      _localRepo.getMealsForDate(date);

  @override
  Future<bool> hasMealsForDate(DateTime date) =>
      _localRepo.hasMealsForDate(date);

  @override
  Future<List<Meal>> getMealsBefore(DateTime date, {int limit = 20}) =>
      _localRepo.getMealsBefore(date, limit: limit);

  @override
  Future<List<Meal>> getMealsBeforeCursor(
    DateTime date, {
    int? id,
    int limit = 20,
  }) =>
      _localRepo.getMealsBeforeCursor(date, id: id, limit: limit);

  @override
  Future<List<Meal>> getMealsForMonth(int year, int month) =>
      _localRepo.getMealsForMonth(year, month);
}
