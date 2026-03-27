import 'dart:async';
import '../models/workout.dart';
import '../services/database_service.dart';
import 'workout_repository_interface.dart';

class LocalWorkoutRepository implements WorkoutRepository {
  @override
  Future<Workout> saveWorkout(Workout workout) async {
    final db = await DatabaseService.database;
    if (workout.id == null) {
      final id = await db.insert('workouts', workout.toMap()..remove('id'));
      await DatabaseService.notifyChange(table: 'workouts');
      return workout.copyWith(id: id);
    } else {
      await db.update(
        'workouts',
        workout.toMap(),
        where: 'id = ?',
        whereArgs: [workout.id],
      );
    }
    await DatabaseService.notifyChange(table: 'workouts');
    return workout;
  }

  Future<void> saveWorkouts(List<Workout> workouts) async {
    final db = await DatabaseService.database;
    final batch = db.batch();

    for (final workout in workouts) {
      if (workout.id == null) {
        batch.insert('workouts', workout.toMap()..remove('id'));
      } else {
        batch.update(
          'workouts',
          workout.toMap(),
          where: 'id = ?',
          whereArgs: [workout.id],
        );
      }
    }

    await batch.commit(noResult: true);
    await DatabaseService.notifyChange(table: 'workouts');
  }

  @override
  Future<Workout?> getWorkoutById(int id) async {
    final db = await DatabaseService.database;
    final maps = await db.query('workouts', where: 'id = ?', whereArgs: [id]);

    if (maps.isEmpty) return null;
    return Workout.fromMap(maps.first);
  }

  @override
  Future<void> deleteWorkout(int id) async {
    final db = await DatabaseService.database;
    await db.delete('workouts', where: 'id = ?', whereArgs: [id]);
    await DatabaseService.notifyChange(table: 'workouts');
  }

  @override
  Stream<List<Workout>> watchTodayWorkouts() async* {
    Future<List<Workout>> loadForToday() async {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));
      return _getWorkoutsForDateRange(startOfDay, endOfDay);
    }

    yield await loadForToday();

    await for (final _ in DatabaseService.watchTable('workouts')) {
      yield await loadForToday();
    }
  }

  Future<List<Workout>> _getWorkoutsForDateRange(
      DateTime start, DateTime end) async {
    final db = await DatabaseService.database;
    final maps = await db.query(
      'workouts',
      where: 'date >= ? AND date < ?',
      whereArgs: [start.millisecondsSinceEpoch, end.millisecondsSinceEpoch],
      orderBy: 'date ASC',
    );

    return maps.map((map) => Workout.fromMap(map)).toList();
  }

  @override
  Future<List<Workout>> getWorkoutsForDate(DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return _getWorkoutsForDateRange(startOfDay, endOfDay);
  }

  @override
  Future<List<Workout>> getWorkoutsBefore(DateTime date,
      {int limit = 20}) async {
    final db = await DatabaseService.database;
    final maps = await db.query(
      'workouts',
      where: 'date < ?',
      whereArgs: [date.millisecondsSinceEpoch],
      orderBy: 'date DESC, id DESC',
      limit: limit,
    );

    return maps.map((map) => Workout.fromMap(map)).toList();
  }

  @override
  Future<List<Workout>> getWorkoutsBeforeCursor(
    DateTime date, {
    int? id,
    int limit = 20,
  }) async {
    final db = await DatabaseService.database;
    final dateMillis = date.millisecondsSinceEpoch;

    if (id == null) {
      final maps = await db.query(
        'workouts',
        where: 'date < ?',
        whereArgs: [dateMillis],
        orderBy: 'date DESC, id DESC',
        limit: limit,
      );
      return maps.map((map) => Workout.fromMap(map)).toList();
    }

    final maps = await db.query(
      'workouts',
      where: 'date < ? OR (date = ? AND id < ?)',
      whereArgs: [dateMillis, dateMillis, id],
      orderBy: 'date DESC, id DESC',
      limit: limit,
    );

    return maps.map((map) => Workout.fromMap(map)).toList();
  }

  @override
  Future<List<Workout>> getWorkoutsForMonth(int year, int month) async {
    final db = await DatabaseService.database;
    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 1);

    final maps = await db.query(
      'workouts',
      where: 'date >= ? AND date < ?',
      whereArgs: [start.millisecondsSinceEpoch, end.millisecondsSinceEpoch],
      orderBy: 'date DESC',
    );

    return maps.map((map) => Workout.fromMap(map)).toList();
  }

  @override
  Future<bool> hasWorkoutsForDate(DateTime date) async {
    final db = await DatabaseService.database;
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM workouts WHERE date >= ? AND date < ?',
      [startOfDay.millisecondsSinceEpoch, endOfDay.millisecondsSinceEpoch],
    );

    final count = (result.first['count'] as int?) ?? 0;
    return count > 0;
  }

  @override
  Future<List<Workout>> getPendingSyncWorkouts() async {
    final db = await DatabaseService.database;
    final maps = await db.query(
      'workouts',
      where: 'pending_sync = ?',
      whereArgs: [1],
      orderBy: 'updated_at ASC',
    );

    return maps.map((map) => Workout.fromMap(map)).toList();
  }

  @override
  Future<void> updateServerId(int localId, int serverId) async {
    final db = await DatabaseService.database;
    await db.update(
      'workouts',
      {'server_id': serverId, 'pending_sync': 0},
      where: 'id = ?',
      whereArgs: [localId],
    );
    await DatabaseService.notifyChange(table: 'workouts');
  }
}
