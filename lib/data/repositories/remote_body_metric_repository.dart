import 'dart:developer' as dev;
import '../models/body_metric.dart';
import 'local_body_metric_repository.dart';
import 'body_metric_repository_interface.dart';

/// A body metric repository that treats the backend as source of truth.
/// Local storage acts as a cache.
class RemoteBodyMetricRepository implements BodyMetricRepository {
  final LocalBodyMetricRepository _cache;

  RemoteBodyMetricRepository({
    LocalBodyMetricRepository? cache,
  }) : _cache = cache ?? LocalBodyMetricRepository();

  static void _log(String message) {
    dev.log('[REMOTE_BODY_METRIC_REPO] $message', name: 'v32');
  }

  @override
  Future<BodyMetric> saveBodyMetric(BodyMetric bodyMetric) async {
    _log('saveBodyMetric: date=${bodyMetric.date}, id=${bodyMetric.id}');

    // Save to cache with pendingSync=true
    final bodyMetricToSave = bodyMetric.copyWith(
      updatedAt: DateTime.now(),
      pendingSync: true,
    );

    final saved = await _cache.saveBodyMetric(bodyMetricToSave);
    _log('BodyMetric saved to cache: id=${saved.id}, pendingSync=true');

    return saved;
  }

  @override
  Future<BodyMetric?> getBodyMetricById(int id) => _cache.getBodyMetricById(id);

  @override
  Future<BodyMetric?> getBodyMetricForDate(DateTime date) =>
      _cache.getBodyMetricForDate(date);

  @override
  Future<void> deleteBodyMetric(int id) async {
    _log('deleteBodyMetric: id=$id');
    await _cache.deleteBodyMetric(id);
  }

  @override
  Stream<List<BodyMetric>> watchRecentBodyMetrics({int limit = 30}) =>
      _cache.watchRecentBodyMetrics(limit: limit);

  @override
  Future<List<BodyMetric>> getBodyMetricsForDateRange(
          DateTime start, DateTime end) =>
      _cache.getBodyMetricsForDateRange(start, end);

  @override
  Future<List<BodyMetric>> getBodyMetricsBefore(DateTime date,
          {int limit = 20}) =>
      _cache.getBodyMetricsBefore(date, limit: limit);

  @override
  Future<List<BodyMetric>> getPendingSyncBodyMetrics() =>
      _cache.getPendingSyncBodyMetrics();

  @override
  Future<void> updateServerId(int localId, int serverId) =>
      _cache.updateServerId(localId, serverId);
}
