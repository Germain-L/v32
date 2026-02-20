import 'package:v32/data/models/daily_metrics.dart';
import 'package:v32/data/repositories/daily_metrics_repository.dart';

class FakeDailyMetricsRepository extends DailyMetricsRepository {
  FakeDailyMetricsRepository({
    Map<String, DailyMetrics>? seedMetrics,
    this.throwOnGetMetricsForDate = false,
    this.throwOnGetMetricsForMonth = false,
    this.throwOnGetMetricsForRange = false,
    this.throwOnSaveMetrics = false,
    this.throwOnDeleteMetrics = false,
  }) : _metricsByDate = {...?seedMetrics};

  final Map<String, DailyMetrics> _metricsByDate;
  final bool throwOnGetMetricsForDate;
  final bool throwOnGetMetricsForMonth;
  final bool throwOnGetMetricsForRange;
  final bool throwOnSaveMetrics;
  final bool throwOnDeleteMetrics;

  @override
  Future<void> saveMetrics(DailyMetrics metrics) async {
    if (throwOnSaveMetrics) {
      throw Exception('saveMetrics failed');
    }
    final normalized = DateTime(
      metrics.date.year,
      metrics.date.month,
      metrics.date.day,
    );
    _metricsByDate[_dateKey(normalized)] = DailyMetrics(
      date: normalized,
      waterLiters: metrics.waterLiters,
      exerciseDone: metrics.exerciseDone,
      exerciseNote: metrics.exerciseNote,
    );
  }

  @override
  Future<DailyMetrics?> getMetricsForDate(DateTime date) async {
    if (throwOnGetMetricsForDate) {
      throw Exception('getMetricsForDate failed');
    }
    final normalized = DateTime(date.year, date.month, date.day);
    return _metricsByDate[_dateKey(normalized)];
  }

  @override
  Future<Map<String, DailyMetrics>> getMetricsForMonth(
    int year,
    int month,
  ) async {
    if (throwOnGetMetricsForMonth) {
      throw Exception('getMetricsForMonth failed');
    }
    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 1);
    return _filterRange(start, end);
  }

  @override
  Future<Map<String, DailyMetrics>> getMetricsForRange(
    DateTime start,
    DateTime end,
  ) async {
    if (throwOnGetMetricsForRange) {
      throw Exception('getMetricsForRange failed');
    }
    final normalizedStart = DateTime(start.year, start.month, start.day);
    final normalizedEnd = DateTime(end.year, end.month, end.day);
    return _filterRange(
      normalizedStart,
      normalizedEnd.add(const Duration(days: 1)),
    );
  }

  @override
  Future<void> deleteMetricsForDate(DateTime date) async {
    if (throwOnDeleteMetrics) {
      throw Exception('deleteMetricsForDate failed');
    }
    final normalized = DateTime(date.year, date.month, date.day);
    _metricsByDate.remove(_dateKey(normalized));
  }

  Map<String, DailyMetrics> _filterRange(DateTime start, DateTime end) {
    final map = <String, DailyMetrics>{};
    _metricsByDate.forEach((key, value) {
      final date = value.date;
      if (!date.isBefore(start) && date.isBefore(end)) {
        map[key] = value;
      }
    });
    return map;
  }

  String _dateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
