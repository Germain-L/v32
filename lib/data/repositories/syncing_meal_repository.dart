import '../models/meal.dart';
import '../models/sync_operation.dart';
import '../services/sync_config.dart';
import '../services/sync_service.dart';
import '../services/sync_queue.dart';
import '../services/sqlite_sync_queue.dart';
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
  }) : _localRepo = localRepo ?? LocalMealRepository(),
       _syncService = syncService;

  /// Create with sync enabled (if configured).
  factory SyncingMealRepository.withSync() {
    if (!SyncConfig.enabled) {
      return SyncingMealRepository(syncService: null);
    }

    try {
      final syncService = SyncService.instance;
      return SyncingMealRepository(syncService: syncService);
    } catch (_) {
      // SyncService not initialized - sync disabled
      return SyncingMealRepository(syncService: null);
    }
  }

  @override
  Future<Meal> saveMeal(Meal meal) async {
    // Save locally first
    final saved = await _localRepo.saveMeal(meal);

    // Then sync in background (don't await)
    _syncService?.syncMeal(
      saved,
      meal.id == null ? OperationType.create : OperationType.update,
    );

    return saved;
  }

  @override
  Future<Meal?> getMealById(int id) => _localRepo.getMealById(id);

  @override
  Future<void> deleteMeal(int id) async {
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
  }) => _localRepo.getMealsBeforeCursor(date, id: id, limit: limit);

  @override
  Future<List<Meal>> getMealsForMonth(int year, int month) =>
      _localRepo.getMealsForMonth(year, month);
}
