import 'package:flutter_test/flutter_test.dart';
import 'package:v32/data/models/meal.dart';
import 'package:v32/presentation/providers/calendar_provider.dart';
import '../fakes/fake_daily_metrics_repository.dart';
import '../fakes/fake_day_rating_repository.dart';
import '../fakes/fake_meal_repository.dart';

void main() {
  test('selectDate normalizes and updates focused month', () async {
    final repo = FakeMealRepository();
    final provider = CalendarProvider(
      repo,
      FakeDayRatingRepository(),
      metricsRepository: FakeDailyMetricsRepository(),
    );

    final target = DateTime(2024, 4, 15, 18, 30);
    provider.selectDate(target);

    expect(provider.selectedDate, DateTime(2024, 4, 15));
    expect(provider.focusedMonth, DateTime(2024, 4, 1));
  });

  test('selectDate no-ops for same day', () async {
    final repo = FakeMealRepository();
    final provider = CalendarProvider(
      repo,
      FakeDayRatingRepository(),
      metricsRepository: FakeDailyMetricsRepository(),
    );
    final selected = provider.selectedDate;

    provider.selectDate(selected);

    expect(provider.selectedDate, selected);
  });

  test('goToPreviousMonth and goToNextMonth update selection', () async {
    final repo = FakeMealRepository();
    final provider = CalendarProvider(
      repo,
      FakeDayRatingRepository(),
      metricsRepository: FakeDailyMetricsRepository(),
    );

    final initial = provider.focusedMonth;
    provider.goToNextMonth();
    expect(provider.focusedMonth.month, initial.month + 1);
    provider.goToPreviousMonth();
    expect(provider.focusedMonth.month, initial.month);
  });

  test('refresh reloads month and day', () async {
    final repo = FakeMealRepository();
    final provider = CalendarProvider(
      repo,
      FakeDayRatingRepository(),
      metricsRepository: FakeDailyMetricsRepository(),
    );

    await provider.refresh();

    expect(provider.isLoadingMonth, isFalse);
    expect(provider.isLoadingDay, isFalse);
  });

  test('hasMealsForDate reflects month map', () async {
    final base = DateTime(2024, 3, 10, 12, 0);
    final repo = FakeMealRepository(
      seedMeals: [Meal(id: 1, slot: MealSlot.lunch, date: base)],
    );
    final provider = CalendarProvider(
      repo,
      FakeDayRatingRepository(),
      metricsRepository: FakeDailyMetricsRepository(),
    );
    provider.selectDate(base);
    await provider.refresh();

    expect(provider.hasMealsForDate(base), isTrue);
    expect(provider.hasMealsForDate(DateTime(2024, 3, 11)), isFalse);
  });

  test('loadMonth handles repository error', () async {
    final repo = FakeMealRepository(throwOnGetMealsForMonth: true);
    final provider = CalendarProvider(
      repo,
      FakeDayRatingRepository(),
      metricsRepository: FakeDailyMetricsRepository(),
    );

    await provider.refresh();

    expect(provider.error, isNotNull);
  });

  test('selected meals are sorted ascending by time', () async {
    final date = DateTime(2024, 3, 5);
    final repo = FakeMealRepository(
      seedMeals: [
        Meal(
          id: 1,
          slot: MealSlot.lunch,
          date: date.add(const Duration(hours: 13)),
        ),
        Meal(
          id: 2,
          slot: MealSlot.breakfast,
          date: date.add(const Duration(hours: 8)),
        ),
      ],
    );
    final provider = CalendarProvider(
      repo,
      FakeDayRatingRepository(),
      metricsRepository: FakeDailyMetricsRepository(),
    );

    await Future<void>.delayed(const Duration(milliseconds: 10));
    provider.selectDate(date);
    await Future<void>.delayed(const Duration(milliseconds: 10));

    expect(provider.selectedMeals.first.id, 2);
    expect(provider.selectedMeals.last.id, 1);
  });
}
