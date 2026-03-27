import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:v32/data/models/workout.dart';
import 'package:v32/data/repositories/local_workout_repository.dart';
import 'package:v32/data/repositories/workout_repository_interface.dart';
import 'package:v32/data/services/database_service.dart';

void main() {
  group('LocalWorkoutRepository Integration', () {
    late LocalWorkoutRepository repository;

    setUp(() async {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
      await DatabaseService.useInMemoryDatabaseForTesting();
      repository = LocalWorkoutRepository();
    });

    tearDown(() async {
      await DatabaseService.resetForTesting();
    });

    test('implements WorkoutRepository', () {
      expect(repository, isA<WorkoutRepository>());
    });

    test('full CRUD flow works', () async {
      // Create
      final workout = Workout(
        type: WorkoutType.run,
        date: DateTime.now(),
        durationSeconds: 1800,
        distanceMeters: 5000.0,
        calories: 300,
      );
      final saved = await repository.saveWorkout(workout);
      expect(saved.id, isNotNull);

      // Read
      final retrieved = await repository.getWorkoutById(saved.id!);
      expect(retrieved?.type, WorkoutType.run);
      expect(retrieved?.durationSeconds, 1800);
      expect(retrieved?.distanceMeters, 5000.0);
      expect(retrieved?.calories, 300);

      // Update
      final updated = saved.copyWith(durationSeconds: 3600, calories: 600);
      final savedUpdated = await repository.saveWorkout(updated);
      expect(savedUpdated.durationSeconds, 3600);
      expect(savedUpdated.calories, 600);

      // Delete
      await repository.deleteWorkout(saved.id!);
      final deleted = await repository.getWorkoutById(saved.id!);
      expect(deleted, isNull);
    });

    test('getWorkoutsForDate returns workouts for specific date', () async {
      final date = DateTime(2024, 1, 15, 10);
      await repository.saveWorkout(Workout(
        type: WorkoutType.run,
        date: date,
      ));
      await repository.saveWorkout(Workout(
        type: WorkoutType.cycle,
        date: date.add(Duration(hours: 2)),
      ));
      // Different date
      await repository.saveWorkout(Workout(
        type: WorkoutType.swim,
        date: DateTime(2024, 1, 16),
      ));

      final workouts = await repository.getWorkoutsForDate(date);
      expect(workouts.length, 2);
    });

    test('hasWorkoutsForDate returns correct boolean', () async {
      final date = DateTime(2024, 1, 15);
      expect(await repository.hasWorkoutsForDate(date), isFalse);

      await repository.saveWorkout(Workout(type: WorkoutType.run, date: date));
      expect(await repository.hasWorkoutsForDate(date), isTrue);
    });

    test('getWorkoutsForMonth returns workouts for specific month', () async {
      await repository.saveWorkout(Workout(
        type: WorkoutType.run,
        date: DateTime(2024, 1, 15),
      ));
      await repository.saveWorkout(Workout(
        type: WorkoutType.cycle,
        date: DateTime(2024, 1, 20),
      ));
      // Different month
      await repository.saveWorkout(Workout(
        type: WorkoutType.swim,
        date: DateTime(2024, 2, 1),
      ));

      final workouts = await repository.getWorkoutsForMonth(2024, 1);
      expect(workouts.length, 2);
    });

    test('getPendingSyncWorkouts returns only pending workouts', () async {
      await repository.saveWorkout(Workout(
        type: WorkoutType.run,
        date: DateTime.now(),
        pendingSync: true,
      ));
      await repository.saveWorkout(Workout(
        type: WorkoutType.cycle,
        date: DateTime.now(),
        pendingSync: false,
      ));

      final pending = await repository.getPendingSyncWorkouts();
      expect(pending.length, 1);
      expect(pending.first.type, WorkoutType.run);
    });

    test('updateServerId updates serverId and clears pendingSync', () async {
      final workout = await repository.saveWorkout(Workout(
        type: WorkoutType.run,
        date: DateTime.now(),
        pendingSync: true,
      ));

      expect(workout.pendingSync, true);
      expect(workout.serverId, isNull);

      await repository.updateServerId(workout.id!, 999);

      final updated = await repository.getWorkoutById(workout.id!);
      expect(updated?.serverId, 999);
      expect(updated?.pendingSync, false);
    });

    test('getWorkoutsBefore returns workouts before date', () async {
      await repository.saveWorkout(Workout(
        type: WorkoutType.run,
        date: DateTime(2024, 1, 10),
      ));
      await repository.saveWorkout(Workout(
        type: WorkoutType.cycle,
        date: DateTime(2024, 1, 15),
      ));
      await repository.saveWorkout(Workout(
        type: WorkoutType.swim,
        date: DateTime(2024, 1, 20),
      ));

      final workouts = await repository.getWorkoutsBefore(DateTime(2024, 1, 18));
      expect(workouts.length, 2);
    });
  });
}
