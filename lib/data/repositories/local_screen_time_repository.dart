import 'dart:async';
import '../models/screen_time.dart';
import '../services/database_service.dart';
import 'screen_time_repository_interface.dart';

class LocalScreenTimeRepository implements ScreenTimeRepository {
  @override
  Future<ScreenTime> saveScreenTime(ScreenTime screenTime) async {
    final db = await DatabaseService.database;
    if (screenTime.id == null) {
      final id =
          await db.insert('screen_times', screenTime.toMap()..remove('id'));
      await DatabaseService.notifyChange(table: 'screen_times');
      return screenTime.copyWith(id: id);
    } else {
      await db.update(
        'screen_times',
        screenTime.toMap(),
        where: 'id = ?',
        whereArgs: [screenTime.id],
      );
    }
    await DatabaseService.notifyChange(table: 'screen_times');
    return screenTime;
  }

  Future<void> saveScreenTimes(List<ScreenTime> screenTimes) async {
    final db = await DatabaseService.database;
    final batch = db.batch();

    for (final screenTime in screenTimes) {
      if (screenTime.id == null) {
        batch.insert('screen_times', screenTime.toMap()..remove('id'));
      } else {
        batch.update(
          'screen_times',
          screenTime.toMap(),
          where: 'id = ?',
          whereArgs: [screenTime.id],
        );
      }
    }

    await batch.commit(noResult: true);
    await DatabaseService.notifyChange(table: 'screen_times');
  }

  @override
  Future<ScreenTime?> getScreenTimeById(int id) async {
    final db = await DatabaseService.database;
    final maps =
        await db.query('screen_times', where: 'id = ?', whereArgs: [id]);

    if (maps.isEmpty) return null;
    return ScreenTime.fromMap(maps.first);
  }

  @override
  Future<ScreenTime?> getScreenTimeForDate(DateTime date) async {
    final db = await DatabaseService.database;
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final maps = await db.query(
      'screen_times',
      where: 'date >= ? AND date < ?',
      whereArgs: [
        startOfDay.millisecondsSinceEpoch,
        endOfDay.millisecondsSinceEpoch
      ],
      orderBy: 'date DESC',
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return ScreenTime.fromMap(maps.first);
  }

  @override
  Future<void> deleteScreenTime(int id) async {
    final db = await DatabaseService.database;
    await db.delete('screen_times', where: 'id = ?', whereArgs: [id]);
    await DatabaseService.notifyChange(table: 'screen_times');
  }

  @override
  Stream<List<ScreenTime>> watchRecentScreenTimes({int limit = 30}) async* {
    Future<List<ScreenTime>> load() async {
      final db = await DatabaseService.database;
      final maps = await db.query(
        'screen_times',
        orderBy: 'date DESC',
        limit: limit,
      );
      return maps.map((map) => ScreenTime.fromMap(map)).toList();
    }

    yield await load();

    await for (final _ in DatabaseService.watchTable('screen_times')) {
      yield await load();
    }
  }

  @override
  Future<List<ScreenTime>> getScreenTimesForDateRange(
      DateTime start, DateTime end) async {
    final db = await DatabaseService.database;
    final maps = await db.query(
      'screen_times',
      where: 'date >= ? AND date < ?',
      whereArgs: [start.millisecondsSinceEpoch, end.millisecondsSinceEpoch],
      orderBy: 'date ASC',
    );

    return maps.map((map) => ScreenTime.fromMap(map)).toList();
  }

  @override
  Future<List<ScreenTime>> getScreenTimesBefore(DateTime date,
      {int limit = 20}) async {
    final db = await DatabaseService.database;
    final maps = await db.query(
      'screen_times',
      where: 'date < ?',
      whereArgs: [date.millisecondsSinceEpoch],
      orderBy: 'date DESC',
      limit: limit,
    );

    return maps.map((map) => ScreenTime.fromMap(map)).toList();
  }

  @override
  Future<List<ScreenTime>> getPendingSyncScreenTimes() async {
    final db = await DatabaseService.database;
    final maps = await db.query(
      'screen_times',
      where: 'pending_sync = ?',
      whereArgs: [1],
      orderBy: 'created_at ASC',
    );

    return maps.map((map) => ScreenTime.fromMap(map)).toList();
  }

  @override
  Future<void> updateServerId(int localId, int serverId) async {
    final db = await DatabaseService.database;
    await db.update(
      'screen_times',
      {'server_id': serverId, 'pending_sync': 0},
      where: 'id = ?',
      whereArgs: [localId],
    );
    await DatabaseService.notifyChange(table: 'screen_times');
  }

  @override
  Future<void> saveScreenTimeApps(
      int screenTimeId, List<ScreenTimeApp> apps) async {
    final db = await DatabaseService.database;

    // Delete existing apps for this screen time
    await db.delete(
      'screen_time_apps',
      where: 'screen_time_id = ?',
      whereArgs: [screenTimeId],
    );

    // Insert new apps
    final batch = db.batch();
    for (final app in apps) {
      batch.insert(
        'screen_time_apps',
        app.copyWith(screenTimeId: screenTimeId).toMap()..remove('id'),
      );
    }
    await batch.commit(noResult: true);
  }

  @override
  Future<List<ScreenTimeApp>> getScreenTimeApps(int screenTimeId) async {
    final db = await DatabaseService.database;
    final maps = await db.query(
      'screen_time_apps',
      where: 'screen_time_id = ?',
      whereArgs: [screenTimeId],
      orderBy: 'duration_ms DESC',
    );

    return maps.map((map) => ScreenTimeApp.fromMap(map)).toList();
  }
}
