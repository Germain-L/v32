import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:v32/data/models/body_metric.dart';
import 'package:v32/data/repositories/body_metric_repository_interface.dart';
import 'package:v32/data/repositories/local_body_metric_repository.dart';
import 'package:v32/data/services/database_service.dart';

void main() {
  group('LocalBodyMetricRepository Integration', () {
    late LocalBodyMetricRepository repository;

    setUp(() async {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
      await DatabaseService.useInMemoryDatabaseForTesting();
      repository = LocalBodyMetricRepository();
    });

    tearDown(() async {
      await DatabaseService.resetForTesting();
    });

    test('implements BodyMetricRepository', () {
      expect(repository, isA<BodyMetricRepository>());
    });

    test('full CRUD flow works', () async {
      // Create
      final bodyMetric = BodyMetric(
        date: DateTime.now(),
        weight: 75.5,
        bodyFat: 18.2,
      );
      final saved = await repository.saveBodyMetric(bodyMetric);
      expect(saved.id, isNotNull);

      // Read
      final retrieved = await repository.getBodyMetricById(saved.id!);
      expect(retrieved?.weight, 75.5);
      expect(retrieved?.bodyFat, 18.2);

      // Update
      final updated = saved.copyWith(weight: 74.5);
      final savedUpdated = await repository.saveBodyMetric(updated);
      expect(savedUpdated.weight, 74.5);

      // Delete
      await repository.deleteBodyMetric(saved.id!);
      final deleted = await repository.getBodyMetricById(saved.id!);
      expect(deleted, isNull);
    });

    test('getBodyMetricForDate returns metric for specific date', () async {
      final date = DateTime(2024, 1, 15);
      await repository.saveBodyMetric(BodyMetric(date: date, weight: 75.0));
      await repository.saveBodyMetric(BodyMetric(
          date: date.add(Duration(days: 1)), weight: 74.5));

      final metric = await repository.getBodyMetricForDate(date);
      expect(metric?.weight, 75.0);
    });

    test('getBodyMetricForDate returns null if no metric for date', () async {
      final metric = await repository.getBodyMetricForDate(DateTime(2024, 1, 15));
      expect(metric, isNull);
    });

    test('getBodyMetricsForDateRange returns metrics in range', () async {
      await repository.saveBodyMetric(
          BodyMetric(date: DateTime(2024, 1, 10), weight: 75.0));
      await repository.saveBodyMetric(
          BodyMetric(date: DateTime(2024, 1, 15), weight: 74.5));
      await repository.saveBodyMetric(
          BodyMetric(date: DateTime(2024, 1, 20), weight: 74.0));
      await repository.saveBodyMetric(
          BodyMetric(date: DateTime(2024, 1, 25), weight: 73.5));

      final metrics = await repository.getBodyMetricsForDateRange(
        DateTime(2024, 1, 12),
        DateTime(2024, 1, 22),
      );
      expect(metrics.length, 2);
    });

    test('getPendingSyncBodyMetrics returns only pending metrics', () async {
      await repository.saveBodyMetric(BodyMetric(
        date: DateTime.now(),
        weight: 75.0,
        pendingSync: true,
      ));
      await repository.saveBodyMetric(BodyMetric(
        date: DateTime.now(),
        weight: 74.5,
        pendingSync: false,
      ));

      final pending = await repository.getPendingSyncBodyMetrics();
      expect(pending.length, 1);
      expect(pending.first.weight, 75.0);
    });

    test('updateServerId updates serverId and clears pendingSync', () async {
      final bodyMetric = await repository.saveBodyMetric(BodyMetric(
        date: DateTime.now(),
        weight: 75.0,
        pendingSync: true,
      ));

      expect(bodyMetric.pendingSync, true);
      expect(bodyMetric.serverId, isNull);

      await repository.updateServerId(bodyMetric.id!, 999);

      final updated = await repository.getBodyMetricById(bodyMetric.id!);
      expect(updated?.serverId, 999);
      expect(updated?.pendingSync, false);
    });

    test('getBodyMetricsBefore returns metrics before date', () async {
      await repository.saveBodyMetric(
          BodyMetric(date: DateTime(2024, 1, 10), weight: 75.0));
      await repository.saveBodyMetric(
          BodyMetric(date: DateTime(2024, 1, 15), weight: 74.5));
      await repository.saveBodyMetric(
          BodyMetric(date: DateTime(2024, 1, 20), weight: 74.0));

      final metrics = await repository.getBodyMetricsBefore(DateTime(2024, 1, 18));
      expect(metrics.length, 2);
    });
  });
}
