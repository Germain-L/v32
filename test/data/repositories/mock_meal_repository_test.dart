import 'package:flutter_test/flutter_test.dart';
import 'package:v32/data/models/meal.dart';
import 'package:v32/data/repositories/mock_meal_repository.dart';

void main() {
  group('MockMealRepository', () {
    late MockMealRepository repository;

    setUp(() {
      repository = MockMealRepository();
    });

    tearDown(() {
      repository.clear();
    });

    test('implements MealRepository', () {
      expect(repository, isA<MockMealRepository>());
    });

    test('saveMeal assigns ID on create', () async {
      final meal = Meal(slot: MealSlot.breakfast, date: DateTime.now());

      final saved = await repository.saveMeal(meal);

      expect(saved.id, isNotNull);
    });

    test('saveMeal updates existing meal', () async {
      final meal = Meal(slot: MealSlot.breakfast, date: DateTime.now());
      final saved = await repository.saveMeal(meal);

      final updated = saved.copyWith(description: 'Updated');
      final result = await repository.saveMeal(updated);

      expect(result.id, saved.id);
      expect(result.description, 'Updated');
    });

    test('getMealById returns meal', () async {
      final meal = Meal(slot: MealSlot.breakfast, date: DateTime.now());
      final saved = await repository.saveMeal(meal);

      final retrieved = await repository.getMealById(saved.id!);

      expect(retrieved?.id, saved.id);
    });

    test('getMealById returns null for non-existent', () async {
      final result = await repository.getMealById(999);

      expect(result, isNull);
    });

    test('deleteMeal removes meal', () async {
      final meal = Meal(slot: MealSlot.breakfast, date: DateTime.now());
      final saved = await repository.saveMeal(meal);

      await repository.deleteMeal(saved.id!);

      final retrieved = await repository.getMealById(saved.id!);
      expect(retrieved, isNull);
    });

    test('getMealsForDate returns meals for date', () async {
      final date = DateTime(2024, 1, 15);
      await repository.saveMeal(Meal(slot: MealSlot.breakfast, date: date));
      await repository.saveMeal(Meal(slot: MealSlot.lunch, date: date));
      await repository.saveMeal(
        Meal(slot: MealSlot.dinner, date: date.add(Duration(days: 1))),
      );

      final meals = await repository.getMealsForDate(date);

      expect(meals.length, 2);
    });

    test('hasMealsForDate returns true when meals exist', () async {
      final date = DateTime(2024, 1, 15);
      await repository.saveMeal(Meal(slot: MealSlot.breakfast, date: date));

      final hasMeals = await repository.hasMealsForDate(date);

      expect(hasMeals, isTrue);
    });

    test('hasMealsForDate returns false when no meals', () async {
      final date = DateTime(2024, 1, 15);

      final hasMeals = await repository.hasMealsForDate(date);

      expect(hasMeals, isFalse);
    });

    test('watchTodayMeals emits current meals', () async {
      await repository.saveMeal(
        Meal(slot: MealSlot.breakfast, date: DateTime.now()),
      );

      final meals = await repository.watchTodayMeals().first;

      expect(meals.length, 1);
    });

    test('clear removes all meals', () async {
      await repository.saveMeal(
        Meal(slot: MealSlot.breakfast, date: DateTime.now()),
      );

      repository.clear();

      final meals = await repository.getMealsForDate(DateTime.now());
      expect(meals.length, 0);
    });
  });
}
