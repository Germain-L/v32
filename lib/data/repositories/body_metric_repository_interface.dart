import '../models/body_metric.dart';

abstract class BodyMetricRepository {
  Future<BodyMetric> saveBodyMetric(BodyMetric bodyMetric);
  Future<BodyMetric?> getBodyMetricById(int id);
  Future<BodyMetric?> getBodyMetricForDate(DateTime date);
  Future<void> deleteBodyMetric(int id);
  Stream<List<BodyMetric>> watchRecentBodyMetrics({int limit = 30});
  Future<List<BodyMetric>> getBodyMetricsForDateRange(
      DateTime start, DateTime end);
  Future<List<BodyMetric>> getBodyMetricsBefore(DateTime date, {int limit = 20});
  Future<List<BodyMetric>> getPendingSyncBodyMetrics();
  Future<void> updateServerId(int localId, int serverId);
}
