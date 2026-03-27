import 'dart:developer' as dev;
import '../models/hydration.dart';
import 'local_hydration_repository.dart';
import 'hydration_repository_interface.dart';

/// A hydration repository that treats the backend as source of truth.
/// Local storage acts as a cache.
class RemoteHydrationRepository implements HydrationRepository {
  final LocalHydrationRepository _cache;

  RemoteHydrationRepository({
    LocalHydrationRepository? cache,
  }) : _cache = cache ?? LocalHydrationRepository();

  static void _log(String message) {
    dev.log('[REMOTE_HYDRATION_REPO] $message', name: 'v32');
  }

  @override
  Future<Hydration> saveHydration(Hydration hydration) async {
    _log('saveHydration: date=${hydration.date}, id=${hydration.id}');

    // Save to cache with pendingSync=true
    final hydrationToSave = hydration.copyWith(
      pendingSync: true,
    );

    final saved = await _cache.saveHydration(hydrationToSave);
    _log('Hydration saved to cache: id=${saved.id}, pendingSync=true');

    return saved;
  }

  @override
  Future<Hydration?> getHydrationById(int id) => _cache.getHydrationById(id);

  @override
  Future<List<Hydration>> getHydrationsForDate(DateTime date) =>
      _cache.getHydrationsForDate(date);

  @override
  Future<void> deleteHydration(int id) async {
    _log('deleteHydration: id=$id');
    await _cache.deleteHydration(id);
  }

  @override
  Stream<List<Hydration>> watchTodayHydrations() =>
      _cache.watchTodayHydrations();

  @override
  Future<List<Hydration>> getHydrationsForDateRange(
          DateTime start, DateTime end) =>
      _cache.getHydrationsForDateRange(start, end);

  @override
  Future<List<Hydration>> getHydrationsBefore(DateTime date,
          {int limit = 20}) =>
      _cache.getHydrationsBefore(date, limit: limit);

  @override
  Future<List<Hydration>> getPendingSyncHydrations() =>
      _cache.getPendingSyncHydrations();

  @override
  Future<void> updateServerId(int localId, int serverId) =>
      _cache.updateServerId(localId, serverId);

  @override
  Future<int> getTotalHydrationForDate(DateTime date) =>
      _cache.getTotalHydrationForDate(date);
}
