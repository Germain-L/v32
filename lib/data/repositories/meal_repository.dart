import 'dart:async';
import '../models/meal.dart';
import '../services/database_service.dart';

class MealRepository {
  // Create or update
  Future<Meal> saveMeal(Meal meal) async {
    final db = await DatabaseService.database;
    if (meal.id == null) {
      final id = await db.insert('meals', meal.toMap()..remove('id'));
      await DatabaseService.notifyChange();
      return meal.copyWith(id: id);
    } else {
      await db.update(
        'meals',
        meal.toMap(),
        where: 'id = ?',
        whereArgs: [meal.id],
      );
    }
    await DatabaseService.notifyChange();
    return meal;
  }

  // Batch insert
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
    await DatabaseService.notifyChange();
  }

  // Get by ID
  Future<Meal?> getMealById(int id) async {
    final db = await DatabaseService.database;
    final maps = await db.query('meals', where: 'id = ?', whereArgs: [id]);

    if (maps.isEmpty) return null;
    return Meal.fromMap(maps.first);
  }

  // Delete
  Future<void> deleteMeal(int id) async {
    final db = await DatabaseService.database;
    await db.delete('meals', where: 'id = ?', whereArgs: [id]);
    await DatabaseService.notifyChange();
  }

  // Today's meals
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
    await for (final _ in DatabaseService.dbChanges) {
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

  // Get meals for specific date
  Future<List<Meal>> getMealsForDate(DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return _getMealsForDateRange(startOfDay, endOfDay);
  }

  // History with pagination
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

  // Calendar view - meals by month
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

  // Check if date has any meals
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
}
