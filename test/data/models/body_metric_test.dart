import 'package:flutter_test/flutter_test.dart';
import 'package:v32/data/models/body_metric.dart';

void main() {
  group('BodyMetric', () {
    test('toMap and fromMap round-trip', () {
      final date = DateTime(2024, 3, 15);
      final createdAt = DateTime(2024, 3, 15, 8, 0);
      final updatedAt = DateTime(2024, 3, 15, 8, 30);

      final bodyMetric = BodyMetric(
        id: 42,
        serverId: 100,
        date: date,
        weight: 75.5,
        bodyFat: 18.2,
        notes: 'Morning measurement',
        createdAt: createdAt,
        updatedAt: updatedAt,
        pendingSync: true,
      );

      final map = bodyMetric.toMap();
      final decoded = BodyMetric.fromMap(map);

      expect(decoded.id, 42);
      expect(decoded.serverId, 100);
      expect(decoded.date, date);
      expect(decoded.weight, 75.5);
      expect(decoded.bodyFat, 18.2);
      expect(decoded.notes, 'Morning measurement');
      expect(decoded.createdAt, createdAt);
      expect(decoded.updatedAt, updatedAt);
      expect(decoded.pendingSync, true);
    });

    test('fromJson and toJson round-trip', () {
      final date = DateTime(2024, 3, 15);
      final createdAt = DateTime(2024, 3, 15, 8, 0);
      final updatedAt = DateTime(2024, 3, 15, 8, 30);

      final json = {
        'id': 100,
        'date': date.millisecondsSinceEpoch,
        'weight': 80.0,
        'bodyFat': 15.5,
        'notes': 'Evening measurement',
        'createdAt': createdAt.millisecondsSinceEpoch,
        'updatedAt': updatedAt.millisecondsSinceEpoch,
      };

      final decoded = BodyMetric.fromJson(json);
      expect(decoded.serverId, 100);
      expect(decoded.date, date);
      expect(decoded.weight, 80.0);
      expect(decoded.bodyFat, 15.5);
      expect(decoded.notes, 'Evening measurement');
      expect(decoded.createdAt, createdAt);
      expect(decoded.updatedAt, updatedAt);
      expect(decoded.pendingSync, false);

      final encoded = decoded.toJson();
      expect(encoded['id'], 100);
      expect(encoded['date'], date.millisecondsSinceEpoch);
      expect(encoded['weight'], 80.0);
      expect(encoded['bodyFat'], 15.5);
      expect(encoded['notes'], 'Evening measurement');
      expect(encoded['createdAt'], createdAt.millisecondsSinceEpoch);
      expect(encoded['updatedAt'], updatedAt.millisecondsSinceEpoch);
    });

    test('toJson does not include id if serverId is null', () {
      final bodyMetric = BodyMetric(
        date: DateTime(2024, 3, 15),
        weight: 75.5,
      );

      final json = bodyMetric.toJson();
      expect(json.containsKey('id'), isFalse);
    });

    test('copyWith updates fields', () {
      final original = BodyMetric(
        id: 1,
        serverId: 10,
        date: DateTime(2024, 3, 15),
        weight: 75.0,
        bodyFat: 18.0,
        notes: 'Original notes',
        pendingSync: false,
      );

      final updated = original.copyWith(
        weight: 74.5,
        bodyFat: 17.5,
        notes: 'Updated notes',
        pendingSync: true,
      );

      expect(updated.id, 1);
      expect(updated.serverId, 10);
      expect(updated.date, DateTime(2024, 3, 15));
      expect(updated.weight, 74.5);
      expect(updated.bodyFat, 17.5);
      expect(updated.notes, 'Updated notes');
      expect(updated.pendingSync, true);
    });


    test('pendingSync defaults to false', () {
      final bodyMetric = BodyMetric(
        date: DateTime(2024, 3, 15),
      );

      expect(bodyMetric.pendingSync, false);
    });

    test('fromMap handles missing optional fields', () {
      final map = {
        'id': 1,
        'date': DateTime(2024, 3, 15).millisecondsSinceEpoch,
      };

      final decoded = BodyMetric.fromMap(map);

      expect(decoded.id, 1);
      expect(decoded.serverId, isNull);
      expect(decoded.weight, isNull);
      expect(decoded.bodyFat, isNull);
      expect(decoded.notes, isNull);
      expect(decoded.pendingSync, false);
    });

    test('pendingSync encoded as integer in toMap', () {
      final bodyMetricPending = BodyMetric(
        date: DateTime(2024, 3, 15),
        pendingSync: true,
      );

      final bodyMetricNotPending = BodyMetric(
        date: DateTime(2024, 3, 15),
        pendingSync: false,
      );

      expect(bodyMetricPending.toMap()['pending_sync'], 1);
      expect(bodyMetricNotPending.toMap()['pending_sync'], 0);
    });
  });
}
