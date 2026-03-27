import '../models/body_metric.dart';
import 'body_metric_repository_interface.dart';

/// In-memory implementation of BodyMetricRepository for unit testing.
/// Stores data in memory - fast but not persistent.
class MockBodyMetricRepository implements BodyMetricRepository {
  final Map<int, BodyMetric> _bodyMetrics = {};
  int _nextId = 1;

  @override
  Future<BodyMetric> saveBodyMetric(BodyMetric bodyMetric) async {
    if (bodyMetric.id == null) {
      final newBodyMetric = bodyMetric.copyWith(id: _nextId++);
      _bodyMetrics[newBodyMetric.id!] = newBodyMetric;
      return newBodyMetric;
    } else {
      _bodyMetrics[bodyMetric.id!] = bodyMetric;
      return bodyMetric;
    }
  }

  @override
  Future<BodyMetric?> getBodyMetricById(int id) async => _bodyMetrics[id];

  @override
  Future<BodyMetric?> getBodyMetricForDate(DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(Duration(days: 1));

    final metrics = _bodyMetrics.values
        .where(
          (m) =>
              m.date.isAfter(startOfDay.subtract(Duration(microseconds: 1))) &&
              m.date.isBefore(endOfDay),
        )
        .toList();

    if (metrics.isEmpty) return null;
    metrics.sort((a, b) => b.date.compareTo(a.date));
    return metrics.first;
  }

  @override
  Future<void> deleteBodyMetric(int id) async {
    _bodyMetrics.remove(id);
  }

  @override
  Stream<List<BodyMetric>> watchRecentBodyMetrics({int limit = 30}) async* {
    yield _bodyMetrics.values.take(limit).toList();
  }

  @override
  Future<List<BodyMetric>> getBodyMetricsForDateRange(
      DateTime start, DateTime end) async {
    return _bodyMetrics.values
        .where(
          (m) =>
              m.date.isAfter(start.subtract(Duration(microseconds: 1))) &&
              m.date.isBefore(end),
        )
        .toList();
  }

  @override
  Future<List<BodyMetric>> getBodyMetricsBefore(DateTime date,
      {int limit = 20}) async {
    return _bodyMetrics.values
        .where((m) => m.date.isBefore(date))
        .take(limit)
        .toList();
  }

  @override
  Future<List<BodyMetric>> getPendingSyncBodyMetrics() async {
    return _bodyMetrics.values.where((m) => m.pendingSync).toList();
  }

  @override
  Future<void> updateServerId(int localId, int serverId) async {
    final bodyMetric = _bodyMetrics[localId];
    if (bodyMetric != null) {
      _bodyMetrics[localId] = bodyMetric.copyWith(serverId: serverId, pendingSync: false);
    }
  }

  /// Clear all data (useful in tests)
  void clear() {
    _bodyMetrics.clear();
    _nextId = 1;
  }
}
