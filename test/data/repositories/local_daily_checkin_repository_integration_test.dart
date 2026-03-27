import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:v32/data/models/daily_checkin.dart';
import 'package:v32/data/repositories/daily_checkin_repository_interface.dart';
import 'package:v32/data/repositories/local_daily_checkin_repository.dart';
import 'package:v32/data/services/database_service.dart';

void main() {
  group('LocalDailyCheckinRepository Integration', () {
    late LocalDailyCheckinRepository repository;

    setUp(() async {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
      await DatabaseService.useInMemoryDatabaseForTesting();
      repository = LocalDailyCheckinRepository();
    });

    tearDown(() async {
      await DatabaseService.resetForTesting();
    });

    test('implements DailyCheckinRepository', () {
      expect(repository, isA<DailyCheckinRepository>());
    });

    test('full CRUD flow works', () async {
      // Create
      final checkin = DailyCheckin(
        date: DateTime.now(),
        mood: 7,
        energy: 6,
        focus: 5,
      );
      final saved = await repository.saveDailyCheckin(checkin);
      expect(saved.id, isNotNull);

      // Read
      final retrieved = await repository.getDailyCheckinById(saved.id!);
      expect(retrieved?.mood, 7);
      expect(retrieved?.energy, 6);
      expect(retrieved?.focus, 5);

      // Update
      final updated = saved.copyWith(mood: 8, energy: 7);
      final savedUpdated = await repository.saveDailyCheckin(updated);
      expect(savedUpdated.mood, 8);
      expect(savedUpdated.energy, 7);

      // Delete
      await repository.deleteDailyCheckin(saved.id!);
      final deleted = await repository.getDailyCheckinById(saved.id!);
      expect(deleted, isNull);
    });

    test('getDailyCheckinForDate returns checkin for specific date', () async {
      final date = DateTime(2024, 1, 15);
      await repository.saveDailyCheckin(
          DailyCheckin(date: date, mood: 7, energy: 6));
      await repository.saveDailyCheckin(DailyCheckin(
          date: date.add(Duration(days: 1)), mood: 8, energy: 7));

      final checkin = await repository.getDailyCheckinForDate(date);
      expect(checkin?.mood, 7);
      expect(checkin?.energy, 6);
    });

    test('getDailyCheckinForDate returns null if no checkin for date', () async {
      final checkin =
          await repository.getDailyCheckinForDate(DateTime(2024, 1, 15));
      expect(checkin, isNull);
    });

    test('getDailyCheckinsForDateRange returns checkins in range', () async {
      await repository.saveDailyCheckin(
          DailyCheckin(date: DateTime(2024, 1, 10), mood: 5));
      await repository.saveDailyCheckin(
          DailyCheckin(date: DateTime(2024, 1, 15), mood: 6));
      await repository.saveDailyCheckin(
          DailyCheckin(date: DateTime(2024, 1, 20), mood: 7));
      await repository.saveDailyCheckin(
          DailyCheckin(date: DateTime(2024, 1, 25), mood: 8));

      final checkins = await repository.getDailyCheckinsForDateRange(
        DateTime(2024, 1, 12),
        DateTime(2024, 1, 22),
      );
      expect(checkins.length, 2);
    });

    test('getPendingSyncDailyCheckins returns only pending checkins', () async {
      await repository.saveDailyCheckin(DailyCheckin(
        date: DateTime.now(),
        mood: 7,
        pendingSync: true,
      ));
      await repository.saveDailyCheckin(DailyCheckin(
        date: DateTime.now().add(Duration(days: 1)),
        mood: 8,
        pendingSync: false,
      ));

      final pending = await repository.getPendingSyncDailyCheckins();
      expect(pending.length, 1);
      expect(pending.first.mood, 7);
    });

    test('updateServerId updates serverId and clears pendingSync', () async {
      final checkin = await repository.saveDailyCheckin(DailyCheckin(
        date: DateTime.now(),
        mood: 7,
        pendingSync: true,
      ));

      expect(checkin.pendingSync, true);
      expect(checkin.serverId, isNull);

      await repository.updateServerId(checkin.id!, 999);

      final updated = await repository.getDailyCheckinById(checkin.id!);
      expect(updated?.serverId, 999);
      expect(updated?.pendingSync, false);
    });

    test('getDailyCheckinsBefore returns checkins before date', () async {
      await repository.saveDailyCheckin(
          DailyCheckin(date: DateTime(2024, 1, 10), mood: 5));
      await repository.saveDailyCheckin(
          DailyCheckin(date: DateTime(2024, 1, 15), mood: 6));
      await repository.saveDailyCheckin(
          DailyCheckin(date: DateTime(2024, 1, 20), mood: 7));

      final checkins =
          await repository.getDailyCheckinsBefore(DateTime(2024, 1, 18));
      expect(checkins.length, 2);
    });
  });
}
