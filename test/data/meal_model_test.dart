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
      imagePath: '/tmp/image.jpg',
    );

    final map = meal.toMap();
    final decoded = Meal.fromMap(map);

    expect(decoded.id, 42);
    expect(decoded.slot, MealSlot.lunch);
    expect(decoded.date, date);
    expect(decoded.description, 'Salad');
    expect(decoded.imagePath, '/tmp/image.jpg');
  });

  test('Meal copyWith preserves imagePath when unset', () {
    final meal = Meal(
      id: 1,
      slot: MealSlot.breakfast,
      date: DateTime(2024, 3, 1),
      imagePath: '/tmp/image.jpg',
    );

    final updated = meal.copyWith(description: 'Eggs');
    expect(updated.imagePath, '/tmp/image.jpg');
  });

  test('Meal copyWith clears imagePath when null', () {
    final meal = Meal(
      id: 1,
      slot: MealSlot.breakfast,
      date: DateTime(2024, 3, 1),
      imagePath: '/tmp/image.jpg',
    );

    final updated = meal.copyWith(imagePath: null);
    expect(updated.imagePath, isNull);
  });

  test('Meal hasImage is false for null or empty', () {
    final mealNull = Meal(
      id: 1,
      slot: MealSlot.breakfast,
      date: DateTime(2024, 3, 1),
    );
    final mealEmpty = Meal(
      id: 2,
      slot: MealSlot.lunch,
      date: DateTime(2024, 3, 1),
      imagePath: '',
    );
    final mealValid = Meal(
      id: 3,
      slot: MealSlot.dinner,
      date: DateTime(2024, 3, 1),
      imagePath: '/tmp/image.jpg',
    );

    expect(mealNull.hasImage, isFalse);
    expect(mealEmpty.hasImage, isFalse);
    expect(mealValid.hasImage, isTrue);
  });
}
