import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:v32/data/models/hydration.dart';
import 'package:v32/data/repositories/hydration_repository_interface.dart';
import 'package:v32/data/repositories/local_hydration_repository.dart';
import 'package:v32/data/services/database_service.dart';

void main() {
  group('LocalHydrationRepository Integration', () {
    late LocalHydrationRepository repository;

    setUp(() async {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
      await DatabaseService.useInMemoryDatabaseForTesting();
      repository = LocalHydrationRepository();
    });

    tearDown(() async {
      await DatabaseService.resetForTesting();
    });

    test('implements HydrationRepository', () {
      expect(repository, isA<HydrationRepository>());
    });

    test('full CRUD flow works', () async {
      // Create
      final hydration = Hydration(
        date: DateTime.now(),
        amountMl: 500,
      );
      final saved = await repository.saveHydration(hydration);
      expect(saved.id, isNotNull);

      // Read
      final retrieved = await repository.getHydrationById(saved.id!);
      expect(retrieved?.amountMl, 500);

      // Update
      final updated = saved.copyWith(amountMl: 750);
      final savedUpdated = await repository.saveHydration(updated);
      expect(savedUpdated.amountMl, 750);

      // Delete
      await repository.deleteHydration(saved.id!);
      final deleted = await repository.getHydrationById(saved.id!);
      expect(deleted, isNull);
    });

    test('getHydrationsForDate returns hydrations for specific date', () async {
      final date = DateTime(2024, 1, 15, 10);
      await repository.saveHydration(
          Hydration(date: date, amountMl: 500));
      await repository.saveHydration(
          Hydration(date: date.add(Duration(hours: 2)), amountMl: 250));
      // Different date
      await repository.saveHydration(
          Hydration(date: DateTime(2024, 1, 16), amountMl: 750));

      final hydrations = await repository.getHydrationsForDate(date);
      expect(hydrations.length, 2);
    });

    test('getTotalHydrationForDate returns correct sum', () async {
      final date = DateTime(2024, 1, 15);
      await repository.saveHydration(Hydration(date: date, amountMl: 500));
      await repository.saveHydration(
          Hydration(date: date.add(Duration(hours: 2)), amountMl: 250));
      await repository.saveHydration(
          Hydration(date: date.add(Duration(hours: 4)), amountMl: 300));

      final total = await repository.getTotalHydrationForDate(date);
      expect(total, 1050);
    });

    test('getTotalHydrationForDate returns 0 if no hydrations', () async {
      final total =
          await repository.getTotalHydrationForDate(DateTime(2024, 1, 15));
      expect(total, 0);
    });

    test('getHydrationsForDateRange returns hydrations in range', () async {
      await repository.saveHydration(
          Hydration(date: DateTime(2024, 1, 10), amountMl: 500));
      await repository.saveHydration(
          Hydration(date: DateTime(2024, 1, 15), amountMl: 600));
      await repository.saveHydration(
          Hydration(date: DateTime(2024, 1, 20), amountMl: 700));
      await repository.saveHydration(
          Hydration(date: DateTime(2024, 1, 25), amountMl: 800));

      final hydrations = await repository.getHydrationsForDateRange(
        DateTime(2024, 1, 12),
        DateTime(2024, 1, 22),
      );
      expect(hydrations.length, 2);
    });

    test('getPendingSyncHydrations returns only pending hydrations', () async {
      await repository.saveHydration(Hydration(
        date: DateTime.now(),
        amountMl: 500,
        pendingSync: true,
      ));
      await repository.saveHydration(Hydration(
        date: DateTime.now().add(Duration(hours: 1)),
        amountMl: 250,
        pendingSync: false,
      ));

      final pending = await repository.getPendingSyncHydrations();
      expect(pending.length, 1);
      expect(pending.first.amountMl, 500);
    });

    test('updateServerId updates serverId and clears pendingSync', () async {
      final hydration = await repository.saveHydration(Hydration(
        date: DateTime.now(),
        amountMl: 500,
        pendingSync: true,
      ));

      expect(hydration.pendingSync, true);
      expect(hydration.serverId, isNull);

      await repository.updateServerId(hydration.id!, 999);

      final updated = await repository.getHydrationById(hydration.id!);
      expect(updated?.serverId, 999);
      expect(updated?.pendingSync, false);
    });

    test('getHydrationsBefore returns hydrations before date', () async {
      await repository.saveHydration(
          Hydration(date: DateTime(2024, 1, 10), amountMl: 500));
      await repository.saveHydration(
          Hydration(date: DateTime(2024, 1, 15), amountMl: 600));
      await repository.saveHydration(
          Hydration(date: DateTime(2024, 1, 20), amountMl: 700));

      final hydrations =
          await repository.getHydrationsBefore(DateTime(2024, 1, 18));
      expect(hydrations.length, 2);
    });
  });
}
