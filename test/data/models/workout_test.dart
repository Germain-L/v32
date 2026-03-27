import 'package:flutter_test/flutter_test.dart';
import 'package:v32/data/models/workout.dart';

void main() {
  group('WorkoutType', () {
    test('displayName maps to labels', () {
      expect(WorkoutType.run.displayName, 'Run');
      expect(WorkoutType.cycle.displayName, 'Cycle');
      expect(WorkoutType.gym.displayName, 'Gym');
      expect(WorkoutType.swim.displayName, 'Swim');
      expect(WorkoutType.walk.displayName, 'Walk');
      expect(WorkoutType.hiking.displayName, 'Hiking');
      expect(WorkoutType.other.displayName, 'Other');
    });
  });

  group('Workout', () {
    test('toMap and fromMap round-trip', () {
      final date = DateTime(2024, 3, 15, 10, 30);
      final createdAt = DateTime(2024, 3, 15, 11, 0);
      final updatedAt = DateTime(2024, 3, 15, 12, 0);

      final workout = Workout(
        id: 42,
        serverId: 100,
        type: WorkoutType.cycle,
        date: date,
        durationSeconds: 3600,
        distanceMeters: 25000.5,
        calories: 450,
        heartRateAvg: 140,
        heartRateMax: 175,
        notes: 'Morning ride',
        source: 'strava',
        sourceId: 'strava_123',
        stravaData: '{"external_id": "123"}',
        createdAt: createdAt,
        updatedAt: updatedAt,
        pendingSync: true,
      );

      final map = workout.toMap();
      final decoded = Workout.fromMap(map);

      expect(decoded.id, 42);
      expect(decoded.serverId, 100);
      expect(decoded.type, WorkoutType.cycle);
      expect(decoded.date, date);
      expect(decoded.durationSeconds, 3600);
      expect(decoded.distanceMeters, 25000.5);
      expect(decoded.calories, 450);
      expect(decoded.heartRateAvg, 140);
      expect(decoded.heartRateMax, 175);
      expect(decoded.notes, 'Morning ride');
      expect(decoded.source, 'strava');
      expect(decoded.sourceId, 'strava_123');
      expect(decoded.stravaData, '{"external_id": "123"}');
      expect(decoded.createdAt, createdAt);
      expect(decoded.updatedAt, updatedAt);
      expect(decoded.pendingSync, true);
    });

    test('fromJson and toJson round-trip', () {
      final date = DateTime(2024, 3, 15, 10, 30);
      final createdAt = DateTime(2024, 3, 15, 11, 0);
      final updatedAt = DateTime(2024, 3, 15, 12, 0);

      final json = {
        'id': 100,
        'type': 'run',
        'date': date.millisecondsSinceEpoch,
        'durationSeconds': 1800,
        'distanceMeters': 5000.0,
        'calories': 300,
        'heartRateAvg': 150,
        'heartRateMax': 180,
        'notes': 'Evening run',
        'source': 'garmin',
        'sourceId': 'garmin_456',
        'stravaData': '{"activity_id": 456}',
        'createdAt': createdAt.millisecondsSinceEpoch,
        'updatedAt': updatedAt.millisecondsSinceEpoch,
      };

      final decoded = Workout.fromJson(json);
      expect(decoded.serverId, 100);
      expect(decoded.type, WorkoutType.run);
      expect(decoded.date, date);
      expect(decoded.durationSeconds, 1800);
      expect(decoded.distanceMeters, 5000.0);
      expect(decoded.calories, 300);
      expect(decoded.heartRateAvg, 150);
      expect(decoded.heartRateMax, 180);
      expect(decoded.notes, 'Evening run');
      expect(decoded.source, 'garmin');
      expect(decoded.sourceId, 'garmin_456');
      expect(decoded.stravaData, '{"activity_id": 456}');
      expect(decoded.createdAt, createdAt);
      expect(decoded.updatedAt, updatedAt);
      expect(decoded.pendingSync, false);

      final encoded = decoded.toJson();
      expect(encoded['id'], 100);
      expect(encoded['type'], 'run');
      expect(encoded['date'], date.millisecondsSinceEpoch);
      expect(encoded['durationSeconds'], 1800);
      expect(encoded['distanceMeters'], 5000.0);
      expect(encoded['calories'], 300);
      expect(encoded['heartRateAvg'], 150);
      expect(encoded['heartRateMax'], 180);
      expect(encoded['notes'], 'Evening run');
      expect(encoded['source'], 'garmin');
      expect(encoded['sourceId'], 'garmin_456');
      expect(encoded['stravaData'], '{"activity_id": 456}');
      expect(encoded['createdAt'], createdAt.millisecondsSinceEpoch);
      expect(encoded['updatedAt'], updatedAt.millisecondsSinceEpoch);
    });

    test('toJson does not include id if serverId is null', () {
      final workout = Workout(
        type: WorkoutType.walk,
        date: DateTime(2024, 3, 15),
      );

      final json = workout.toJson();
      expect(json.containsKey('id'), isFalse);
    });

    test('copyWith updates fields', () {
      final original = Workout(
        id: 1,
        serverId: 10,
        type: WorkoutType.run,
        date: DateTime(2024, 3, 15),
        durationSeconds: 1800,
        distanceMeters: 5000.0,
        calories: 300,
        heartRateAvg: 150,
        heartRateMax: 180,
        notes: 'Original notes',
        source: 'manual',
        sourceId: 'source_1',
        stravaData: null,
        pendingSync: false,
      );

      final updated = original.copyWith(
        type: WorkoutType.cycle,
        durationSeconds: 3600,
        notes: 'Updated notes',
        pendingSync: true,
      );

      expect(updated.id, 1);
      expect(updated.serverId, 10);
      expect(updated.type, WorkoutType.cycle);
      expect(updated.durationSeconds, 3600);
      expect(updated.distanceMeters, 5000.0);
      expect(updated.calories, 300);
      expect(updated.heartRateAvg, 150);
      expect(updated.heartRateMax, 180);
      expect(updated.notes, 'Updated notes');
      expect(updated.source, 'manual');
      expect(updated.sourceId, 'source_1');
      expect(updated.stravaData, isNull);
      expect(updated.pendingSync, true);
    });


    test('pendingSync field defaults to false', () {
      final workout = Workout(
        type: WorkoutType.run,
        date: DateTime(2024, 3, 15),
      );

      expect(workout.pendingSync, false);
    });

    test('fromMap handles missing optional fields', () {
      final map = {
        'id': 1,
        'type': 'run',
        'date': DateTime(2024, 3, 15).millisecondsSinceEpoch,
        'source': 'manual',
      };

      final decoded = Workout.fromMap(map);

      expect(decoded.id, 1);
      expect(decoded.type, WorkoutType.run);
      expect(decoded.serverId, isNull);
      expect(decoded.durationSeconds, isNull);
      expect(decoded.distanceMeters, isNull);
      expect(decoded.calories, isNull);
      expect(decoded.heartRateAvg, isNull);
      expect(decoded.heartRateMax, isNull);
      expect(decoded.notes, isNull);
      expect(decoded.sourceId, isNull);
      expect(decoded.stravaData, isNull);
      expect(decoded.pendingSync, false);
    });

    test('pendingSync encoded as integer in toMap', () {
      final workoutPending = Workout(
        type: WorkoutType.run,
        date: DateTime(2024, 3, 15),
        pendingSync: true,
      );

      final workoutNotPending = Workout(
        type: WorkoutType.run,
        date: DateTime(2024, 3, 15),
        pendingSync: false,
      );

      expect(workoutPending.toMap()['pending_sync'], 1);
      expect(workoutNotPending.toMap()['pending_sync'], 0);
    });
  });
}
