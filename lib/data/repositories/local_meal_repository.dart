import 'dart:async';
import '../models/meal.dart';
import '../models/meal_image.dart';
import '../services/database_service.dart';
import 'meal_image_repository.dart';
import 'meal_repository_interface.dart';

/// SQLite implementation of MealRepository.
/// Uses local database for storage.
class LocalMealRepository implements MealRepository {
  @override
  Future<Meal> saveMeal(Meal meal) async {
    final db = await DatabaseService.database;
    if (meal.id == null) {
      final id = await db.insert('meals', meal.toMap()..remove('id'));
      await DatabaseService.notifyChange(table: 'meals');
      return meal.copyWith(id: id);
    } else {
      await db.update(
        'meals',
        meal.toMap(),
        where: 'id = ?',
        whereArgs: [meal.id],
      );
    }
    await DatabaseService.notifyChange(table: 'meals');
    return meal;
  }

  // Batch insert - not part of interface but kept for internal use
  Future<void> saveMeals(List<Meal> meals) async {
    final db = await DatabaseService.database;
    final batch = db.batch();

    for (final meal in meals) {
      if (meal.id == null) {
        batch.insert('meals', meal.toMap()..remove('id'));
      } else {
        batch.update(
          'meals',
          meal.toMap(),
          where: 'id = ?',
          whereArgs: [meal.id],
        );
      }
    }

    await batch.commit(noResult: true);
    await DatabaseService.notifyChange(table: 'meals');
  }

  @override
  Future<Meal?> getMealById(int id) async {
    final db = await DatabaseService.database;
    final maps = await db.query('meals', where: 'id = ?', whereArgs: [id]);

    if (maps.isEmpty) return null;
    return Meal.fromMap(maps.first);
  }

  @override
  Future<void> deleteMeal(int id) async {
    final db = await DatabaseService.database;
    await db.delete('meals', where: 'id = ?', whereArgs: [id]);
    await DatabaseService.notifyChange(table: 'meals');
  }

  @override
  Stream<List<Meal>> watchTodayMeals() async* {
    Future<List<Meal>> loadForToday() async {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));
      return _getMealsForDateRange(startOfDay, endOfDay);
    }

    // Emit initial data
    yield await loadForToday();

    // Watch for changes
    await for (final _ in DatabaseService.watchTable('meals')) {
      yield await loadForToday();
    }
  }

  Future<List<Meal>> _getMealsForDateRange(DateTime start, DateTime end) async {
    final db = await DatabaseService.database;
    final maps = await db.query(
      'meals',
      where: 'date >= ? AND date < ?',
      whereArgs: [start.millisecondsSinceEpoch, end.millisecondsSinceEpoch],
      orderBy: 'date ASC',
    );

    return maps.map((map) => Meal.fromMap(map)).toList();
  }

  @override
  Future<List<Meal>> getMealsForDate(DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return _getMealsForDateRange(startOfDay, endOfDay);
  }

  // History with pagination - not part of interface but kept for internal use
  Future<List<Meal>> getMealsBefore(DateTime date, {int limit = 20}) async {
    final db = await DatabaseService.database;
    final maps = await db.query(
      'meals',
      where: 'date < ?',
      whereArgs: [date.millisecondsSinceEpoch],
      orderBy: 'date DESC, id DESC',
      limit: limit,
    );

    return maps.map((map) => Meal.fromMap(map)).toList();
  }

  Future<List<Meal>> getMealsBeforeCursor(
    DateTime date, {
    int? id,
    int limit = 20,
  }) async {
    final db = await DatabaseService.database;
    final dateMillis = date.millisecondsSinceEpoch;

    if (id == null) {
      final maps = await db.query(
        'meals',
        where: 'date < ?',
        whereArgs: [dateMillis],
        orderBy: 'date DESC, id DESC',
        limit: limit,
      );
      return maps.map((map) => Meal.fromMap(map)).toList();
    }

    final maps = await db.query(
      'meals',
      where: 'date < ? OR (date = ? AND id < ?)',
      whereArgs: [dateMillis, dateMillis, id],
      orderBy: 'date DESC, id DESC',
      limit: limit,
    );

    return maps.map((map) => Meal.fromMap(map)).toList();
  }

  // Calendar view - meals by month - not part of interface but kept for internal use
  Future<List<Meal>> getMealsForMonth(int year, int month) async {
    final db = await DatabaseService.database;
    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 1);

    final maps = await db.query(
      'meals',
      where: 'date >= ? AND date < ?',
      whereArgs: [start.millisecondsSinceEpoch, end.millisecondsSinceEpoch],
      orderBy: 'date DESC',
    );

    return maps.map((map) => Meal.fromMap(map)).toList();
  }

  @override
  Future<bool> hasMealsForDate(DateTime date) async {
    final db = await DatabaseService.database;
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM meals WHERE date >= ? AND date < ?',
      [startOfDay.millisecondsSinceEpoch, endOfDay.millisecondsSinceEpoch],
    );

    final count = (result.first['count'] as int?) ?? 0;
    return count > 0;
  }

  /// Get additional images for a meal
  Future<List<MealImage>> getAdditionalImagesForMeal(int mealId) async {
    if (mealId <= 0) return [];
    final imageRepo = MealImageRepository();
    return imageRepo.getImagesForMeal(mealId);
  }
}
