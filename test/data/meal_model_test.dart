import 'package:flutter_test/flutter_test.dart';
import 'package:v32/data/models/meal.dart';

void main() {
  test('MealSlot displayName maps to labels', () {
    expect(MealSlot.breakfast.displayName, 'Breakfast');
    expect(MealSlot.lunch.displayName, 'Lunch');
    expect(MealSlot.afternoonSnack.displayName, 'Afternoon Snack');
    expect(MealSlot.dinner.displayName, 'Dinner');
  });

  test('Meal toMap and fromMap round-trip', () {
    final date = DateTime(2024, 3, 1, 9, 30, 12);
    final meal = Meal(
      id: 42,
      slot: MealSlot.lunch,
      date: date,
      description: 'Salad',
    );

    final map = meal.toMap();
    final decoded = Meal.fromMap(map);

    expect(decoded.id, 42);
    expect(decoded.slot, MealSlot.lunch);
    expect(decoded.date, date);
    expect(decoded.description, 'Salad');
  });

  test('Meal copyWith updates description', () {
    final meal = Meal(
      id: 1,
      slot: MealSlot.breakfast,
      date: DateTime(2024, 3, 1),
    );

    final updated = meal.copyWith(description: 'Eggs');
    expect(updated.description, 'Eggs');
  });
}
