import 'dart:async';
import '../models/hydration.dart';
import '../services/database_service.dart';
import 'hydration_repository_interface.dart';

class LocalHydrationRepository implements HydrationRepository {
  @override
  Future<Hydration> saveHydration(Hydration hydration) async {
    final db = await DatabaseService.database;
    if (hydration.id == null) {
      final id = await db.insert('hydrations', hydration.toMap()..remove('id'));
      await DatabaseService.notifyChange(table: 'hydrations');
      return hydration.copyWith(id: id);
    } else {
      await db.update(
        'hydrations',
        hydration.toMap(),
        where: 'id = ?',
        whereArgs: [hydration.id],
      );
    }
    await DatabaseService.notifyChange(table: 'hydrations');
    return hydration;
  }

  Future<void> saveHydrations(List<Hydration> hydrations) async {
    final db = await DatabaseService.database;
    final batch = db.batch();

    for (final hydration in hydrations) {
      if (hydration.id == null) {
        batch.insert('hydrations', hydration.toMap()..remove('id'));
      } else {
        batch.update(
          'hydrations',
          hydration.toMap(),
          where: 'id = ?',
          whereArgs: [hydration.id],
        );
      }
    }

    await batch.commit(noResult: true);
    await DatabaseService.notifyChange(table: 'hydrations');
  }

  @override
  Future<Hydration?> getHydrationById(int id) async {
    final db = await DatabaseService.database;
    final maps =
        await db.query('hydrations', where: 'id = ?', whereArgs: [id]);

    if (maps.isEmpty) return null;
    return Hydration.fromMap(maps.first);
  }

  @override
  Future<List<Hydration>> getHydrationsForDate(DateTime date) async {
    final db = await DatabaseService.database;
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final maps = await db.query(
      'hydrations',
      where: 'date >= ? AND date < ?',
      whereArgs: [
        startOfDay.millisecondsSinceEpoch,
        endOfDay.millisecondsSinceEpoch
      ],
      orderBy: 'date ASC',
    );

    return maps.map((map) => Hydration.fromMap(map)).toList();
  }

  @override
  Future<void> deleteHydration(int id) async {
    final db = await DatabaseService.database;
    await db.delete('hydrations', where: 'id = ?', whereArgs: [id]);
    await DatabaseService.notifyChange(table: 'hydrations');
  }

  @override
  Stream<List<Hydration>> watchTodayHydrations() async* {
    Future<List<Hydration>> loadForToday() async {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final db = await DatabaseService.database;
      final maps = await db.query(
        'hydrations',
        where: 'date >= ? AND date < ?',
        whereArgs: [
          startOfDay.millisecondsSinceEpoch,
          endOfDay.millisecondsSinceEpoch
        ],
        orderBy: 'date ASC',
      );

      return maps.map((map) => Hydration.fromMap(map)).toList();
    }

    yield await loadForToday();

    await for (final _ in DatabaseService.watchTable('hydrations')) {
      yield await loadForToday();
    }
  }

  @override
  Future<List<Hydration>> getHydrationsForDateRange(
      DateTime start, DateTime end) async {
    final db = await DatabaseService.database;
    final maps = await db.query(
      'hydrations',
      where: 'date >= ? AND date < ?',
      whereArgs: [start.millisecondsSinceEpoch, end.millisecondsSinceEpoch],
      orderBy: 'date ASC',
    );

    return maps.map((map) => Hydration.fromMap(map)).toList();
  }

  @override
  Future<List<Hydration>> getHydrationsBefore(DateTime date,
      {int limit = 20}) async {
    final db = await DatabaseService.database;
    final maps = await db.query(
      'hydrations',
      where: 'date < ?',
      whereArgs: [date.millisecondsSinceEpoch],
      orderBy: 'date DESC',
      limit: limit,
    );

    return maps.map((map) => Hydration.fromMap(map)).toList();
  }

  @override
  Future<List<Hydration>> getPendingSyncHydrations() async {
    final db = await DatabaseService.database;
    final maps = await db.query(
      'hydrations',
      where: 'pending_sync = ?',
      whereArgs: [1],
      orderBy: 'created_at ASC',
    );

    return maps.map((map) => Hydration.fromMap(map)).toList();
  }

  @override
  Future<void> updateServerId(int localId, int serverId) async {
    final db = await DatabaseService.database;
    await db.update(
      'hydrations',
      {'server_id': serverId, 'pending_sync': 0},
      where: 'id = ?',
      whereArgs: [localId],
    );
    await DatabaseService.notifyChange(table: 'hydrations');
  }

  @override
  Future<int> getTotalHydrationForDate(DateTime date) async {
    final hydrations = await getHydrationsForDate(date);
    return hydrations.fold<int>(0, (sum, h) => sum + h.amountMl);
  }
}
