import 'package:flutter_test/flutter_test.dart';
import 'package:v32/data/models/daily_metrics.dart';
import 'package:v32/data/repositories/mock_daily_metrics_repository.dart';

void main() {
  group('MockDailyMetricsRepository', () {
    late MockDailyMetricsRepository repository;

    setUp(() {
      repository = MockDailyMetricsRepository();
    });

    tearDown(() {
      repository.clear();
    });

    test('implements DailyMetricsRepository', () {
      expect(repository, isA<MockDailyMetricsRepository>());
    });

    test('saveMetrics stores metrics', () async {
      final metrics = DailyMetrics(
        date: DateTime(2024, 1, 15),
        waterLiters: 2.5,
      );

      await repository.saveMetrics(metrics);

      final retrieved = await repository.getMetricsForDate(
        DateTime(2024, 1, 15),
      );
      expect(retrieved?.waterLiters, 2.5);
    });

    test('getMetricsForDate returns null for non-existent', () async {
      final result = await repository.getMetricsForDate(DateTime(2024, 1, 15));
      expect(result, isNull);
    });

    test('deleteMetricsForDate removes metrics', () async {
      await repository.saveMetrics(DailyMetrics(date: DateTime(2024, 1, 15)));

      await repository.deleteMetricsForDate(DateTime(2024, 1, 15));

      final retrieved = await repository.getMetricsForDate(
        DateTime(2024, 1, 15),
      );
      expect(retrieved, isNull);
    });
  });
}
