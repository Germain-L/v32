import 'dart:developer' as dev;
import '../models/workout.dart';
import 'local_workout_repository.dart';
import 'workout_repository_interface.dart';

/// A workout repository that treats the backend as source of truth.
/// Local storage acts as a cache.
/// Handles offline gracefully by queuing changes for later sync.
class RemoteWorkoutRepository implements WorkoutRepository {
  final LocalWorkoutRepository _cache;

  RemoteWorkoutRepository({
    LocalWorkoutRepository? cache,
  }) : _cache = cache ?? LocalWorkoutRepository();

  static void _log(String message) {
    dev.log('[REMOTE_WORKOUT_REPO] $message', name: 'v32');
  }

  @override
  Future<Workout> saveWorkout(Workout workout) async {
    _log('saveWorkout: type=${workout.type.name}, id=${workout.id}');

    // Save to cache with pendingSync=true
    final workoutToSave = workout.copyWith(
      updatedAt: DateTime.now(),
      pendingSync: true,
    );

    final saved = await _cache.saveWorkout(workoutToSave);
    _log('Workout saved to cache: id=${saved.id}, pendingSync=true');

    // TODO: Trigger sync when backend endpoints are available

    return saved;
  }

  @override
  Future<Workout?> getWorkoutById(int id) => _cache.getWorkoutById(id);

  @override
  Future<void> deleteWorkout(int id) async {
    _log('deleteWorkout: id=$id');
    await _cache.deleteWorkout(id);
  }

  @override
  Stream<List<Workout>> watchTodayWorkouts() => _cache.watchTodayWorkouts();

  @override
  Future<List<Workout>> getWorkoutsForDate(DateTime date) =>
      _cache.getWorkoutsForDate(date);

  @override
  Future<bool> hasWorkoutsForDate(DateTime date) =>
      _cache.hasWorkoutsForDate(date);

  @override
  Future<List<Workout>> getWorkoutsBefore(DateTime date, {int limit = 20}) =>
      _cache.getWorkoutsBefore(date, limit: limit);

  @override
  Future<List<Workout>> getWorkoutsBeforeCursor(
    DateTime date, {
    int? id,
    int limit = 20,
  }) => _cache.getWorkoutsBeforeCursor(date, id: id, limit: limit);

  @override
  Future<List<Workout>> getWorkoutsForMonth(int year, int month) =>
      _cache.getWorkoutsForMonth(year, month);

  @override
  Future<List<Workout>> getPendingSyncWorkouts() =>
      _cache.getPendingSyncWorkouts();

  @override
  Future<void> updateServerId(int localId, int serverId) =>
      _cache.updateServerId(localId, serverId);
}
