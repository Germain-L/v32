import 'package:flutter_test/flutter_test.dart';
import 'package:v32/data/models/daily_checkin.dart';

void main() {
  group('DailyCheckin', () {
    test('toMap and fromMap round-trip', () {
      final date = DateTime(2024, 3, 15);
      final createdAt = DateTime(2024, 3, 15, 8, 0);
      final updatedAt = DateTime(2024, 3, 15, 8, 30);

      final checkin = DailyCheckin(
        id: 42,
        serverId: 100,
        date: date,
        mood: 8,
        energy: 7,
        focus: 6,
        stress: 3,
        sleepHours: 7.5,
        sleepQuality: 8,
        notes: 'Good day overall',
        createdAt: createdAt,
        updatedAt: updatedAt,
        pendingSync: true,
      );

      final map = checkin.toMap();
      final decoded = DailyCheckin.fromMap(map);

      expect(decoded.id, 42);
      expect(decoded.serverId, 100);
      expect(decoded.date, date);
      expect(decoded.mood, 8);
      expect(decoded.energy, 7);
      expect(decoded.focus, 6);
      expect(decoded.stress, 3);
      expect(decoded.sleepHours, 7.5);
      expect(decoded.sleepQuality, 8);
      expect(decoded.notes, 'Good day overall');
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
        'mood': 5,
        'energy': 4,
        'focus': 6,
        'stress': 7,
        'sleepHours': 6.0,
        'sleepQuality': 5,
        'notes': 'Tired today',
        'createdAt': createdAt.millisecondsSinceEpoch,
        'updatedAt': updatedAt.millisecondsSinceEpoch,
      };

      final decoded = DailyCheckin.fromJson(json);
      expect(decoded.serverId, 100);
      expect(decoded.date, date);
      expect(decoded.mood, 5);
      expect(decoded.energy, 4);
      expect(decoded.focus, 6);
      expect(decoded.stress, 7);
      expect(decoded.sleepHours, 6.0);
      expect(decoded.sleepQuality, 5);
      expect(decoded.notes, 'Tired today');
      expect(decoded.createdAt, createdAt);
      expect(decoded.updatedAt, updatedAt);
      expect(decoded.pendingSync, false);

      final encoded = decoded.toJson();
      expect(encoded['id'], 100);
      expect(encoded['date'], date.millisecondsSinceEpoch);
      expect(encoded['mood'], 5);
      expect(encoded['energy'], 4);
      expect(encoded['focus'], 6);
      expect(encoded['stress'], 7);
      expect(encoded['sleepHours'], 6.0);
      expect(encoded['sleepQuality'], 5);
      expect(encoded['notes'], 'Tired today');
      expect(encoded['createdAt'], createdAt.millisecondsSinceEpoch);
      expect(encoded['updatedAt'], updatedAt.millisecondsSinceEpoch);
    });

    test('toJson does not include id if serverId is null', () {
      final checkin = DailyCheckin(
        date: DateTime(2024, 3, 15),
        mood: 7,
      );

      final json = checkin.toJson();
      expect(json.containsKey('id'), isFalse);
    });

    test('copyWith updates fields', () {
      final original = DailyCheckin(
        id: 1,
        serverId: 10,
        date: DateTime(2024, 3, 15),
        mood: 5,
        energy: 5,
        focus: 5,
        stress: 5,
        sleepHours: 7.0,
        sleepQuality: 5,
        notes: 'Original notes',
        pendingSync: false,
      );

      final updated = original.copyWith(
        mood: 8,
        energy: 7,
        stress: 2,
        notes: 'Updated notes',
        pendingSync: true,
      );

      expect(updated.id, 1);
      expect(updated.serverId, 10);
      expect(updated.date, DateTime(2024, 3, 15));
      expect(updated.mood, 8);
      expect(updated.energy, 7);
      expect(updated.focus, 5);
      expect(updated.stress, 2);
      expect(updated.sleepHours, 7.0);
      expect(updated.sleepQuality, 5);
      expect(updated.notes, 'Updated notes');
      expect(updated.pendingSync, true);
    });


    test('nullable fields can be null', () {
      final checkin = DailyCheckin(
        date: DateTime(2024, 3, 15),
      );

      expect(checkin.mood, isNull);
      expect(checkin.energy, isNull);
      expect(checkin.focus, isNull);
      expect(checkin.stress, isNull);
      expect(checkin.sleepHours, isNull);
      expect(checkin.sleepQuality, isNull);
      expect(checkin.notes, isNull);
    });

    test('pendingSync defaults to false', () {
      final checkin = DailyCheckin(
        date: DateTime(2024, 3, 15),
      );

      expect(checkin.pendingSync, false);
    });

    test('fromMap handles missing optional fields', () {
      final map = {
        'id': 1,
        'date': DateTime(2024, 3, 15).millisecondsSinceEpoch,
      };

      final decoded = DailyCheckin.fromMap(map);

      expect(decoded.id, 1);
      expect(decoded.serverId, isNull);
      expect(decoded.mood, isNull);
      expect(decoded.energy, isNull);
      expect(decoded.focus, isNull);
      expect(decoded.stress, isNull);
      expect(decoded.sleepHours, isNull);
      expect(decoded.sleepQuality, isNull);
      expect(decoded.notes, isNull);
      expect(decoded.pendingSync, false);
    });

    test('pendingSync encoded as integer in toMap', () {
      final checkinPending = DailyCheckin(
        date: DateTime(2024, 3, 15),
        pendingSync: true,
      );

      final checkinNotPending = DailyCheckin(
        date: DateTime(2024, 3, 15),
        pendingSync: false,
      );

      expect(checkinPending.toMap()['pending_sync'], 1);
      expect(checkinNotPending.toMap()['pending_sync'], 0);
    });
  });
}
