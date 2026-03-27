import 'dart:developer' as dev;

import '../models/screen_time.dart';
import '../services/screen_time_settings_service.dart';
import 'local_screen_time_repository.dart';
import 'screen_time_repository_interface.dart';

/// A screen time repository that syncs to the backend.
/// Wraps LocalScreenTimeRepository and adds sync functionality.
class SyncingScreenTimeRepository implements ScreenTimeRepository {
  final LocalScreenTimeRepository _localRepo;
  final ScreenTimeSettingsService _settingsService;

  SyncingScreenTimeRepository({
    LocalScreenTimeRepository? localRepo,
    ScreenTimeSettingsService? settingsService,
  })  : _localRepo = localRepo ?? LocalScreenTimeRepository(),
        _settingsService = settingsService ?? ScreenTimeSettingsService();

  static void _log(String message) {
    dev.log('[SYNCING_SCREEN_TIME_REPO] $message', name: 'v32');
  }

  @override
  Future<ScreenTime> saveScreenTime(ScreenTime screenTime) async {
    _log('saveScreenTime called: date=${screenTime.date}, id=${screenTime.id}');

    // Save locally first
    final saved = await _localRepo.saveScreenTime(screenTime);
    _log('ScreenTime saved locally: id=${saved.id}');

    // TODO: Trigger sync when backend endpoints are available

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
