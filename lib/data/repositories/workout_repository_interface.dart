import '../models/workout.dart';

abstract class WorkoutRepository {
  Future<Workout> saveWorkout(Workout workout);
  Future<Workout?> getWorkoutById(int id);
  Future<void> deleteWorkout(int id);
  Stream<List<Workout>> watchTodayWorkouts();
  Future<List<Workout>> getWorkoutsForDate(DateTime date);
  Future<bool> hasWorkoutsForDate(DateTime date);
  Future<List<Workout>> getWorkoutsBefore(DateTime date, {int limit = 20});
  Future<List<Workout>> getWorkoutsBeforeCursor(
    DateTime date, {
    int? id,
    int limit = 20,
  });
  Future<List<Workout>> getWorkoutsForMonth(int year, int month);
  Future<List<Workout>> getPendingSyncWorkouts();
  Future<void> updateServerId(int localId, int serverId);
}
