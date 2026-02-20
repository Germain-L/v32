import 'package:sqflite/sqflite.dart';
import '../models/daily_metrics.dart';
import '../services/database_service.dart';

class DailyMetricsRepository {
  Future<void> saveMetrics(DailyMetrics metrics) async {
    final normalized = DateTime(
      metrics.date.year,
      metrics.date.month,
      metrics.date.day,
    );
    final db = await DatabaseService.database;
    await db.insert(
      'daily_metrics',
      DailyMetrics(
        date: normalized,
        waterLiters: metrics.waterLiters,
        exerciseDone: metrics.exerciseDone,
        exerciseNote: metrics.exerciseNote,
      ).toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await DatabaseService.notifyChange(table: 'daily_metrics');
  }

  Future<DailyMetrics?> getMetricsForDate(DateTime date) async {
    final normalized = DateTime(date.year, date.month, date.day);
    final db = await DatabaseService.database;
    final maps = await db.query(
      'daily_metrics',
      where: 'date = ?',
      whereArgs: [normalized.millisecondsSinceEpoch],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return DailyMetrics.fromMap(maps.first);
  }

  Future<Map<String, DailyMetrics>> getMetricsForMonth(
    int year,
    int month,
  ) async {
    final db = await DatabaseService.database;
    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 1);
    final maps = await db.query(
      'daily_metrics',
      where: 'date >= ? AND date < ?',
      whereArgs: [start.millisecondsSinceEpoch, end.millisecondsSinceEpoch],
    );

    final map = <String, DailyMetrics>{};
    for (final entry in maps) {
      final metrics = DailyMetrics.fromMap(entry);
      map[_dateKey(metrics.date)] = metrics;
    }
    return map;
  }

  Future<Map<String, DailyMetrics>> getMetricsForRange(
    DateTime start,
    DateTime end,
  ) async {
    final db = await DatabaseService.database;
    final normalizedStart = DateTime(start.year, start.month, start.day);
    final normalizedEnd = DateTime(end.year, end.month, end.day, 23, 59, 59);
    final maps = await db.query(
      'daily_metrics',
      where: 'date >= ? AND date <= ?',
      whereArgs: [
        normalizedStart.millisecondsSinceEpoch,
        normalizedEnd.millisecondsSinceEpoch,
      ],
    );

    final map = <String, DailyMetrics>{};
    for (final entry in maps) {
      final metrics = DailyMetrics.fromMap(entry);
      map[_dateKey(metrics.date)] = metrics;
    }
    return map;
  }

  Future<void> deleteMetricsForDate(DateTime date) async {
    final normalized = DateTime(date.year, date.month, date.day);
    final db = await DatabaseService.database;
    await db.delete(
      'daily_metrics',
      where: 'date = ?',
      whereArgs: [normalized.millisecondsSinceEpoch],
    );
    await DatabaseService.notifyChange(table: 'daily_metrics');
  }

  String _dateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
