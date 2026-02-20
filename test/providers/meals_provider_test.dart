import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:v32/data/models/meal.dart';
import 'package:v32/presentation/providers/meals_provider.dart';
import '../fakes/fake_meal_repository.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('en', null);
  });
  test('loadMoreMeals dedupes by id and updates cursor', () async {
    final base = DateTime(2024, 3, 1, 8, 0);
    final repo = FakeMealRepository(
      seedMeals: [
        Meal(id: 1, slot: MealSlot.breakfast, date: base),
        Meal(id: 2, slot: MealSlot.lunch, date: base),
        Meal(id: 3, slot: MealSlot.dinner, date: base),
        Meal(
          id: 4,
          slot: MealSlot.lunch,
          date: base.subtract(const Duration(minutes: 1)),
        ),
      ],
    );

    final provider = MealsProvider(repo, pageSize: 2, autoLoad: false);
    await provider.loadMoreMeals();
    await provider.loadMoreMeals();

    expect(provider.meals.map((meal) => meal.id).toList(), [3, 2, 1, 4]);
  });

  test('loadMoreMeals toggles hasMore when empty', () async {
    final repo = FakeMealRepository();
    final provider = MealsProvider(repo, autoLoad: false);

    await provider.loadMoreMeals();

    expect(provider.hasMore, isFalse);
    expect(provider.meals, isEmpty);
  });

  test('loadMoreMeals sets error on repository failure', () async {
    final repo = FakeMealRepository(throwOnGetMealsBeforeCursor: true);
    final provider = MealsProvider(repo, autoLoad: false);

    await provider.loadMoreMeals();

    expect(provider.error, isNotNull);
    expect(provider.isLoading, isFalse);
  });

  test('refresh clears state and reloads', () async {
    final base = DateTime(2024, 3, 1, 8, 0);
    final repo = FakeMealRepository(
      seedMeals: [Meal(id: 1, slot: MealSlot.breakfast, date: base)],
    );
    final provider = MealsProvider(repo, pageSize: 1, autoLoad: false);

    await provider.loadMoreMeals();
    expect(provider.meals, isNotEmpty);

    await provider.refresh();
    expect(provider.meals, isNotEmpty);
    expect(provider.hasMore, isTrue);
  });

  test('getFormattedDateGroup formats weekday within last week', () {
    final provider = MealsProvider(FakeMealRepository(), autoLoad: false);
    final now = DateTime.now();
    final date = now.subtract(const Duration(days: 3));
    final label = provider.getFormattedDateGroup(date);
    expect([
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ], contains(label));
  });

  test('getFormattedDateGroup formats current year dates', () {
    final provider = MealsProvider(FakeMealRepository(), autoLoad: false);
    final now = DateTime.now();
    final date = DateTime(now.year, 1, 5);
    final label = provider.getFormattedDateGroup(date);
    expect(label, contains('Jan'));
    expect(label, contains('5'));
  });

  test('getFormattedDateGroup formats older year dates', () {
    final provider = MealsProvider(FakeMealRepository(), autoLoad: false);
    final date = DateTime(2020, 12, 24);
    final label = provider.getFormattedDateGroup(date);
    expect(label, contains('2020'));
  });

  test('getFormattedDateGroup formats relative labels', () {
    final provider = MealsProvider(FakeMealRepository(), autoLoad: false);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    expect(provider.getFormattedDateGroup(today), 'Today');
    expect(
      provider.getFormattedDateGroup(today.subtract(const Duration(days: 1))),
      'Yesterday',
    );
  });
}
