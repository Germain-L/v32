import 'package:flutter_test/flutter_test.dart';
import 'package:v32/data/models/screen_time.dart';

void main() {
  group('ScreenTimeApp', () {
    test('toMap and fromMap round-trip', () {
      final app = ScreenTimeApp(
        id: 42,
        serverId: 100,
        screenTimeId: 1,
        packageName: 'com.example.app',
        appName: 'Example App',
        durationMs: 3600000,
      );

      final map = app.toMap();
      final decoded = ScreenTimeApp.fromMap(map);

      expect(decoded.id, 42);
      expect(decoded.serverId, 100);
      expect(decoded.screenTimeId, 1);
      expect(decoded.packageName, 'com.example.app');
      expect(decoded.appName, 'Example App');
      expect(decoded.durationMs, 3600000);
    });

    test('fromJson and toJson round-trip', () {
      final json = {
        'id': 100,
        'screenTimeId': 2,
        'packageName': 'com.example.app2',
        'appName': 'Example App 2',
        'durationMs': 7200000,
      };

      final decoded = ScreenTimeApp.fromJson(json);
      expect(decoded.serverId, 100);
      expect(decoded.screenTimeId, 2);
      expect(decoded.packageName, 'com.example.app2');
      expect(decoded.appName, 'Example App 2');
      expect(decoded.durationMs, 7200000);

      final encoded = decoded.toJson();
      expect(encoded['id'], 100);
      expect(encoded['screenTimeId'], 2);
      expect(encoded['packageName'], 'com.example.app2');
      expect(encoded['appName'], 'Example App 2');
      expect(encoded['durationMs'], 7200000);
    });

    test('toJson does not include id if serverId is null', () {
      final app = ScreenTimeApp(
        screenTimeId: 1,
        packageName: 'com.example.app',
        appName: 'Example App',
        durationMs: 1000,
      );

      final json = app.toJson();
      expect(json.containsKey('id'), isFalse);
    });

    test('copyWith updates fields', () {
      final original = ScreenTimeApp(
        id: 1,
        serverId: 10,
        screenTimeId: 5,
        packageName: 'com.original.app',
        appName: 'Original App',
        durationMs: 1000,
      );

      final updated = original.copyWith(
        appName: 'Updated App',
        durationMs: 2000,
      );

      expect(updated.id, 1);
      expect(updated.serverId, 10);
      expect(updated.screenTimeId, 5);
      expect(updated.packageName, 'com.original.app');
      expect(updated.appName, 'Updated App');
      expect(updated.durationMs, 2000);
    });
  });

  group('ScreenTime', () {
    test('toMap and fromMap round-trip', () {
      final date = DateTime(2024, 3, 15);
      final createdAt = DateTime(2024, 3, 15, 23, 59);

      final screenTime = ScreenTime(
        id: 42,
        serverId: 100,
        date: date,
        totalMs: 28800000,
        pickups: 50,
        createdAt: createdAt,
        pendingSync: true,
      );

      final map = screenTime.toMap();
      final decoded = ScreenTime.fromMap(map);

      expect(decoded.id, 42);
      expect(decoded.serverId, 100);
      expect(decoded.date, date);
      expect(decoded.totalMs, 28800000);
      expect(decoded.pickups, 50);
      expect(decoded.createdAt, createdAt);
      expect(decoded.pendingSync, true);
      expect(decoded.apps, isEmpty);
    });

    test('fromJson with nested apps list', () {
      final date = DateTime(2024, 3, 15);
      final createdAt = DateTime(2024, 3, 15, 23, 59);

      final json = {
        'id': 100,
        'date': date.millisecondsSinceEpoch,
        'totalMs': 36000000,
        'pickups': 75,
        'createdAt': createdAt.millisecondsSinceEpoch,
        'apps': [
          {
            'id': 1,
            'screenTimeId': 100,
            'packageName': 'com.example.app1',
            'appName': 'App 1',
            'durationMs': 18000000,
          },
          {
            'id': 2,
            'screenTimeId': 100,
            'packageName': 'com.example.app2',
            'appName': 'App 2',
            'durationMs': 18000000,
          },
        ],
      };

      final decoded = ScreenTime.fromJson(json);

      expect(decoded.serverId, 100);
      expect(decoded.date, date);
      expect(decoded.totalMs, 36000000);
      expect(decoded.pickups, 75);
      expect(decoded.createdAt, createdAt);
      expect(decoded.pendingSync, false);
      expect(decoded.apps.length, 2);
      expect(decoded.apps[0].serverId, 1);
      expect(decoded.apps[0].packageName, 'com.example.app1');
      expect(decoded.apps[0].appName, 'App 1');
      expect(decoded.apps[0].durationMs, 18000000);
      expect(decoded.apps[1].serverId, 2);
      expect(decoded.apps[1].packageName, 'com.example.app2');
      expect(decoded.apps[1].appName, 'App 2');
      expect(decoded.apps[1].durationMs, 18000000);
    });

    test('fromJson handles missing apps list', () {
      final date = DateTime(2024, 3, 15);

      final json = {
        'id': 100,
        'date': date.millisecondsSinceEpoch,
        'totalMs': 36000000,
      };

      final decoded = ScreenTime.fromJson(json);

      expect(decoded.apps, isEmpty);
    });

    test('toJson includes apps list', () {
      final screenTime = ScreenTime(
        serverId: 100,
        date: DateTime(2024, 3, 15),
        totalMs: 36000000,
        apps: [
          ScreenTimeApp(
            serverId: 1,
            screenTimeId: 100,
            packageName: 'com.example.app',
            appName: 'App',
            durationMs: 18000000,
          ),
        ],
      );

      final json = screenTime.toJson();

      expect(json['apps'], isA<List>());
      expect((json['apps'] as List).length, 1);
      expect(json['apps'][0]['packageName'], 'com.example.app');
    });

    test('toJson does not include id if serverId is null', () {
      final screenTime = ScreenTime(
        date: DateTime(2024, 3, 15),
        totalMs: 1000,
      );

      final json = screenTime.toJson();
      expect(json.containsKey('id'), isFalse);
    });

    test('copyWith updates fields', () {
      final original = ScreenTime(
        id: 1,
        serverId: 10,
        date: DateTime(2024, 3, 15),
        totalMs: 10000,
        pickups: 20,
        pendingSync: false,
      );

      final updated = original.copyWith(
        totalMs: 20000,
        pickups: 40,
        pendingSync: true,
      );

      expect(updated.id, 1);
      expect(updated.serverId, 10);
      expect(updated.date, DateTime(2024, 3, 15));
      expect(updated.totalMs, 20000);
      expect(updated.pickups, 40);
      expect(updated.pendingSync, true);
    });

    test('copyWith updates apps list', () {
      final original = ScreenTime(
        id: 1,
        date: DateTime(2024, 3, 15),
        totalMs: 10000,
        apps: [
          ScreenTimeApp(
            screenTimeId: 1,
            packageName: 'com.example.app1',
            appName: 'App 1',
            durationMs: 5000,
          ),
        ],
      );

      final updated = original.copyWith(
        totalMs: 15000,
        apps: [
          ScreenTimeApp(
            screenTimeId: 1,
            packageName: 'com.example.app1',
            appName: 'App 1',
            durationMs: 7500,
          ),
          ScreenTimeApp(
            screenTimeId: 1,
            packageName: 'com.example.app2',
            appName: 'App 2',
            durationMs: 7500,
          ),
        ],
      );

      expect(updated.apps.length, 2);
      expect(updated.totalMs, 15000);
    });

    test('pendingSync defaults to false', () {
      final screenTime = ScreenTime(
        date: DateTime(2024, 3, 15),
        totalMs: 1000,
      );

      expect(screenTime.pendingSync, false);
    });

    test('fromMap handles missing optional fields', () {
      final map = {
        'id': 1,
        'date': DateTime(2024, 3, 15).millisecondsSinceEpoch,
        'total_ms': 10000,
      };

      final decoded = ScreenTime.fromMap(map);

      expect(decoded.id, 1);
      expect(decoded.serverId, isNull);
      expect(decoded.pickups, isNull);
      expect(decoded.pendingSync, false);
      expect(decoded.apps, isEmpty);
    });

    test('pendingSync encoded as integer in toMap', () {
      final screenTimePending = ScreenTime(
        date: DateTime(2024, 3, 15),
        totalMs: 1000,
        pendingSync: true,
      );

      final screenTimeNotPending = ScreenTime(
        date: DateTime(2024, 3, 15),
        totalMs: 1000,
        pendingSync: false,
      );

      expect(screenTimePending.toMap()['pending_sync'], 1);
      expect(screenTimeNotPending.toMap()['pending_sync'], 0);
    });
  });
}
