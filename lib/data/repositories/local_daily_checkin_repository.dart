import 'dart:async';
import '../models/daily_checkin.dart';
import '../services/database_service.dart';
import 'daily_checkin_repository_interface.dart';

class LocalDailyCheckinRepository implements DailyCheckinRepository {
  @override
  Future<DailyCheckin> saveDailyCheckin(DailyCheckin dailyCheckin) async {
    final db = await DatabaseService.database;
    if (dailyCheckin.id == null) {
      final id =
          await db.insert('daily_checkins', dailyCheckin.toMap()..remove('id'));
      await DatabaseService.notifyChange(table: 'daily_checkins');
      return dailyCheckin.copyWith(id: id);
    } else {
      await db.update(
        'daily_checkins',
        dailyCheckin.toMap(),
        where: 'id = ?',
        whereArgs: [dailyCheckin.id],
      );
    }
    await DatabaseService.notifyChange(table: 'daily_checkins');
    return dailyCheckin;
  }

  Future<void> saveDailyCheckins(List<DailyCheckin> dailyCheckins) async {
    final db = await DatabaseService.database;
    final batch = db.batch();

    for (final dailyCheckin in dailyCheckins) {
      if (dailyCheckin.id == null) {
        batch.insert('daily_checkins', dailyCheckin.toMap()..remove('id'));
      } else {
        batch.update(
          'daily_checkins',
          dailyCheckin.toMap(),
          where: 'id = ?',
          whereArgs: [dailyCheckin.id],
        );
      }
    }

    await batch.commit(noResult: true);
    await DatabaseService.notifyChange(table: 'daily_checkins');
  }

  @override
  Future<DailyCheckin?> getDailyCheckinById(int id) async {
    final db = await DatabaseService.database;
    final maps =
        await db.query('daily_checkins', where: 'id = ?', whereArgs: [id]);

    if (maps.isEmpty) return null;
    return DailyCheckin.fromMap(maps.first);
  }

  @override
  Future<DailyCheckin?> getDailyCheckinForDate(DateTime date) async {
    final db = await DatabaseService.database;
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final maps = await db.query(
      'daily_checkins',
      where: 'date >= ? AND date < ?',
      whereArgs: [
        startOfDay.millisecondsSinceEpoch,
        endOfDay.millisecondsSinceEpoch
      ],
      orderBy: 'date DESC',
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return DailyCheckin.fromMap(maps.first);
  }

  @override
  Future<void> deleteDailyCheckin(int id) async {
    final db = await DatabaseService.database;
    await db.delete('daily_checkins', where: 'id = ?', whereArgs: [id]);
    await DatabaseService.notifyChange(table: 'daily_checkins');
  }

  @override
  Stream<List<DailyCheckin>> watchRecentDailyCheckins({int limit = 30}) async* {
    Future<List<DailyCheckin>> load() async {
      final db = await DatabaseService.database;
      final maps = await db.query(
        'daily_checkins',
        orderBy: 'date DESC',
        limit: limit,
      );
      return maps.map((map) => DailyCheckin.fromMap(map)).toList();
    }

    yield await load();

    await for (final _ in DatabaseService.watchTable('daily_checkins')) {
      yield await load();
    }
  }

  @override
  Future<List<DailyCheckin>> getDailyCheckinsForDateRange(
      DateTime start, DateTime end) async {
    final db = await DatabaseService.database;
    final maps = await db.query(
      'daily_checkins',
      where: 'date >= ? AND date < ?',
      whereArgs: [start.millisecondsSinceEpoch, end.millisecondsSinceEpoch],
      orderBy: 'date ASC',
    );

    return maps.map((map) => DailyCheckin.fromMap(map)).toList();
  }

  @override
  Future<List<DailyCheckin>> getDailyCheckinsBefore(DateTime date,
      {int limit = 20}) async {
    final db = await DatabaseService.database;
    final maps = await db.query(
      'daily_checkins',
      where: 'date < ?',
      whereArgs: [date.millisecondsSinceEpoch],
      orderBy: 'date DESC',
      limit: limit,
    );

    return maps.map((map) => DailyCheckin.fromMap(map)).toList();
  }

  @override
  Future<List<DailyCheckin>> getPendingSyncDailyCheckins() async {
    final db = await DatabaseService.database;
    final maps = await db.query(
      'daily_checkins',
      where: 'pending_sync = ?',
      whereArgs: [1],
      orderBy: 'updated_at ASC',
    );

    return maps.map((map) => DailyCheckin.fromMap(map)).toList();
  }

  @override
  Future<void> updateServerId(int localId, int serverId) async {
    final db = await DatabaseService.database;
    await db.update(
      'daily_checkins',
      {'server_id': serverId, 'pending_sync': 0},
      where: 'id = ?',
      whereArgs: [localId],
    );
    await DatabaseService.notifyChange(table: 'daily_checkins');
  }
}
