import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:v32/data/models/daily_metrics.dart';
import 'package:v32/data/repositories/local_daily_metrics_repository.dart';
import 'package:v32/data/repositories/daily_metrics_repository_interface.dart';
import 'package:v32/data/services/database_service.dart';

void main() {
  group('LocalDailyMetricsRepository Integration', () {
    late LocalDailyMetricsRepository repository;

    setUp(() async {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
      await DatabaseService.useInMemoryDatabaseForTesting();
      repository = LocalDailyMetricsRepository();
    });

    tearDown(() async {
      await DatabaseService.resetForTesting();
    });

    test('implements DailyMetricsRepository', () {
      expect(repository, isA<DailyMetricsRepository>());
    });

    test('saveMetrics and getMetricsForDate work', () async {
      final date = DateTime(2024, 1, 15);
      final metrics = DailyMetrics(date: date, waterLiters: 2.5);

      await repository.saveMetrics(metrics);

      final retrieved = await repository.getMetricsForDate(date);
      expect(retrieved?.waterLiters, 2.5);
    });

    test('deleteMetricsForDate removes metrics', () async {
      final date = DateTime(2024, 1, 15);
      await repository.saveMetrics(DailyMetrics(date: date));

      await repository.deleteMetricsForDate(date);

      final retrieved = await repository.getMetricsForDate(date);
      expect(retrieved, isNull);
    });
  });
}
