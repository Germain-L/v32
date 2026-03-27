import 'dart:developer' as dev;

import '../models/screen_time.dart';
import '../services/screen_time_settings_service.dart';
import 'local_screen_time_repository.dart';
import 'screen_time_repository_interface.dart';

/// A screen time repository that treats the backend as source of truth.
/// Local storage acts as a cache.
class RemoteScreenTimeRepository implements ScreenTimeRepository {
  final LocalScreenTimeRepository _cache;
  final ScreenTimeSettingsService _settingsService;

  RemoteScreenTimeRepository({
    LocalScreenTimeRepository? cache,
    ScreenTimeSettingsService? settingsService,
  })  : _cache = cache ?? LocalScreenTimeRepository(),
        _settingsService = settingsService ?? ScreenTimeSettingsService();

  static void _log(String message) {
    dev.log('[REMOTE_SCREEN_TIME_REPO] $message', name: 'v32');
  }

  @override
  Future<ScreenTime> saveScreenTime(ScreenTime screenTime) async {
    _log('saveScreenTime: date=${screenTime.date}, id=${screenTime.id}');

    // Save to cache with pendingSync=true
    final screenTimeToSave = screenTime.copyWith(
      pendingSync: true,
    );

    final saved = await _cache.saveScreenTime(screenTimeToSave);
    _log('ScreenTime saved to cache: id=${saved.id}, pendingSync=true');

    return saved;
  }

  @override
  Future<ScreenTime?> getScreenTimeById(int id) => _cache.getScreenTimeById(id);

  @override
  Future<ScreenTime?> getScreenTimeForDate(DateTime date) async {
    if (await _settingsService.isScreenTimeEnabled()) {
      final synced = await _cache.syncFromNative(date);
      if (synced != null) {
        return synced;
      }
    }

    return _cache.getScreenTimeForDate(date);
  }

  @override
  Future<void> deleteScreenTime(int id) async {
    _log('deleteScreenTime: id=$id');
    await _cache.deleteScreenTime(id);
  }

  @override
  Stream<List<ScreenTime>> watchRecentScreenTimes({int limit = 30}) =>
      _cache.watchRecentScreenTimes(limit: limit);

  @override
  Future<List<ScreenTime>> getScreenTimesForDateRange(
          DateTime start, DateTime end) =>
      _cache.getScreenTimesForDateRange(start, end);

  @override
  Future<List<ScreenTime>> getScreenTimesBefore(DateTime date,
          {int limit = 20}) =>
      _cache.getScreenTimesBefore(date, limit: limit);

  @override
  Future<List<ScreenTime>> getPendingSyncScreenTimes() =>
      _cache.getPendingSyncScreenTimes();

  @override
  Future<void> updateServerId(int localId, int serverId) =>
      _cache.updateServerId(localId, serverId);

  @override
  Future<void> saveScreenTimeApps(int screenTimeId, List<ScreenTimeApp> apps) =>
      _cache.saveScreenTimeApps(screenTimeId, apps);

  @override
  Future<List<ScreenTimeApp>> getScreenTimeApps(int screenTimeId) =>
      _cache.getScreenTimeApps(screenTimeId);
}
