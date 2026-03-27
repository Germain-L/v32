import 'dart:developer' as dev;
import '../models/body_metric.dart';
import '../models/sync_operation.dart';
import '../services/sync_config.dart';
import '../services/sync_service.dart';
import 'local_body_metric_repository.dart';
import 'body_metric_repository_interface.dart';

/// A body metric repository that syncs to the backend.
/// Wraps LocalBodyMetricRepository and adds sync functionality.
class SyncingBodyMetricRepository implements BodyMetricRepository {
  final LocalBodyMetricRepository _localRepo;
  final SyncService? _syncService;

  SyncingBodyMetricRepository({
    LocalBodyMetricRepository? localRepo,
    SyncService? syncService,
  })  : _localRepo = localRepo ?? LocalBodyMetricRepository(),
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
    dev.log('[SYNCING_BODY_METRIC_REPO] $message', name: 'v32');
  }

  @override
  Future<BodyMetric> saveBodyMetric(BodyMetric bodyMetric) async {
    _log('saveBodyMetric called: date=${bodyMetric.date}, id=${bodyMetric.id}');

    final bodyMetricToSave = bodyMetric.copyWith(
      updatedAt: DateTime.now(),
      pendingSync: true,
    );
    final saved = await _localRepo.saveBodyMetric(bodyMetricToSave);
    _log('BodyMetric saved locally: id=${saved.id}');

    final syncService = _syncService;
    if (syncService != null) {
      syncService
          .syncBodyMetric(
        saved,
        bodyMetric.id == null ? OperationType.create : OperationType.update,
      )
          .then((success) {
        _log(
          'BodyMetric sync ${success ? "succeeded" : "failed (will retry later)"}',
        );
      });
    }

    return saved;
  }

  @override
  Future<BodyMetric?> getBodyMetricById(int id) =>
      _localRepo.getBodyMetricById(id);

  @override
  Future<BodyMetric?> getBodyMetricForDate(DateTime date) =>
      _localRepo.getBodyMetricForDate(date);

  @override
  Future<void> deleteBodyMetric(int id) async {
    _log('deleteBodyMetric called: id=$id');
    final bodyMetric = await _localRepo.getBodyMetricById(id);
    final syncService = _syncService;
    final serverId = bodyMetric?.serverId;
    if (serverId != null && syncService != null) {
      await syncService.queueDeleteBodyMetric(serverId);
      final deleted = await syncService.deleteBodyMetric(serverId);
      if (deleted) {
        await syncService.completeQueuedOperation(
          'body_metric_delete:$serverId',
        );
      }
    }
    await _localRepo.deleteBodyMetric(id);
  }

  @override
  Stream<List<BodyMetric>> watchRecentBodyMetrics({int limit = 30}) =>
      _localRepo.watchRecentBodyMetrics(limit: limit);

  @override
  Future<List<BodyMetric>> getBodyMetricsForDateRange(
          DateTime start, DateTime end) =>
      _localRepo.getBodyMetricsForDateRange(start, end);

  @override
  Future<List<BodyMetric>> getBodyMetricsBefore(DateTime date,
          {int limit = 20}) =>
      _localRepo.getBodyMetricsBefore(date, limit: limit);

  @override
  Future<List<BodyMetric>> getPendingSyncBodyMetrics() =>
      _localRepo.getPendingSyncBodyMetrics();

  @override
  Future<void> updateServerId(int localId, int serverId) =>
      _localRepo.updateServerId(localId, serverId);
}
