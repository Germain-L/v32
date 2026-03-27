import '../models/daily_checkin.dart';
import 'daily_checkin_repository_interface.dart';

/// In-memory implementation of DailyCheckinRepository for unit testing.
/// Stores data in memory - fast but not persistent.
class MockDailyCheckinRepository implements DailyCheckinRepository {
  final Map<int, DailyCheckin> _dailyCheckins = {};
  int _nextId = 1;

  @override
  Future<DailyCheckin> saveDailyCheckin(DailyCheckin dailyCheckin) async {
    if (dailyCheckin.id == null) {
      final newDailyCheckin = dailyCheckin.copyWith(id: _nextId++);
      _dailyCheckins[newDailyCheckin.id!] = newDailyCheckin;
      return newDailyCheckin;
    } else {
      _dailyCheckins[dailyCheckin.id!] = dailyCheckin;
      return dailyCheckin;
    }
  }

  @override
  Future<DailyCheckin?> getDailyCheckinById(int id) async => _dailyCheckins[id];

  @override
  Future<DailyCheckin?> getDailyCheckinForDate(DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(Duration(days: 1));

    final checkins = _dailyCheckins.values
        .where(
          (c) =>
              c.date.isAfter(startOfDay.subtract(Duration(microseconds: 1))) &&
              c.date.isBefore(endOfDay),
        )
        .toList();

    if (checkins.isEmpty) return null;
    checkins.sort((a, b) => b.date.compareTo(a.date));
    return checkins.first;
  }

  @override
  Future<void> deleteDailyCheckin(int id) async {
    _dailyCheckins.remove(id);
  }

  @override
  Stream<List<DailyCheckin>> watchRecentDailyCheckins({int limit = 30}) async* {
    yield _dailyCheckins.values.take(limit).toList();
  }

  @override
  Future<List<DailyCheckin>> getDailyCheckinsForDateRange(
      DateTime start, DateTime end) async {
    return _dailyCheckins.values
        .where(
          (c) =>
              c.date.isAfter(start.subtract(Duration(microseconds: 1))) &&
              c.date.isBefore(end),
        )
        .toList();
  }

  @override
  Future<List<DailyCheckin>> getDailyCheckinsBefore(DateTime date,
      {int limit = 20}) async {
    return _dailyCheckins.values
        .where((c) => c.date.isBefore(date))
        .take(limit)
        .toList();
  }

  @override
  Future<List<DailyCheckin>> getPendingSyncDailyCheckins() async {
    return _dailyCheckins.values.where((c) => c.pendingSync).toList();
  }

  @override
  Future<void> updateServerId(int localId, int serverId) async {
    final checkin = _dailyCheckins[localId];
    if (checkin != null) {
      _dailyCheckins[localId] = checkin.copyWith(serverId: serverId, pendingSync: false);
    }
  }

  /// Clear all data (useful in tests)
  void clear() {
    _dailyCheckins.clear();
    _nextId = 1;
  }
}
