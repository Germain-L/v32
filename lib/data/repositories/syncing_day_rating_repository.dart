import 'dart:developer' as dev;

import '../services/sync_config.dart';
import '../services/sync_service.dart';
import 'day_rating_repository_interface.dart';
import 'local_day_rating_repository.dart';

class SyncingDayRatingRepository implements DayRatingRepository {
  SyncingDayRatingRepository({
    LocalDayRatingRepository? localRepo,
    SyncService? syncService,
  })  : _localRepo = localRepo ?? LocalDayRatingRepository(),
        _syncService = syncService ?? _resolveSyncService();

  final LocalDayRatingRepository _localRepo;
  final SyncService? _syncService;

  static SyncService? _resolveSyncService() {
    if (!SyncConfig.enabled ||
        !SyncConfig.hasCredentials ||
        !SyncService.isInitialized) {
      return null;
    }
    return SyncService.instance;
  }

  static void _log(String message) {
    dev.log('[SYNCING_DAY_RATING_REPO] $message', name: 'v32');
  }

  @override
  Future<void> saveRating(DateTime date, int score) async {
    await _localRepo.saveRating(date, score);
    _log('DayRating saved locally: date=$date score=$score');

    final syncService = _syncService;
    if (syncService != null) {
      await syncService.queueUpsertDayRating(date, score);
      final success = await syncService.syncDayRating(date, score);
      if (success) {
        await syncService.completeQueuedOperation(
          'day_rating:${DateTime(date.year, date.month, date.day).millisecondsSinceEpoch}',
        );
      }
      _log(
        'DayRating sync ${success ? "succeeded" : "failed (local only for now)"}',
      );
    }
  }

  @override
  Future<int?> getRatingForDate(DateTime date) =>
      _localRepo.getRatingForDate(date);

  @override
  Future<Map<String, int>> getRatingsForMonth(int year, int month) =>
      _localRepo.getRatingsForMonth(year, month);
}
