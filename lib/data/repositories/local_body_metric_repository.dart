import 'dart:async';
import '../models/body_metric.dart';
import '../services/database_service.dart';
import 'body_metric_repository_interface.dart';

class LocalBodyMetricRepository implements BodyMetricRepository {
  @override
  Future<BodyMetric> saveBodyMetric(BodyMetric bodyMetric) async {
    final db = await DatabaseService.database;
    if (bodyMetric.id == null) {
      final id = await db.insert('body_metrics', bodyMetric.toMap()..remove('id'));
      await DatabaseService.notifyChange(table: 'body_metrics');
      return bodyMetric.copyWith(id: id);
    } else {
      await db.update(
        'body_metrics',
        bodyMetric.toMap(),
        where: 'id = ?',
        whereArgs: [bodyMetric.id],
      );
    }
    await DatabaseService.notifyChange(table: 'body_metrics');
    return bodyMetric;
  }

  Future<void> saveBodyMetrics(List<BodyMetric> bodyMetrics) async {
    final db = await DatabaseService.database;
    final batch = db.batch();

    for (final bodyMetric in bodyMetrics) {
      if (bodyMetric.id == null) {
        batch.insert('body_metrics', bodyMetric.toMap()..remove('id'));
      } else {
        batch.update(
          'body_metrics',
          bodyMetric.toMap(),
          where: 'id = ?',
          whereArgs: [bodyMetric.id],
        );
      }
    }

    await batch.commit(noResult: true);
    await DatabaseService.notifyChange(table: 'body_metrics');
  }

  @override
  Future<BodyMetric?> getBodyMetricById(int id) async {
    final db = await DatabaseService.database;
    final maps =
        await db.query('body_metrics', where: 'id = ?', whereArgs: [id]);

    if (maps.isEmpty) return null;
    return BodyMetric.fromMap(maps.first);
  }

  @override
  Future<BodyMetric?> getBodyMetricForDate(DateTime date) async {
    final db = await DatabaseService.database;
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final maps = await db.query(
      'body_metrics',
      where: 'date >= ? AND date < ?',
      whereArgs: [startOfDay.millisecondsSinceEpoch, endOfDay.millisecondsSinceEpoch],
      orderBy: 'date DESC',
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return BodyMetric.fromMap(maps.first);
  }

  @override
  Future<void> deleteBodyMetric(int id) async {
    final db = await DatabaseService.database;
    await db.delete('body_metrics', where: 'id = ?', whereArgs: [id]);
    await DatabaseService.notifyChange(table: 'body_metrics');
  }

  @override
  Stream<List<BodyMetric>> watchRecentBodyMetrics({int limit = 30}) async* {
    Future<List<BodyMetric>> load() async {
      final db = await DatabaseService.database;
      final maps = await db.query(
        'body_metrics',
        orderBy: 'date DESC',
        limit: limit,
      );
      return maps.map((map) => BodyMetric.fromMap(map)).toList();
    }

    yield await load();

    await for (final _ in DatabaseService.watchTable('body_metrics')) {
      yield await load();
    }
  }

  @override
  Future<List<BodyMetric>> getBodyMetricsForDateRange(
      DateTime start, DateTime end) async {
    final db = await DatabaseService.database;
    final maps = await db.query(
      'body_metrics',
      where: 'date >= ? AND date < ?',
      whereArgs: [start.millisecondsSinceEpoch, end.millisecondsSinceEpoch],
      orderBy: 'date ASC',
    );

    return maps.map((map) => BodyMetric.fromMap(map)).toList();
  }

  @override
  Future<List<BodyMetric>> getBodyMetricsBefore(DateTime date,
      {int limit = 20}) async {
    final db = await DatabaseService.database;
    final maps = await db.query(
      'body_metrics',
      where: 'date < ?',
      whereArgs: [date.millisecondsSinceEpoch],
      orderBy: 'date DESC',
      limit: limit,
    );

    return maps.map((map) => BodyMetric.fromMap(map)).toList();
  }

  @override
  Future<List<BodyMetric>> getPendingSyncBodyMetrics() async {
    final db = await DatabaseService.database;
    final maps = await db.query(
      'body_metrics',
      where: 'pending_sync = ?',
      whereArgs: [1],
      orderBy: 'updated_at ASC',
    );

    return maps.map((map) => BodyMetric.fromMap(map)).toList();
  }

  @override
  Future<void> updateServerId(int localId, int serverId) async {
    final db = await DatabaseService.database;
    await db.update(
      'body_metrics',
      {'server_id': serverId, 'pending_sync': 0},
      where: 'id = ?',
      whereArgs: [localId],
    );
    await DatabaseService.notifyChange(table: 'body_metrics');
  }
}
