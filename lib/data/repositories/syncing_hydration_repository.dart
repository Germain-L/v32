import 'dart:developer' as dev;
import '../models/hydration.dart';
import '../models/sync_operation.dart';
import '../services/sync_config.dart';
import '../services/sync_service.dart';
import 'local_hydration_repository.dart';
import 'hydration_repository_interface.dart';

/// A hydration repository that syncs to the backend.
/// Wraps LocalHydrationRepository and adds sync functionality.
class SyncingHydrationRepository implements HydrationRepository {
  final LocalHydrationRepository _localRepo;
  final SyncService? _syncService;

  SyncingHydrationRepository({
    LocalHydrationRepository? localRepo,
    SyncService? syncService,
  })  : _localRepo = localRepo ?? LocalHydrationRepository(),
        _syncService = syncService ?? _resolveSyncService();

  static SyncService? _resolveSyncService() {
    if (!SyncConfig.enabled ||
        !SyncConfig.hasCredentials ||
        !SyncService.isInitialized) {
      return null;
    }
    return SyncService.instance;
  }

  static void _log(String message) {
    dev.log('[SYNCING_HYDRATION_REPO] $message', name: 'v32');
  }

  @override
  Future<Hydration> saveHydration(Hydration hydration) async {
    _log('saveHydration called: date=${hydration.date}, id=${hydration.id}');

    final hydrationToSave = hydration.copyWith(pendingSync: true);
    final saved = await _localRepo.saveHydration(hydrationToSave);
    _log('Hydration saved locally: id=${saved.id}');

    final syncService = _syncService;
    if (syncService != null) {
      syncService
          .syncHydration(
        saved,
        hydration.id == null ? OperationType.create : OperationType.update,
      )
          .then((success) {
        _log(
          'Hydration sync ${success ? "succeeded" : "failed (will retry later)"}',
        );
      });
    }

    return saved;
  }

  @override
  Future<Hydration?> getHydrationById(int id) =>
      _localRepo.getHydrationById(id);

  @override
  Future<List<Hydration>> getHydrationsForDate(DateTime date) =>
      _localRepo.getHydrationsForDate(date);

  @override
  Future<void> deleteHydration(int id) async {
    _log('deleteHydration called: id=$id');
    final hydration = await _localRepo.getHydrationById(id);
    final syncService = _syncService;
    final serverId = hydration?.serverId;
    if (serverId != null && syncService != null) {
      await syncService.queueDeleteHydration(serverId);
      final deleted = await syncService.deleteHydration(serverId);
      if (deleted) {
        await syncService.completeQueuedOperation('hydration_delete:$serverId');
      }
    }
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
