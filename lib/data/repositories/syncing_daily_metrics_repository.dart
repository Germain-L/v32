import 'dart:developer' as dev;

import '../models/daily_metrics.dart';
import '../services/sync_config.dart';
import '../services/sync_service.dart';
import 'daily_metrics_repository_interface.dart';
import 'local_daily_metrics_repository.dart';

class SyncingDailyMetricsRepository implements DailyMetricsRepository {
  SyncingDailyMetricsRepository({
    LocalDailyMetricsRepository? localRepo,
    SyncService? syncService,
  })  : _localRepo = localRepo ?? LocalDailyMetricsRepository(),
        _syncService = syncService ?? _resolveSyncService();

  final LocalDailyMetricsRepository _localRepo;
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
    dev.log('[SYNCING_DAILY_METRICS_REPO] $message', name: 'v32');
  }

  @override
  Future<void> saveMetrics(DailyMetrics metrics) async {
    await _localRepo.saveMetrics(metrics);
    _log('DailyMetrics saved locally: date=${metrics.date}');

    final syncService = _syncService;
    if (syncService != null) {
      await syncService.queueUpsertDailyMetrics(metrics);
      final success = await syncService.syncDailyMetrics(metrics);
      if (success) {
        await syncService.completeQueuedOperation(
          'daily_metrics:${DateTime(metrics.date.year, metrics.date.month, metrics.date.day).millisecondsSinceEpoch}',
        );
      }
      _log(
        'DailyMetrics sync ${success ? "succeeded" : "failed (local only for now)"}',
      );
    }
  }

  @override
  Future<DailyMetrics?> getMetricsForDate(DateTime date) =>
      _localRepo.getMetricsForDate(date);

  @override
  Future<void> deleteMetricsForDate(DateTime date) async {
    final existing = await _localRepo.getMetricsForDate(date);
    await _localRepo.deleteMetricsForDate(date);
    _log('DailyMetrics deleted locally: date=$date');

    final syncService = _syncService;
    if (syncService != null && existing != null) {
      await syncService.queueDeleteDailyMetrics(date);
      final success = await syncService.deleteDailyMetrics(date);
      if (success) {
        await syncService.completeQueuedOperation(
          'daily_metrics_delete:${DateTime(date.year, date.month, date.day).millisecondsSinceEpoch}',
        );
      }
      _log(
        'DailyMetrics delete sync ${success ? "succeeded" : "failed"}',
      );
    }
  }

  @override
  Future<Map<String, DailyMetrics>> getMetricsForMonth(int year, int month) =>
      _localRepo.getMetricsForMonth(year, month);

  @override
  Future<Map<String, DailyMetrics>> getMetricsForRange(
    DateTime start,
    DateTime end,
  ) =>
      _localRepo.getMetricsForRange(start, end);
}
