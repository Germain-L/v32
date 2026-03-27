import 'dart:developer' as dev;

import '../models/screen_time.dart';
import '../models/sync_operation.dart';
import '../services/screen_time_settings_service.dart';
import '../services/sync_config.dart';
import '../services/sync_service.dart';
import 'local_screen_time_repository.dart';
import 'screen_time_repository_interface.dart';

/// A screen time repository that syncs to the backend.
/// Wraps LocalScreenTimeRepository and adds sync functionality.
class SyncingScreenTimeRepository implements ScreenTimeRepository {
  final LocalScreenTimeRepository _localRepo;
  final ScreenTimeSettingsService _settingsService;
  final SyncService? _syncService;

  SyncingScreenTimeRepository({
    LocalScreenTimeRepository? localRepo,
    ScreenTimeSettingsService? settingsService,
    SyncService? syncService,
  })  : _localRepo = localRepo ?? LocalScreenTimeRepository(),
        _settingsService = settingsService ?? ScreenTimeSettingsService(),
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
    dev.log('[SYNCING_SCREEN_TIME_REPO] $message', name: 'v32');
  }

  @override
  Future<ScreenTime> saveScreenTime(ScreenTime screenTime) async {
    _log('saveScreenTime called: date=${screenTime.date}, id=${screenTime.id}');

    final screenTimeToSave = screenTime.copyWith(pendingSync: true);
    final saved = await _localRepo.saveScreenTime(screenTimeToSave);
    _log('ScreenTime saved locally: id=${saved.id}');

    final syncService = _syncService;
    if (syncService != null) {
      syncService
          .syncScreenTime(
        saved,
        screenTime.id == null ? OperationType.create : OperationType.update,
      )
          .then((success) {
        _log(
          'ScreenTime sync ${success ? "succeeded" : "failed (will retry later)"}',
        );
      });
    }

    return saved;
  }

  @override
  Future<ScreenTime?> getScreenTimeById(int id) =>
      _localRepo.getScreenTimeById(id);

  @override
  Future<ScreenTime?> getScreenTimeForDate(DateTime date) async {
    if (await _settingsService.isScreenTimeEnabled()) {
      final synced = await _localRepo.syncFromNative(date);
      if (synced != null) {
        return synced;
      }
    }

    return _localRepo.getScreenTimeForDate(date);
  }

  @override
  Future<void> deleteScreenTime(int id) async {
    _log('deleteScreenTime called: id=$id');
    final screenTime = await _localRepo.getScreenTimeById(id);
    final syncService = _syncService;
    if (screenTime != null && syncService != null) {
      await syncService.queueDeleteScreenTime(screenTime.date);
      final deleted = await syncService.deleteScreenTime(screenTime.date);
      if (deleted) {
        await syncService.completeQueuedOperation(
          'screen_time_delete:${DateTime(screenTime.date.year, screenTime.date.month, screenTime.date.day).millisecondsSinceEpoch}',
        );
      }
    }
    await _localRepo.deleteScreenTime(id);
  }

  @override
  Stream<List<ScreenTime>> watchRecentScreenTimes({int limit = 30}) =>
      _localRepo.watchRecentScreenTimes(limit: limit);

  @override
  Future<List<ScreenTime>> getScreenTimesForDateRange(
          DateTime start, DateTime end) =>
      _localRepo.getScreenTimesForDateRange(start, end);

  @override
  Future<List<ScreenTime>> getScreenTimesBefore(DateTime date,
          {int limit = 20}) =>
      _localRepo.getScreenTimesBefore(date, limit: limit);

  @override
  Future<List<ScreenTime>> getPendingSyncScreenTimes() =>
      _localRepo.getPendingSyncScreenTimes();

  @override
  Future<void> updateServerId(int localId, int serverId) =>
      _localRepo.updateServerId(localId, serverId);

  @override
  Future<void> saveScreenTimeApps(int screenTimeId, List<ScreenTimeApp> apps) =>
      _localRepo.saveScreenTimeApps(screenTimeId, apps);

  @override
  Future<List<ScreenTimeApp>> getScreenTimeApps(int screenTimeId) =>
      _localRepo.getScreenTimeApps(screenTimeId);
}
