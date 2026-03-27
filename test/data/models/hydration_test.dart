import 'package:flutter_test/flutter_test.dart';
import 'package:v32/data/models/hydration.dart';

void main() {
  group('Hydration', () {
    test('toMap and fromMap round-trip', () {
      final date = DateTime(2024, 3, 15, 10, 30);
      final createdAt = DateTime(2024, 3, 15, 10, 35);

      final hydration = Hydration(
        id: 42,
        serverId: 100,
        date: date,
        amountMl: 500,
        createdAt: createdAt,
        pendingSync: true,
      );

      final map = hydration.toMap();
      final decoded = Hydration.fromMap(map);

      expect(decoded.id, 42);
      expect(decoded.serverId, 100);
      expect(decoded.date, date);
      expect(decoded.amountMl, 500);
      expect(decoded.createdAt, createdAt);
      expect(decoded.pendingSync, true);
    });

    test('fromJson and toJson round-trip', () {
      final date = DateTime(2024, 3, 15, 14, 0);
      final createdAt = DateTime(2024, 3, 15, 14, 5);

      final json = {
        'id': 100,
        'date': date.millisecondsSinceEpoch,
        'amountMl': 750,
        'createdAt': createdAt.millisecondsSinceEpoch,
      };

      final decoded = Hydration.fromJson(json);
      expect(decoded.serverId, 100);
      expect(decoded.date, date);
      expect(decoded.amountMl, 750);
      expect(decoded.createdAt, createdAt);
      expect(decoded.pendingSync, false);

      final encoded = decoded.toJson();
      expect(encoded['id'], 100);
      expect(encoded['date'], date.millisecondsSinceEpoch);
      expect(encoded['amountMl'], 750);
      expect(encoded['createdAt'], createdAt.millisecondsSinceEpoch);
    });

    test('toJson does not include id if serverId is null', () {
      final hydration = Hydration(
        date: DateTime(2024, 3, 15),
        amountMl: 250,
      );

      final json = hydration.toJson();
      expect(json.containsKey('id'), isFalse);
    });

    test('copyWith updates fields', () {
      final original = Hydration(
        id: 1,
        serverId: 10,
        date: DateTime(2024, 3, 15, 10, 0),
        amountMl: 500,
        pendingSync: false,
      );

      final updated = original.copyWith(
        amountMl: 750,
        pendingSync: true,
      );

      expect(updated.id, 1);
      expect(updated.serverId, 10);
      expect(updated.date, DateTime(2024, 3, 15, 10, 0));
      expect(updated.amountMl, 750);
      expect(updated.pendingSync, true);
    });

    test('copyWith can update all fields', () {
      final original = Hydration(
        id: 1,
        date: DateTime(2024, 3, 15),
        amountMl: 500,
      );

      final updated = original.copyWith(
        id: 2,
        serverId: 20,
        date: DateTime(2024, 3, 16),
        amountMl: 1000,
        pendingSync: true,
      );

      expect(updated.id, 2);
      expect(updated.serverId, 20);
      expect(updated.date, DateTime(2024, 3, 16));
      expect(updated.amountMl, 1000);
      expect(updated.pendingSync, true);
    });

    test('pendingSync defaults to false', () {
      final hydration = Hydration(
        date: DateTime(2024, 3, 15),
        amountMl: 500,
      );

      expect(hydration.pendingSync, false);
    });

    test('fromMap handles missing optional fields', () {
      final map = {
        'id': 1,
        'date': DateTime(2024, 3, 15).millisecondsSinceEpoch,
        'amount_ml': 500,
      };

      final decoded = Hydration.fromMap(map);

      expect(decoded.id, 1);
      expect(decoded.serverId, isNull);
      expect(decoded.pendingSync, false);
    });

    test('pendingSync encoded as integer in toMap', () {
      final hydrationPending = Hydration(
        date: DateTime(2024, 3, 15),
        amountMl: 500,
        pendingSync: true,
      );

      final hydrationNotPending = Hydration(
        date: DateTime(2024, 3, 15),
        amountMl: 500,
        pendingSync: false,
      );

      expect(hydrationPending.toMap()['pending_sync'], 1);
      expect(hydrationNotPending.toMap()['pending_sync'], 0);
    });

    test('amountMl can be zero', () {
      final hydration = Hydration(
        date: DateTime(2024, 3, 15),
        amountMl: 0,
      );

      expect(hydration.amountMl, 0);
    });
  });
}
