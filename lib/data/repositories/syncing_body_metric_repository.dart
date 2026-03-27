import 'dart:developer' as dev;
import '../models/body_metric.dart';
import 'local_body_metric_repository.dart';
import 'body_metric_repository_interface.dart';

/// A body metric repository that syncs to the backend.
/// Wraps LocalBodyMetricRepository and adds sync functionality.
class SyncingBodyMetricRepository implements BodyMetricRepository {
  final LocalBodyMetricRepository _localRepo;

  SyncingBodyMetricRepository({
    LocalBodyMetricRepository? localRepo,
  }) : _localRepo = localRepo ?? LocalBodyMetricRepository();

  static void _log(String message) {
    dev.log('[SYNCING_BODY_METRIC_REPO] $message', name: 'v32');
  }

  @override
  Future<BodyMetric> saveBodyMetric(BodyMetric bodyMetric) async {
    _log('saveBodyMetric called: date=${bodyMetric.date}, id=${bodyMetric.id}');

    // Save locally first
    final saved = await _localRepo.saveBodyMetric(bodyMetric);
    _log('BodyMetric saved locally: id=${saved.id}');

    // TODO: Trigger sync when backend endpoints are available

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
