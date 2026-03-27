import 'dart:developer' as dev;
import '../models/hydration.dart';
import 'local_hydration_repository.dart';
import 'hydration_repository_interface.dart';

/// A hydration repository that syncs to the backend.
/// Wraps LocalHydrationRepository and adds sync functionality.
class SyncingHydrationRepository implements HydrationRepository {
  final LocalHydrationRepository _localRepo;

  SyncingHydrationRepository({
    LocalHydrationRepository? localRepo,
  }) : _localRepo = localRepo ?? LocalHydrationRepository();

  static void _log(String message) {
    dev.log('[SYNCING_HYDRATION_REPO] $message', name: 'v32');
  }

  @override
  Future<Hydration> saveHydration(Hydration hydration) async {
    _log('saveHydration called: date=${hydration.date}, id=${hydration.id}');

    // Save locally first
    final saved = await _localRepo.saveHydration(hydration);
    _log('Hydration saved locally: id=${saved.id}');

    // TODO: Trigger sync when backend endpoints are available

    return saved;
  }

  @override
  Future<Hydration?> getHydrationById(int id) => _localRepo.getHydrationById(id);

  @override
  Future<List<Hydration>> getHydrationsForDate(DateTime date) =>
      _localRepo.getHydrationsForDate(date);

  @override
  Future<void> deleteHydration(int id) async {
    _log('deleteHydration called: id=$id');
    await _localRepo.deleteHydration(id);
  }

  @override
  Stream<List<Hydration>> watchTodayHydrations() =>
      _localRepo.watchTodayHydrations();

  @override
  Future<List<Hydration>> getHydrationsForDateRange(
          DateTime start, DateTime end) =>
      _localRepo.getHydrationsForDateRange(start, end);

  @override
  Future<List<Hydration>> getHydrationsBefore(DateTime date,
          {int limit = 20}) =>
      _localRepo.getHydrationsBefore(date, limit: limit);

  @override
  Future<List<Hydration>> getPendingSyncHydrations() =>
      _localRepo.getPendingSyncHydrations();

  @override
  Future<void> updateServerId(int localId, int serverId) =>
      _localRepo.updateServerId(localId, serverId);

  @override
  Future<int> getTotalHydrationForDate(DateTime date) =>
      _localRepo.getTotalHydrationForDate(date);
}
