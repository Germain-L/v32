import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:v32/data/models/meal.dart';
import 'package:v32/data/repositories/meal_repository.dart';
import 'package:v32/data/services/database_service.dart';

void main() {
  late MealRepository repository;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    await DatabaseService.resetForTesting();
    await DatabaseService.useInMemoryDatabaseForTesting();
    repository = MealRepository();
  });

  tearDown(() async {
    await DatabaseService.resetForTesting();
  });

  test('saveMeal inserts when id is null', () async {
    final meal = Meal(
      slot: MealSlot.breakfast,
      date: DateTime(2024, 3, 1, 8, 0),
      description: 'Eggs',
    );

    final saved = await repository.saveMeal(meal);

    expect(saved.id, isNotNull);
    final fetched = await repository.getMealById(saved.id!);
    expect(fetched?.description, 'Eggs');
  });

  test('saveMeal updates when id is provided', () async {
    final meal = Meal(
      slot: MealSlot.lunch,
      date: DateTime(2024, 3, 1, 12, 0),
      description: 'Soup',
    );

    final saved = await repository.saveMeal(meal);
    final updated = await repository.saveMeal(
      saved.copyWith(description: 'Soup and salad'),
    );

    final fetched = await repository.getMealById(updated.id!);
    expect(fetched?.description, 'Soup and salad');
  });

  test('getMealsForDate includes start and excludes next day', () async {
    final base = DateTime(2024, 3, 1, 9, 0);
    await repository.saveMeal(Meal(slot: MealSlot.breakfast, date: base));
    await repository.saveMeal(
      Meal(slot: MealSlot.lunch, date: base.add(const Duration(hours: 2))),
    );
    await repository.saveMeal(
      Meal(slot: MealSlot.dinner, date: DateTime(2024, 3, 2, 0, 0)),
    );

    final meals = await repository.getMealsForDate(DateTime(2024, 3, 1));

    expect(meals.length, 2);
    expect(meals.map((meal) => meal.slot), contains(MealSlot.breakfast));
    expect(meals.map((meal) => meal.slot), contains(MealSlot.lunch));
  });

  test('getMealsBeforeCursor uses date and id ordering', () async {
    final base = DateTime(2024, 3, 1, 8, 0);
    final meals = await Future.wait([
      repository.saveMeal(Meal(slot: MealSlot.breakfast, date: base)),
      repository.saveMeal(Meal(slot: MealSlot.lunch, date: base)),
      repository.saveMeal(Meal(slot: MealSlot.dinner, date: base)),
      repository.saveMeal(
        Meal(
          slot: MealSlot.lunch,
          date: base.subtract(const Duration(days: 1)),
        ),
      ),
    ]);

    final sorted = [...meals]
      ..sort((a, b) {
        final dateCompare = b.date.compareTo(a.date);
        if (dateCompare != 0) return dateCompare;
        return b.id!.compareTo(a.id!);
      });

    final cursorMeal = sorted[1];
    final page = await repository.getMealsBeforeCursor(
      cursorMeal.date,
      id: cursorMeal.id,
      limit: 10,
    );

    for (final meal in page) {
      final mealMillis = meal.date.millisecondsSinceEpoch;
      final cursorMillis = cursorMeal.date.millisecondsSinceEpoch;
      final isBefore =
          mealMillis < cursorMillis ||
          (mealMillis == cursorMillis && meal.id! < cursorMeal.id!);
      expect(isBefore, isTrue);
    }
  });

  test('hasMealsForDate returns true when meals exist', () async {
    await repository.saveMeal(
      Meal(slot: MealSlot.breakfast, date: DateTime(2024, 3, 1, 9, 0)),
    );

    final hasMeals = await repository.hasMealsForDate(DateTime(2024, 3, 1));
    final hasNone = await repository.hasMealsForDate(DateTime(2024, 3, 2));

    expect(hasMeals, isTrue);
    expect(hasNone, isFalse);
  });

  test('watchTodayMeals emits on change notification', () async {
    final now = DateTime.now();
    final first = await repository.watchTodayMeals().first;
    expect(first, isEmpty);

    await repository.saveMeal(Meal(slot: MealSlot.breakfast, date: now));

    final updated = await repository.watchTodayMeals().first;
    expect(updated, isNotEmpty);
  });
}
