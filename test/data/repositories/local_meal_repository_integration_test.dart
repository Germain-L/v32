import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:v32/data/models/meal.dart';
import 'package:v32/data/repositories/local_meal_repository.dart';
import 'package:v32/data/repositories/meal_repository_interface.dart';
import 'package:v32/data/services/database_service.dart';

void main() {
  group('LocalMealRepository Integration', () {
    late LocalMealRepository repository;

    setUp(() async {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
      await DatabaseService.useInMemoryDatabaseForTesting();
      repository = LocalMealRepository();
    });

    tearDown(() async {
      await DatabaseService.resetForTesting();
    });

    test('implements MealRepository', () {
      expect(repository, isA<MealRepository>());
    });

    test('full CRUD flow works', () async {
      // Create
      final meal = Meal(slot: MealSlot.lunch, date: DateTime.now());
      final saved = await repository.saveMeal(meal);
      expect(saved.id, isNotNull);

      // Read
      final retrieved = await repository.getMealById(saved.id!);
      expect(retrieved?.slot, MealSlot.lunch);

      // Update
      final updated = saved.copyWith(description: 'Updated meal');
      final savedUpdated = await repository.saveMeal(updated);
      expect(savedUpdated.description, 'Updated meal');

      // Delete
      await repository.deleteMeal(saved.id!);
      final deleted = await repository.getMealById(saved.id!);
      expect(deleted, isNull);
    });

    test('getMealsForDate returns meals for specific date', () async {
      final date = DateTime(2024, 1, 15);
      await repository.saveMeal(Meal(slot: MealSlot.breakfast, date: date));
      await repository.saveMeal(Meal(slot: MealSlot.lunch, date: date));

      final meals = await repository.getMealsForDate(date);
      expect(meals.length, 2);
    });

    test('hasMealsForDate returns correct boolean', () async {
      final date = DateTime(2024, 1, 15);
      expect(await repository.hasMealsForDate(date), isFalse);

      await repository.saveMeal(Meal(slot: MealSlot.breakfast, date: date));
      expect(await repository.hasMealsForDate(date), isTrue);
    });
  });
}
