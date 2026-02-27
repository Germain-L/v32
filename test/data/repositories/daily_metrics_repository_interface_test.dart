import 'package:flutter_test/flutter_test.dart';
import 'package:v32/data/models/daily_metrics.dart';
import 'package:v32/data/repositories/daily_metrics_repository_interface.dart';

void main() {
  group('DailyMetricsRepository Interface', () {
    test('interface can be implemented', () {
      expect(() => _TestDailyMetricsRepository(), returnsNormally);
    });

    test('saveMetrics accepts DailyMetrics', () async {
      final repo = _TestDailyMetricsRepository();
      final metrics = DailyMetrics(date: DateTime.now());

      await expectLater(repo.saveMetrics(metrics), completes);
    });

    test('getMetricsForDate returns Future<DailyMetrics?>', () async {
      final repo = _TestDailyMetricsRepository();

      final result = await repo.getMetricsForDate(DateTime.now());

      expect(result, isNull);
    });

    test('deleteMetricsForDate returns Future<void>', () async {
      final repo = _TestDailyMetricsRepository();

      await expectLater(repo.deleteMetricsForDate(DateTime.now()), completes);
    });

    test('getMetricsForMonth returns Map<String, DailyMetrics>', () async {
      final repo = _TestDailyMetricsRepository();

      final result = await repo.getMetricsForMonth(2024, 1);

      expect(result, isA<Map<String, DailyMetrics>>());
    });
  });
}

class _TestDailyMetricsRepository implements DailyMetricsRepository {
  @override
  Future<void> saveMetrics(DailyMetrics metrics) async {}

  @override
  Future<DailyMetrics?> getMetricsForDate(DateTime date) async => null;

  @override
  Future<void> deleteMetricsForDate(DateTime date) async {}

  @override
  Future<Map<String, DailyMetrics>> getMetricsForMonth(
    int year,
    int month,
  ) async => {};
}
