import 'dart:developer' as dev;
import '../models/daily_checkin.dart';
import 'local_daily_checkin_repository.dart';
import 'daily_checkin_repository_interface.dart';

/// A daily checkin repository that syncs to the backend.
/// Wraps LocalDailyCheckinRepository and adds sync functionality.
class SyncingDailyCheckinRepository implements DailyCheckinRepository {
  final LocalDailyCheckinRepository _localRepo;

  SyncingDailyCheckinRepository({
    LocalDailyCheckinRepository? localRepo,
  }) : _localRepo = localRepo ?? LocalDailyCheckinRepository();

  static void _log(String message) {
    dev.log('[SYNCING_DAILY_CHECKIN_REPO] $message', name: 'v32');
  }

  @override
  Future<DailyCheckin> saveDailyCheckin(DailyCheckin dailyCheckin) async {
    _log(
        'saveDailyCheckin called: date=${dailyCheckin.date}, id=${dailyCheckin.id}');

    // Save locally first
    final saved = await _localRepo.saveDailyCheckin(dailyCheckin);
    _log('DailyCheckin saved locally: id=${saved.id}');

    // TODO: Trigger sync when backend endpoints are available

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
