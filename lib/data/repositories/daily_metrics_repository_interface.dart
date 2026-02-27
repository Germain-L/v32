import '../models/daily_metrics.dart';

/// Abstract interface for daily metrics repository operations.
abstract class DailyMetricsRepository {
  /// Save metrics for a date (upsert)
  Future<void> saveMetrics(DailyMetrics metrics);

  /// Get metrics for a specific date
  Future<DailyMetrics?> getMetricsForDate(DateTime date);

  /// Delete metrics for a date
  Future<void> deleteMetricsForDate(DateTime date);

  /// Get all metrics for a month, keyed by date string (YYYY-MM-DD)
  Future<Map<String, DailyMetrics>> getMetricsForMonth(int year, int month);
}
