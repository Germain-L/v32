---
name: flutter-testing
description: Widget and integration testing patterns for Flutter with Isar database and image handling
license: MIT
compatibility: opencode
metadata:
  category: testing
  framework: flutter
---

## What I Do

Provide comprehensive testing patterns for Flutter apps using Isar database, image_picker, and local storage.

## When to Use Me

Use this skill when:
- Writing widget tests for database-backed screens
- Testing image capture and display flows
- Creating integration tests for complete user journeys
- Mocking platform plugins (image_picker)
- Setting up test data with Isar

## Testing Patterns

### 1. Mock Isar Database

```dart
// test/helpers/test_isar.dart
import 'package:isar/isar.dart';

class TestIsarHelper {
  static Future<Isar> createTestIsar() async {
    final dir = Directory.systemTemp.createTempSync();
    
    return Isar.open(
      [MealSchema],
      directory: dir.path,
    );
  }
}
```

### 2. Mock Image Picker

```dart
// test/mocks/mock_image_picker.dart
import 'package:image_picker/image_picker.dart';
import 'package:mockito/mockito.dart';

class MockImagePicker extends Mock implements ImagePicker {
  XFile? returnFile;
  
  @override
  Future<XFile?> pickImage({
    required ImageSource source,
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
  }) async => returnFile;
}
```

### 3. Test Meal Slot Widget

```dart
// test/widgets/meal_slot_test.dart
testWidgets('MealSlot displays photo when meal has image', (tester) async {
  final meal = Meal()
    ..id = 1
    ..slot = MealSlot.lunch
    ..date = DateTime.now()
    ..imagePath = '/test/path.jpg';
  
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: MealSlot(
          meal: meal,
          onPhotoTap: () {},
          onDescriptionChanged: (_) {},
        ),
      ),
    ),
  );
  
  expect(find.byType(Image), findsOneWidget);
  expect(find.byIcon(Icons.camera_alt), findsNothing);
});
```

### 4. Integration Test Pattern

```dart
// integration_test/app_test.dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  
  group('End-to-end meal tracking', () {
    testWidgets('Add meal with photo', (tester) async {
      app.main();
      await tester.pumpAndSettle();
      
      // Tap breakfast slot
      await tester.tap(find.text('Breakfast'));
      await tester.pumpAndSettle();
      
      // Tap camera button
      await tester.tap(find.byIcon(Icons.camera_alt));
      await tester.pumpAndSettle();
      
      // Verify meal saved
      expect(find.text('Breakfast entry saved'), findsOneWidget);
    });
  });
}
```

### 5. Golden Tests

```dart
// test/goldens/meal_card_test.dart
testWidgets('MealCard golden test', (tester) async {
  final meal = Meal()
    ..id = 1
    ..slot = MealSlot.dinner
    ..date = DateTime(2024, 1, 15, 19, 30)
    ..description = 'Grilled salmon with vegetables';
  
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData.light(),
      home: Scaffold(
        body: MealCard(meal: meal),
      ),
    ),
  );
  
  await expectLater(
    find.byType(MealCard),
    matchesGoldenFile('goldens/meal_card.png'),
  );
});
```

## Best Practices

- Always pumpAndSettle() after async operations
- Use find.byKey() for dynamic content
- Mock platform channels for native plugins
- Clean up Isar instances after each test
- Group related tests semantically
- Use setUp() and tearDown() for test isolation