import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:v32/data/models/screen_time.dart';
import 'package:v32/data/repositories/local_screen_time_repository.dart';
import 'package:v32/data/repositories/screen_time_repository_interface.dart';
import 'package:v32/data/services/database_service.dart';

void main() {
  group('LocalScreenTimeRepository Integration', () {
    late LocalScreenTimeRepository repository;

    setUp(() async {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
      await DatabaseService.useInMemoryDatabaseForTesting();
      repository = LocalScreenTimeRepository();
    });

    tearDown(() async {
      await DatabaseService.resetForTesting();
    });

    test('implements ScreenTimeRepository', () {
      expect(repository, isA<ScreenTimeRepository>());
    });

    test('full CRUD flow works', () async {
      // Create
      final screenTime = ScreenTime(
        date: DateTime.now(),
        totalMs: 28800000,
        pickups: 50,
      );
      final saved = await repository.saveScreenTime(screenTime);
      expect(saved.id, isNotNull);

      // Read
      final retrieved = await repository.getScreenTimeById(saved.id!);
      expect(retrieved?.totalMs, 28800000);
      expect(retrieved?.pickups, 50);

      // Update
      final updated = saved.copyWith(totalMs: 36000000, pickups: 75);
      final savedUpdated = await repository.saveScreenTime(updated);
      expect(savedUpdated.totalMs, 36000000);
      expect(savedUpdated.pickups, 75);

      // Delete
      await repository.deleteScreenTime(saved.id!);
      final deleted = await repository.getScreenTimeById(saved.id!);
      expect(deleted, isNull);
    });

    test('getScreenTimeForDate returns screen time for specific date', () async {
      final date = DateTime(2024, 1, 15);
      await repository.saveScreenTime(
          ScreenTime(date: date, totalMs: 28800000, pickups: 50));
      await repository.saveScreenTime(ScreenTime(
          date: date.add(Duration(days: 1)), totalMs: 36000000, pickups: 60));

      final screenTime = await repository.getScreenTimeForDate(date);
      expect(screenTime?.totalMs, 28800000);
      expect(screenTime?.pickups, 50);
    });

    test('getScreenTimeForDate returns null if no screen time for date', () async {
      final screenTime =
          await repository.getScreenTimeForDate(DateTime(2024, 1, 15));
      expect(screenTime, isNull);
    });

    test('getScreenTimesForDateRange returns screen times in range', () async {
      await repository.saveScreenTime(
          ScreenTime(date: DateTime(2024, 1, 10), totalMs: 10000000));
      await repository.saveScreenTime(
          ScreenTime(date: DateTime(2024, 1, 15), totalMs: 20000000));
      await repository.saveScreenTime(
          ScreenTime(date: DateTime(2024, 1, 20), totalMs: 30000000));
      await repository.saveScreenTime(
          ScreenTime(date: DateTime(2024, 1, 25), totalMs: 40000000));

      final screenTimes = await repository.getScreenTimesForDateRange(
        DateTime(2024, 1, 12),
        DateTime(2024, 1, 22),
      );
      expect(screenTimes.length, 2);
    });

    test('getPendingSyncScreenTimes returns only pending screen times', () async {
      await repository.saveScreenTime(ScreenTime(
        date: DateTime.now(),
        totalMs: 28800000,
        pendingSync: true,
      ));
      await repository.saveScreenTime(ScreenTime(
        date: DateTime.now().add(Duration(days: 1)),
        totalMs: 36000000,
        pendingSync: false,
      ));

      final pending = await repository.getPendingSyncScreenTimes();
      expect(pending.length, 1);
      expect(pending.first.totalMs, 28800000);
    });

    test('updateServerId updates serverId and clears pendingSync', () async {
      final screenTime = await repository.saveScreenTime(ScreenTime(
        date: DateTime.now(),
        totalMs: 28800000,
        pendingSync: true,
      ));

      expect(screenTime.pendingSync, true);
      expect(screenTime.serverId, isNull);

      await repository.updateServerId(screenTime.id!, 999);

      final updated = await repository.getScreenTimeById(screenTime.id!);
      expect(updated?.serverId, 999);
      expect(updated?.pendingSync, false);
    });

    test('getScreenTimesBefore returns screen times before date', () async {
      await repository.saveScreenTime(
          ScreenTime(date: DateTime(2024, 1, 10), totalMs: 10000000));
      await repository.saveScreenTime(
          ScreenTime(date: DateTime(2024, 1, 15), totalMs: 20000000));
      await repository.saveScreenTime(
          ScreenTime(date: DateTime(2024, 1, 20), totalMs: 30000000));

      final screenTimes =
          await repository.getScreenTimesBefore(DateTime(2024, 1, 18));
      expect(screenTimes.length, 2);
    });

    test('saveScreenTimeApps and getScreenTimeApps work correctly', () async {
      final screenTime = await repository.saveScreenTime(ScreenTime(
        date: DateTime.now(),
        totalMs: 36000000,
      ));

      final apps = [
        ScreenTimeApp(
          screenTimeId: screenTime.id!,
          packageName: 'com.example.app1',
          appName: 'App 1',
          durationMs: 18000000,
        ),
        ScreenTimeApp(
          screenTimeId: screenTime.id!,
          packageName: 'com.example.app2',
          appName: 'App 2',
          durationMs: 18000000,
        ),
      ];

      await repository.saveScreenTimeApps(screenTime.id!, apps);

      final retrievedApps = await repository.getScreenTimeApps(screenTime.id!);
      expect(retrievedApps.length, 2);
      expect(retrievedApps[0].packageName, 'com.example.app1');
      expect(retrievedApps[1].packageName, 'com.example.app2');
    });

    test('saveScreenTimeApps replaces existing apps', () async {
      final screenTime = await repository.saveScreenTime(ScreenTime(
        date: DateTime.now(),
        totalMs: 36000000,
      ));

      // Save initial apps
      await repository.saveScreenTimeApps(screenTime.id!, [
        ScreenTimeApp(
          screenTimeId: screenTime.id!,
          packageName: 'com.example.old',
          appName: 'Old App',
          durationMs: 18000000,
        ),
      ]);

      // Save new apps (should replace)
      await repository.saveScreenTimeApps(screenTime.id!, [
        ScreenTimeApp(
          screenTimeId: screenTime.id!,
          packageName: 'com.example.new',
          appName: 'New App',
          durationMs: 36000000,
        ),
      ]);

      final retrievedApps = await repository.getScreenTimeApps(screenTime.id!);
      expect(retrievedApps.length, 1);
      expect(retrievedApps[0].packageName, 'com.example.new');
    });
  });
}
