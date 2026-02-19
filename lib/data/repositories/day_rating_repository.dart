import 'package:sqflite/sqflite.dart';
import '../models/day_rating.dart';
import '../services/database_service.dart';

class DayRatingRepository {
  Future<void> saveRating(DateTime date, int score) async {
    final normalized = DateTime(date.year, date.month, date.day);
    final db = await DatabaseService.database;
    await db.insert(
      'day_ratings',
      DayRating(date: normalized, score: score).toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await DatabaseService.notifyChange();
  }

  Future<int?> getRatingForDate(DateTime date) async {
    final normalized = DateTime(date.year, date.month, date.day);
    final db = await DatabaseService.database;
    final maps = await db.query(
      'day_ratings',
      where: 'date = ?',
      whereArgs: [normalized.millisecondsSinceEpoch],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return maps.first['score'] as int?;
  }

  Future<Map<String, int>> getRatingsForMonth(int year, int month) async {
    final db = await DatabaseService.database;
    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 1);
    final maps = await db.query(
      'day_ratings',
      where: 'date >= ? AND date < ?',
      whereArgs: [start.millisecondsSinceEpoch, end.millisecondsSinceEpoch],
    );

    final map = <String, int>{};
    for (final entry in maps) {
      final dateMillis = entry['date'] as int;
      final score = entry['score'] as int;
      final date = DateTime.fromMillisecondsSinceEpoch(dateMillis);
      final key = _dateKey(date);
      map[key] = score;
    }
    return map;
  }

  String _dateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
