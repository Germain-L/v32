import 'package:flutter_test/flutter_test.dart';
import 'package:diet/data/models/meal.dart';
import 'package:diet/presentation/providers/today_provider.dart';
import '../fakes/fake_day_rating_repository.dart';
import '../fakes/fake_meal_repository.dart';

void main() {
  test('loadTodayMeals maps meals into slots and descriptions', () async {
    final now = DateTime.now();
    final repo = FakeMealRepository(
      seedMeals: [
        Meal(id: 1, slot: MealSlot.breakfast, date: now, description: 'Eggs'),
        Meal(id: 2, slot: MealSlot.lunch, date: now, description: 'Salad'),
      ],
    );

    final provider = TodayProvider(repo, FakeDayRatingRepository());
    await provider.loadTodayMeals();

    expect(provider.getMeal(MealSlot.breakfast)?.description, 'Eggs');
    expect(provider.getMeal(MealSlot.lunch)?.description, 'Salad');
    expect(provider.getDescription(MealSlot.lunch), 'Salad');
  });

  test('updateDescription creates new meal when none exists', () async {
    final repo = FakeMealRepository();
    final provider = TodayProvider(repo, FakeDayRatingRepository());

    provider.updateDescription(MealSlot.dinner, 'Pasta');
    await provider.saveDescriptionNow(MealSlot.dinner);

    final meal = provider.getMeal(MealSlot.dinner);
    expect(meal, isNotNull);
    expect(meal?.description, 'Pasta');
  });

  test('updateDescription does not create meal for empty text', () async {
    final repo = FakeMealRepository();
    final provider = TodayProvider(repo, FakeDayRatingRepository());

    provider.updateDescription(MealSlot.dinner, '');
    await provider.saveDescriptionNow(MealSlot.dinner);

    expect(provider.getMeal(MealSlot.dinner), isNull);
  });

  test('saveDescriptionNow updates existing meal', () async {
    final now = DateTime.now();
    final repo = FakeMealRepository(
      seedMeals: [
        Meal(id: 9, slot: MealSlot.lunch, date: now, description: 'Soup'),
      ],
    );
    final provider = TodayProvider(repo, FakeDayRatingRepository());
    await provider.loadTodayMeals();

    provider.updateDescription(MealSlot.lunch, 'Soup and salad');
    await provider.saveDescriptionNow(MealSlot.lunch);

    expect(provider.getMeal(MealSlot.lunch)?.description, 'Soup and salad');
  });

  test('saveDescriptionNow handles repository error', () async {
    final repo = FakeMealRepository(throwOnSaveMeal: true);
    final provider = TodayProvider(repo, FakeDayRatingRepository());

    provider.updateDescription(MealSlot.dinner, 'Pasta');
    await expectLater(
      () => provider.saveDescriptionNow(MealSlot.dinner),
      throwsException,
    );
  });

  test('clearMeal removes stored meal and resets description', () async {
    final now = DateTime.now();
    final repo = FakeMealRepository(
      seedMeals: [
        Meal(id: 10, slot: MealSlot.breakfast, date: now, description: 'Toast'),
      ],
    );
    final provider = TodayProvider(repo, FakeDayRatingRepository());
    await provider.loadTodayMeals();

    await provider.clearMeal(MealSlot.breakfast);

    expect(provider.getMeal(MealSlot.breakfast), isNull);
    expect(provider.getDescription(MealSlot.breakfast), '');
    expect(
      repo.meals.where((meal) => meal.slot == MealSlot.breakfast),
      isEmpty,
    );
  });

  test('deletePhoto clears imagePath on meal', () async {
    final now = DateTime.now();
    final repo = FakeMealRepository(
      seedMeals: [
        Meal(
          id: 4,
          slot: MealSlot.dinner,
          date: now,
          imagePath: '/tmp/test.jpg',
        ),
      ],
    );
    final provider = TodayProvider(repo, FakeDayRatingRepository());
    await provider.loadTodayMeals();

    await provider.deletePhoto(MealSlot.dinner);

    expect(provider.getMeal(MealSlot.dinner)?.imagePath, isNull);
  });

  test('clearMeal prevents pending save from persisting', () async {
    final repo = FakeMealRepository();
    final provider = TodayProvider(repo, FakeDayRatingRepository());

    provider.updateDescription(MealSlot.breakfast, 'Coffee');
    await provider.clearMeal(MealSlot.breakfast);
    await provider.flushPendingSaves();

    expect(
      repo.meals.where((meal) => meal.slot == MealSlot.breakfast),
      isEmpty,
    );
  });
}
