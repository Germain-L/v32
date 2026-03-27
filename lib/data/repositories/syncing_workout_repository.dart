import 'dart:developer' as dev;
import '../models/workout.dart';
import 'local_workout_repository.dart';
import 'workout_repository_interface.dart';

/// A workout repository that syncs to the backend.
/// Wraps LocalWorkoutRepository and adds sync functionality.
class SyncingWorkoutRepository implements WorkoutRepository {
  final LocalWorkoutRepository _localRepo;

  SyncingWorkoutRepository({
    LocalWorkoutRepository? localRepo,
  }) : _localRepo = localRepo ?? LocalWorkoutRepository();

  static void _log(String message) {
    dev.log('[SYNCING_WORKOUT_REPO] $message', name: 'v32');
  }

  @override
  Future<Workout> saveWorkout(Workout workout) async {
    _log('saveWorkout called: type=${workout.type.name}, id=${workout.id}');

    // Save locally first
    final saved = await _localRepo.saveWorkout(workout);
    _log('Workout saved locally: id=${saved.id}');

    // TODO: Trigger sync when backend endpoints are available

    return saved;
  }

  @override
  Future<Workout?> getWorkoutById(int id) => _localRepo.getWorkoutById(id);

  @override
  Future<void> deleteWorkout(int id) async {
    _log('deleteWorkout called: id=$id');
    await _localRepo.deleteWorkout(id);
  }

  @override
  Stream<List<Workout>> watchTodayWorkouts() => _localRepo.watchTodayWorkouts();

  @override
  Future<List<Workout>> getWorkoutsForDate(DateTime date) =>
      _localRepo.getWorkoutsForDate(date);

  @override
  Future<bool> hasWorkoutsForDate(DateTime date) =>
      _localRepo.hasWorkoutsForDate(date);

  @override
  Future<List<Workout>> getWorkoutsBefore(DateTime date, {int limit = 20}) =>
      _localRepo.getWorkoutsBefore(date, limit: limit);

  @override
  Future<List<Workout>> getWorkoutsBeforeCursor(
    DateTime date, {
    int? id,
    int limit = 20,
  }) => _localRepo.getWorkoutsBeforeCursor(date, id: id, limit: limit);

  @override
  Future<List<Workout>> getWorkoutsForMonth(int year, int month) =>
      _localRepo.getWorkoutsForMonth(year, month);

  @override
  Future<List<Workout>> getPendingSyncWorkouts() =>
      _localRepo.getPendingSyncWorkouts();

  @override
  Future<void> updateServerId(int localId, int serverId) =>
      _localRepo.updateServerId(localId, serverId);
}
