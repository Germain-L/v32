import 'daily_metrics_repository_interface.dart';
import 'day_rating_repository_interface.dart';
import 'local_daily_metrics_repository.dart';
import 'local_day_rating_repository.dart';
import 'meal_repository_interface.dart';
import 'syncing_meal_repository.dart';

/// Factory for repository instances.
/// Allows injection of mock/test implementations.
class RepositoryFactory {
  static final RepositoryFactory _instance = RepositoryFactory._internal();

  factory RepositoryFactory() => _instance;
  RepositoryFactory._internal();

  MealRepository? _mealRepository;
  DailyMetricsRepository? _dailyMetricsRepository;
  DayRatingRepository? _dayRatingRepository;

  MealRepository getMealRepository() {
    _mealRepository ??= SyncingMealRepository.withSync();
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

  /// Reset all repositories (useful in tests)
  void reset() {
    _mealRepository = null;
    _dailyMetricsRepository = null;
    _dayRatingRepository = null;
  }
}
