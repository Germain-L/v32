import '../models/meal.dart';

/// Abstract interface for meal repository operations.
/// Implementations can use local SQLite, remote REST API, or both.
abstract class MealRepository {
  /// Save a meal (create or update)
  Future<Meal> saveMeal(Meal meal);

  /// Get a meal by its ID
  Future<Meal?> getMealById(int id);

  /// Delete a meal by its ID
  Future<void> deleteMeal(int id);

  /// Watch meals for today as a stream (for reactive UI)
  Stream<List<Meal>> watchTodayMeals();

  /// Get meals for a specific date
  Future<List<Meal>> getMealsForDate(DateTime date);

  /// Check if any meals exist for a date
  Future<bool> hasMealsForDate(DateTime date);

  /// Get meals before a date with pagination
  Future<List<Meal>> getMealsBefore(DateTime date, {int limit = 20});

  /// Get meals before a cursor (date + optional id) for pagination
  Future<List<Meal>> getMealsBeforeCursor(
    DateTime date, {
    int? id,
    int limit = 20,
  });

  /// Get meals for a specific month
  Future<List<Meal>> getMealsForMonth(int year, int month);
}
