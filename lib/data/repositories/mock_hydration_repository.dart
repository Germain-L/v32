import '../models/hydration.dart';
import 'hydration_repository_interface.dart';

/// In-memory implementation of HydrationRepository for unit testing.
/// Stores data in memory - fast but not persistent.
class MockHydrationRepository implements HydrationRepository {
  final Map<int, Hydration> _hydrations = {};
  int _nextId = 1;

  @override
  Future<Hydration> saveHydration(Hydration hydration) async {
    if (hydration.id == null) {
      final newHydration = hydration.copyWith(id: _nextId++);
      _hydrations[newHydration.id!] = newHydration;
      return newHydration;
    } else {
      _hydrations[hydration.id!] = hydration;
      return hydration;
    }
  }

  @override
  Future<Hydration?> getHydrationById(int id) async => _hydrations[id];

  @override
  Future<List<Hydration>> getHydrationsForDate(DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(Duration(days: 1));

    return _hydrations.values
        .where(
          (h) =>
              h.date.isAfter(startOfDay.subtract(Duration(microseconds: 1))) &&
              h.date.isBefore(endOfDay),
        )
        .toList();
  }

  @override
  Future<void> deleteHydration(int id) async {
    _hydrations.remove(id);
  }

  @override
  Stream<List<Hydration>> watchTodayHydrations() async* {
    yield await getHydrationsForDate(DateTime.now());
  }

  @override
  Future<List<Hydration>> getHydrationsForDateRange(
      DateTime start, DateTime end) async {
    return _hydrations.values
        .where(
          (h) =>
              h.date.isAfter(start.subtract(Duration(microseconds: 1))) &&
              h.date.isBefore(end),
        )
        .toList();
  }

  @override
  Future<List<Hydration>> getHydrationsBefore(DateTime date,
      {int limit = 20}) async {
    return _hydrations.values
        .where((h) => h.date.isBefore(date))
        .take(limit)
        .toList();
  }

  @override
  Future<List<Hydration>> getPendingSyncHydrations() async {
    return _hydrations.values.where((h) => h.pendingSync).toList();
  }

  @override
  Future<void> updateServerId(int localId, int serverId) async {
    final hydration = _hydrations[localId];
    if (hydration != null) {
      _hydrations[localId] = hydration.copyWith(serverId: serverId, pendingSync: false);
    }
  }

  @override
  Future<int> getTotalHydrationForDate(DateTime date) async {
    final hydrations = await getHydrationsForDate(date);
    return hydrations.fold<int>(0, (sum, h) => sum + h.amountMl);
  }

  /// Clear all data (useful in tests)
  void clear() {
    _hydrations.clear();
    _nextId = 1;
  }
}
