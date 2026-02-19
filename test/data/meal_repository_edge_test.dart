import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:diet/data/models/meal.dart';
import 'package:diet/data/repositories/meal_repository.dart';
import 'package:diet/data/services/database_service.dart';

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

  test('getMealsForMonth spans month boundaries', () async {
    await repository.saveMeal(
      Meal(slot: MealSlot.breakfast, date: DateTime(2024, 3, 1, 8, 0)),
    );
    await repository.saveMeal(
      Meal(slot: MealSlot.lunch, date: DateTime(2024, 3, 31, 23, 59)),
    );
    await repository.saveMeal(
      Meal(slot: MealSlot.dinner, date: DateTime(2024, 4, 1, 0, 0)),
    );

    final meals = await repository.getMealsForMonth(2024, 3);

    expect(meals.length, 2);
  });

  test('getMealsBefore uses limit and ordering', () async {
    final base = DateTime(2024, 3, 1, 8, 0);
    await repository.saveMeal(Meal(slot: MealSlot.breakfast, date: base));
    await repository.saveMeal(
      Meal(slot: MealSlot.lunch, date: base.subtract(const Duration(hours: 1))),
    );
    await repository.saveMeal(
      Meal(
        slot: MealSlot.dinner,
        date: base.subtract(const Duration(hours: 2)),
      ),
    );

    final meals = await repository.getMealsBefore(base, limit: 2);

    expect(meals.length, 2);
    expect(meals.first.date.isAfter(meals.last.date), isTrue);
  });
}
