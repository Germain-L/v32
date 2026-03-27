import 'dart:developer' as dev;
import '../models/daily_checkin.dart';
import '../models/sync_operation.dart';
import '../services/sync_config.dart';
import '../services/sync_service.dart';
import 'local_daily_checkin_repository.dart';
import 'daily_checkin_repository_interface.dart';

/// A daily checkin repository that syncs to the backend.
/// Wraps LocalDailyCheckinRepository and adds sync functionality.
class SyncingDailyCheckinRepository implements DailyCheckinRepository {
  final LocalDailyCheckinRepository _localRepo;
  final SyncService? _syncService;

  SyncingDailyCheckinRepository({
    LocalDailyCheckinRepository? localRepo,
    SyncService? syncService,
  })  : _localRepo = localRepo ?? LocalDailyCheckinRepository(),
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
    dev.log('[SYNCING_DAILY_CHECKIN_REPO] $message', name: 'v32');
  }

  @override
  Future<DailyCheckin> saveDailyCheckin(DailyCheckin dailyCheckin) async {
    _log(
        'saveDailyCheckin called: date=${dailyCheckin.date}, id=${dailyCheckin.id}');

    final dailyCheckinToSave = dailyCheckin.copyWith(
      updatedAt: DateTime.now(),
      pendingSync: true,
    );
    final saved = await _localRepo.saveDailyCheckin(dailyCheckinToSave);
    _log('DailyCheckin saved locally: id=${saved.id}');

    final syncService = _syncService;
    if (syncService != null) {
      syncService
          .syncDailyCheckin(
        saved,
        dailyCheckin.id == null ? OperationType.create : OperationType.update,
      )
          .then((success) {
        _log(
          'DailyCheckin sync ${success ? "succeeded" : "failed (will retry later)"}',
        );
      });
    }

    return saved;
  }

  @override
  Future<DailyCheckin?> getDailyCheckinById(int id) =>
      _localRepo.getDailyCheckinById(id);

  @override
  Future<DailyCheckin?> getDailyCheckinForDate(DateTime date) =>
      _localRepo.getDailyCheckinForDate(date);

  @override
  Future<void> deleteDailyCheckin(int id) async {
    _log('deleteDailyCheckin called: id=$id');
    final checkin = await _localRepo.getDailyCheckinById(id);
    final syncService = _syncService;
    if (checkin != null && syncService != null) {
      await syncService.queueDeleteCheckin(checkin.date);
      final deleted = await syncService.deleteCheckin(checkin.date);
      if (deleted) {
        await syncService.completeQueuedOperation(
          'checkin_delete:${DateTime(checkin.date.year, checkin.date.month, checkin.date.day).millisecondsSinceEpoch}',
        );
      }
    }
    await _localRepo.deleteDailyCheckin(id);
  }

  @override
  Stream<List<DailyCheckin>> watchRecentDailyCheckins({int limit = 30}) =>
      _localRepo.watchRecentDailyCheckins(limit: limit);

  @override
  Future<List<DailyCheckin>> getDailyCheckinsForDateRange(
          DateTime start, DateTime end) =>
      _localRepo.getDailyCheckinsForDateRange(start, end);

  @override
  Future<List<DailyCheckin>> getDailyCheckinsBefore(DateTime date,
          {int limit = 20}) =>
      _localRepo.getDailyCheckinsBefore(date, limit: limit);

  @override
  Future<List<DailyCheckin>> getPendingSyncDailyCheckins() =>
      _localRepo.getPendingSyncDailyCheckins();

  @override
  Future<void> updateServerId(int localId, int serverId) =>
      _localRepo.updateServerId(localId, serverId);
}
