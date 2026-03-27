import 'daily_metrics_repository_interface.dart';
import 'day_rating_repository_interface.dart';
import 'daily_checkin_repository_interface.dart';
import 'workout_repository_interface.dart';
import 'body_metric_repository_interface.dart';
import 'screen_time_repository_interface.dart';
import 'hydration_repository_interface.dart';
import 'local_daily_metrics_repository.dart';
import 'local_day_rating_repository.dart';
import 'local_daily_checkin_repository.dart';
import 'local_workout_repository.dart';
import 'local_body_metric_repository.dart';
import 'local_screen_time_repository.dart';
import 'local_hydration_repository.dart';
import 'remote_meal_repository.dart';
import 'syncing_daily_checkin_repository.dart';
import 'syncing_workout_repository.dart';
import 'syncing_body_metric_repository.dart';
import 'syncing_screen_time_repository.dart';
import 'syncing_hydration_repository.dart';
import 'meal_repository_interface.dart';

/// Factory for repository instances.
/// Allows injection of mock/test implementations.
class RepositoryFactory {
  static final RepositoryFactory _instance = RepositoryFactory._internal();

  factory RepositoryFactory() => _instance;
  RepositoryFactory._internal();

  MealRepository? _mealRepository;
  DailyMetricsRepository? _dailyMetricsRepository;
  DayRatingRepository? _dayRatingRepository;
  DailyCheckinRepository? _dailyCheckinRepository;
  WorkoutRepository? _workoutRepository;
  BodyMetricRepository? _bodyMetricRepository;
  ScreenTimeRepository? _screenTimeRepository;
  HydrationRepository? _hydrationRepository;

  /// Use remote-first repository by default
  MealRepository getMealRepository() {
    _mealRepository ??= RemoteMealRepository.withSync();
    return _mealRepository!;
  }

  void setMealRepository(MealRepository repository) {
    _mealRepository = repository;
  }

  DailyMetricsRepository getDailyMetricsRepository() {
    _dailyMetricsRepository ??= LocalDailyMetricsRepository();
    return _dailyMetricsRepository!;
  }

  void setDailyMetricsRepository(DailyMetricsRepository repository) {
    _dailyMetricsRepository = repository;
  }

  DayRatingRepository getDayRatingRepository() {
    _dayRatingRepository ??= LocalDayRatingRepository();
    return _dayRatingRepository!;
  }

  void setDayRatingRepository(DayRatingRepository repository) {
    _dayRatingRepository = repository;
  }

  DailyCheckinRepository getDailyCheckinRepository() {
    _dailyCheckinRepository ??= SyncingDailyCheckinRepository();
    return _dailyCheckinRepository!;
  }

  void setDailyCheckinRepository(DailyCheckinRepository repository) {
    _dailyCheckinRepository = repository;
  }

  WorkoutRepository getWorkoutRepository() {
    _workoutRepository ??= SyncingWorkoutRepository();
    return _workoutRepository!;
  }

  void setWorkoutRepository(WorkoutRepository repository) {
    _workoutRepository = repository;
  }

  BodyMetricRepository getBodyMetricRepository() {
    _bodyMetricRepository ??= SyncingBodyMetricRepository();
    return _bodyMetricRepository!;
  }

  void setBodyMetricRepository(BodyMetricRepository repository) {
    _bodyMetricRepository = repository;
  }

  ScreenTimeRepository getScreenTimeRepository() {
    _screenTimeRepository ??= SyncingScreenTimeRepository();
    return _screenTimeRepository!;
  }

  void setScreenTimeRepository(ScreenTimeRepository repository) {
    _screenTimeRepository = repository;
  }

  HydrationRepository getHydrationRepository() {
    _hydrationRepository ??= SyncingHydrationRepository();
    return _hydrationRepository!;
  }

  void setHydrationRepository(HydrationRepository repository) {
    _hydrationRepository = repository;
  }

  /// Reset all repositories (useful in tests)
  void reset() {
    _mealRepository = null;
    _dailyMetricsRepository = null;
    _dayRatingRepository = null;
    _dailyCheckinRepository = null;
    _workoutRepository = null;
    _bodyMetricRepository = null;
    _screenTimeRepository = null;
    _hydrationRepository = null;
  }
}
