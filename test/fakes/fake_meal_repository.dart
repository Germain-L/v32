import 'package:diet/data/models/meal.dart';
import 'package:diet/data/repositories/meal_repository.dart';

class FakeMealRepository extends MealRepository {
  FakeMealRepository({
    List<Meal>? seedMeals,
    this.throwOnSaveMeal = false,
    this.throwOnDeleteMeal = false,
    this.throwOnGetMealsForDate = false,
    this.throwOnGetMealsBeforeCursor = false,
    this.throwOnGetMealsForMonth = false,
  }) : _meals = [...?seedMeals] {
    if (_meals.isNotEmpty) {
      _nextId =
          _meals
              .map((meal) => meal.id ?? 0)
              .fold<int>(0, (maxId, id) => id > maxId ? id : maxId) +
          1;
    }
  }

  final List<Meal> _meals;
  int _nextId = 1;
  final bool throwOnSaveMeal;
  final bool throwOnDeleteMeal;
  final bool throwOnGetMealsForDate;
  final bool throwOnGetMealsBeforeCursor;
  final bool throwOnGetMealsForMonth;

  List<Meal> get meals => List.unmodifiable(_meals);

  @override
  Future<Meal> saveMeal(Meal meal) async {
    if (throwOnSaveMeal) {
      throw Exception('saveMeal failed');
    }
    if (meal.id == null) {
      final saved = meal.copyWith(id: _nextId++);
      _meals.add(saved);
      return saved;
    }

    final index = _meals.indexWhere((m) => m.id == meal.id);
    if (index == -1) {
      _meals.add(meal);
    } else {
      _meals[index] = meal;
    }
    return meal;
  }

  @override
  Future<void> deleteMeal(int id) async {
    if (throwOnDeleteMeal) {
      throw Exception('deleteMeal failed');
    }
    _meals.removeWhere((meal) => meal.id == id);
  }

  @override
  Future<List<Meal>> getMealsForDate(DateTime date) async {
    if (throwOnGetMealsForDate) {
      throw Exception('getMealsForDate failed');
    }
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    return _meals
        .where((meal) => !meal.date.isBefore(start) && meal.date.isBefore(end))
        .toList();
  }

  @override
  Future<List<Meal>> getMealsBefore(DateTime date, {int limit = 20}) async {
    return getMealsBeforeCursor(date, limit: limit);
  }

  @override
  Future<List<Meal>> getMealsForMonth(int year, int month) async {
    if (throwOnGetMealsForMonth) {
      throw Exception('getMealsForMonth failed');
    }
    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 1);
    return _meals
        .where((meal) => !meal.date.isBefore(start) && meal.date.isBefore(end))
        .toList();
  }

  @override
  Future<bool> hasMealsForDate(DateTime date) async {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    return _meals.any(
      (meal) => !meal.date.isBefore(start) && meal.date.isBefore(end),
    );
  }

  @override
  Future<List<Meal>> getMealsBeforeCursor(
    DateTime date, {
    int? id,
    int limit = 20,
  }) async {
    if (throwOnGetMealsBeforeCursor) {
      throw Exception('getMealsBeforeCursor failed');
    }
    final targetMillis = date.millisecondsSinceEpoch;
    final sorted = [..._meals]
      ..sort((a, b) {
        final dateCompare = b.date.compareTo(a.date);
        if (dateCompare != 0) return dateCompare;
        return (b.id ?? 0).compareTo(a.id ?? 0);
      });

    final filtered = sorted.where((meal) {
      final mealMillis = meal.date.millisecondsSinceEpoch;
      if (id == null) {
        return mealMillis < targetMillis;
      }
      return mealMillis < targetMillis ||
          (mealMillis == targetMillis && (meal.id ?? 0) < id);
    });

    return filtered.take(limit).toList();
  }
}
