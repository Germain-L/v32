import 'dart:developer' as dev;
import '../models/daily_checkin.dart';
import 'local_daily_checkin_repository.dart';
import 'daily_checkin_repository_interface.dart';

/// A daily checkin repository that treats the backend as source of truth.
/// Local storage acts as a cache.
class RemoteDailyCheckinRepository implements DailyCheckinRepository {
  final LocalDailyCheckinRepository _cache;

  RemoteDailyCheckinRepository({
    LocalDailyCheckinRepository? cache,
  }) : _cache = cache ?? LocalDailyCheckinRepository();

  static void _log(String message) {
    dev.log('[REMOTE_DAILY_CHECKIN_REPO] $message', name: 'v32');
  }

  @override
  Future<DailyCheckin> saveDailyCheckin(DailyCheckin dailyCheckin) async {
    _log('saveDailyCheckin: date=${dailyCheckin.date}, id=${dailyCheckin.id}');

    // Save to cache with pendingSync=true
    final dailyCheckinToSave = dailyCheckin.copyWith(
      updatedAt: DateTime.now(),
      pendingSync: true,
    );

    final saved = await _cache.saveDailyCheckin(dailyCheckinToSave);
    _log('DailyCheckin saved to cache: id=${saved.id}, pendingSync=true');

    return saved;
  }

  @override
  Future<DailyCheckin?> getDailyCheckinById(int id) =>
      _cache.getDailyCheckinById(id);

  @override
  Future<DailyCheckin?> getDailyCheckinForDate(DateTime date) =>
      _cache.getDailyCheckinForDate(date);

  @override
  Future<void> deleteDailyCheckin(int id) async {
    _log('deleteDailyCheckin: id=$id');
    await _cache.deleteDailyCheckin(id);
  }

  @override
  Stream<List<DailyCheckin>> watchRecentDailyCheckins({int limit = 30}) =>
      _cache.watchRecentDailyCheckins(limit: limit);

  @override
  Future<List<DailyCheckin>> getDailyCheckinsForDateRange(
          DateTime start, DateTime end) =>
      _cache.getDailyCheckinsForDateRange(start, end);

  @override
  Future<List<DailyCheckin>> getDailyCheckinsBefore(DateTime date,
          {int limit = 20}) =>
      _cache.getDailyCheckinsBefore(date, limit: limit);

  @override
  Future<List<DailyCheckin>> getPendingSyncDailyCheckins() =>
      _cache.getPendingSyncDailyCheckins();

  @override
  Future<void> updateServerId(int localId, int serverId) =>
      _cache.updateServerId(localId, serverId);
}
