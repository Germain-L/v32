import '../models/daily_metrics.dart';
import 'daily_metrics_repository_interface.dart';

/// In-memory implementation of DailyMetricsRepository for unit testing.
class MockDailyMetricsRepository implements DailyMetricsRepository {
  final Map<String, DailyMetrics> _metrics = {};

  String _dateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  @override
  Future<void> saveMetrics(DailyMetrics metrics) async {
    final normalized = DateTime(
      metrics.date.year,
      metrics.date.month,
      metrics.date.day,
    );
    _metrics[_dateKey(normalized)] = DailyMetrics(
      date: normalized,
      waterLiters: metrics.waterLiters,
      exerciseDone: metrics.exerciseDone,
      exerciseNote: metrics.exerciseNote,
    );
  }

  @override
  Future<DailyMetrics?> getMetricsForDate(DateTime date) async {
    final normalized = DateTime(date.year, date.month, date.day);
    return _metrics[_dateKey(normalized)];
  }

  @override
  Future<void> deleteMetricsForDate(DateTime date) async {
    final normalized = DateTime(date.year, date.month, date.day);
    _metrics.remove(_dateKey(normalized));
  }

  @override
  Future<Map<String, DailyMetrics>> getMetricsForMonth(
    int year,
    int month,
  ) async {
    return Map.unmodifiable(_metrics);
  }

  /// Clear all data (useful in tests)
  void clear() {
    _metrics.clear();
  }
}
