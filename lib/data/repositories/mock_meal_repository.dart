import '../models/meal.dart';
import 'meal_repository_interface.dart';

/// In-memory implementation of MealRepository for unit testing.
/// Stores data in memory - fast but not persistent.
class MockMealRepository implements MealRepository {
  final Map<int, Meal> _meals = {};
  int _nextId = 1;

  @override
  Future<Meal> saveMeal(Meal meal) async {
    if (meal.id == null) {
      final newMeal = meal.copyWith(id: _nextId++);
      _meals[newMeal.id!] = newMeal;
      return newMeal;
    } else {
      _meals[meal.id!] = meal;
      return meal;
    }
  }

  @override
  Future<Meal?> getMealById(int id) async => _meals[id];

  @override
  Future<void> deleteMeal(int id) async {
    _meals.remove(id);
  }

  @override
  Stream<List<Meal>> watchTodayMeals() async* {
    yield await getMealsForDate(DateTime.now());
  }

  @override
  Future<List<Meal>> getMealsForDate(DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(Duration(days: 1));

    return _meals.values
        .where(
          (m) =>
              m.date.isAfter(startOfDay.subtract(Duration(microseconds: 1))) &&
              m.date.isBefore(endOfDay),
        )
        .toList();
  }

  @override
  Future<bool> hasMealsForDate(DateTime date) async {
    final meals = await getMealsForDate(date);
    return meals.isNotEmpty;
  }

  /// Clear all data (useful in tests)
  void clear() {
    _meals.clear();
    _nextId = 1;
  }
}
