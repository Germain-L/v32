import '../models/screen_time.dart';
import 'screen_time_repository_interface.dart';

/// In-memory implementation of ScreenTimeRepository for unit testing.
/// Stores data in memory - fast but not persistent.
class MockScreenTimeRepository implements ScreenTimeRepository {
  final Map<int, ScreenTime> _screenTimes = {};
  final Map<int, List<ScreenTimeApp>> _screenTimeApps = {};
  int _nextId = 1;

  @override
  Future<ScreenTime> saveScreenTime(ScreenTime screenTime) async {
    if (screenTime.id == null) {
      final newScreenTime = screenTime.copyWith(id: _nextId++);
      _screenTimes[newScreenTime.id!] = newScreenTime;
      return newScreenTime;
    } else {
      _screenTimes[screenTime.id!] = screenTime;
      return screenTime;
    }
  }

  @override
  Future<ScreenTime?> getScreenTimeById(int id) async => _screenTimes[id];

  @override
  Future<ScreenTime?> getScreenTimeForDate(DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(Duration(days: 1));

    final screenTimes = _screenTimes.values
        .where(
          (s) =>
              s.date.isAfter(startOfDay.subtract(Duration(microseconds: 1))) &&
              s.date.isBefore(endOfDay),
        )
        .toList();

    if (screenTimes.isEmpty) return null;
    screenTimes.sort((a, b) => b.date.compareTo(a.date));
    return screenTimes.first;
  }

  @override
  Future<void> deleteScreenTime(int id) async {
    _screenTimes.remove(id);
    _screenTimeApps.remove(id);
  }

  @override
  Stream<List<ScreenTime>> watchRecentScreenTimes({int limit = 30}) async* {
    yield _screenTimes.values.take(limit).toList();
  }

  @override
  Future<List<ScreenTime>> getScreenTimesForDateRange(
      DateTime start, DateTime end) async {
    return _screenTimes.values
        .where(
          (s) =>
              s.date.isAfter(start.subtract(Duration(microseconds: 1))) &&
              s.date.isBefore(end),
        )
        .toList();
  }

  @override
  Future<List<ScreenTime>> getScreenTimesBefore(DateTime date,
      {int limit = 20}) async {
    return _screenTimes.values
        .where((s) => s.date.isBefore(date))
        .take(limit)
        .toList();
  }

  @override
  Future<List<ScreenTime>> getPendingSyncScreenTimes() async {
    return _screenTimes.values.where((s) => s.pendingSync).toList();
  }

  @override
  Future<void> updateServerId(int localId, int serverId) async {
    final screenTime = _screenTimes[localId];
    if (screenTime != null) {
      _screenTimes[localId] = screenTime.copyWith(serverId: serverId, pendingSync: false);
    }
  }

  @override
  Future<void> saveScreenTimeApps(
      int screenTimeId, List<ScreenTimeApp> apps) async {
    _screenTimeApps[screenTimeId] = apps;
  }

  @override
  Future<List<ScreenTimeApp>> getScreenTimeApps(int screenTimeId) async {
    return _screenTimeApps[screenTimeId] ?? [];
  }

  /// Clear all data (useful in tests)
  void clear() {
    _screenTimes.clear();
    _screenTimeApps.clear();
    _nextId = 1;
  }
}
