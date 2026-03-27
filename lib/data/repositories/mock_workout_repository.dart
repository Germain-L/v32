import '../models/workout.dart';
import 'workout_repository_interface.dart';

/// In-memory implementation of WorkoutRepository for unit testing.
/// Stores data in memory - fast but not persistent.
class MockWorkoutRepository implements WorkoutRepository {
  final Map<int, Workout> _workouts = {};
  int _nextId = 1;

  @override
  Future<Workout> saveWorkout(Workout workout) async {
    if (workout.id == null) {
      final newWorkout = workout.copyWith(id: _nextId++);
      _workouts[newWorkout.id!] = newWorkout;
      return newWorkout;
    } else {
      _workouts[workout.id!] = workout;
      return workout;
    }
  }

  @override
  Future<Workout?> getWorkoutById(int id) async => _workouts[id];

  @override
  Future<void> deleteWorkout(int id) async {
    _workouts.remove(id);
  }

  @override
  Stream<List<Workout>> watchTodayWorkouts() async* {
    yield await getWorkoutsForDate(DateTime.now());
  }

  @override
  Future<List<Workout>> getWorkoutsForDate(DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(Duration(days: 1));

    return _workouts.values
        .where(
          (w) =>
              w.date.isAfter(startOfDay.subtract(Duration(microseconds: 1))) &&
              w.date.isBefore(endOfDay),
        )
        .toList();
  }

  @override
  Future<bool> hasWorkoutsForDate(DateTime date) async {
    final workouts = await getWorkoutsForDate(date);
    return workouts.isNotEmpty;
  }

  @override
  Future<List<Workout>> getWorkoutsBefore(DateTime date, {int limit = 20}) async {
    return _workouts.values
        .where((w) => w.date.isBefore(date))
        .take(limit)
        .toList();
  }

  @override
  Future<List<Workout>> getWorkoutsBeforeCursor(
    DateTime date, {
    int? id,
    int limit = 20,
  }) async {
    return getWorkoutsBefore(date, limit: limit);
  }

  @override
  Future<List<Workout>> getWorkoutsForMonth(int year, int month) async {
    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 1);
    return _workouts.values
        .where(
          (w) =>
              w.date.isAfter(start.subtract(Duration(microseconds: 1))) &&
              w.date.isBefore(end),
        )
        .toList();
  }

  @override
  Future<List<Workout>> getPendingSyncWorkouts() async {
    return _workouts.values.where((w) => w.pendingSync).toList();
  }

  @override
  Future<void> updateServerId(int localId, int serverId) async {
    final workout = _workouts[localId];
    if (workout != null) {
      _workouts[localId] = workout.copyWith(serverId: serverId, pendingSync: false);
    }
  }

  /// Clear all data (useful in tests)
  void clear() {
    _workouts.clear();
    _nextId = 1;
  }
}
