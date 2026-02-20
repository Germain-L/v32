import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:v32/data/models/meal.dart';
import 'package:v32/gen_l10n/app_localizations.dart';
import 'package:v32/presentation/providers/meals_provider.dart';
import 'package:v32/presentation/screens/meals_screen.dart';
import 'package:v32/presentation/widgets/skeleton_loading.dart';
import 'package:v32/presentation/widgets/meal_history_card.dart';

import '../fakes/fake_meal_repository.dart';

class TestMealsScreen extends StatelessWidget {
  final FakeMealRepository repository;

  const TestMealsScreen({super.key, required this.repository});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en'), Locale('fr')],
      home: MealsScreen(repository: repository, autoLoad: false),
    );
  }
}

void main() {
  group('MealsScreen swipe-to-delete', () {
    test('provider loads meals correctly', () async {
      final now = DateTime.now();
      final repo = FakeMealRepository(
        seedMeals: [
          Meal(
            id: 1,
            slot: MealSlot.breakfast,
            date: now.subtract(const Duration(hours: 1)),
            description: 'Test breakfast',
          ),
        ],
      );
      
      final provider = MealsProvider(repo, autoLoad: false);
      expect(provider.meals.length, 0);
      
      await provider.loadMoreMeals();
      
      print('Meals loaded: ${provider.meals.length}');
      print('Error: ${provider.error}');
      print('isLoading: ${provider.isLoading}');
      
      expect(provider.meals.length, 1);
      expect(provider.meals.first.id, 1);
    });

    testWidgets('Dismissible exists on meal cards', (tester) async {
      final now = DateTime.now();
      final repo = FakeMealRepository(
        seedMeals: [
          Meal(
            id: 1,
            slot: MealSlot.breakfast,
            date: now.subtract(const Duration(hours: 1)),
            description: 'Test breakfast',
          ),
        ],
      );

      await tester.pumpWidget(TestMealsScreen(repository: repo));
      await tester.pump();
      await tester.pump(const Duration(seconds: 3));
      
      print('After pump - checking for widgets:');
      print('  SkeletonLoading: ${find.byType(SkeletonLoading).evaluate().length}');
      print('  CircularProgressIndicator: ${find.byType(CircularProgressIndicator).evaluate().length}');
      print('  Dismissible: ${find.byType(Dismissible).evaluate().length}');
      print('  MealHistoryCard: ${find.byType(MealHistoryCard).evaluate().length}');

      final dismissible = find.byType(Dismissible);
      expect(dismissible, findsOneWidget);

      final dismissibleWidget = tester.widget<Dismissible>(dismissible);
      expect(dismissibleWidget.key, const ValueKey('meal_1'));
    });

    testWidgets('swipe direction is endToStart', (tester) async {
      final now = DateTime.now();
      final repo = FakeMealRepository(
        seedMeals: [
          Meal(
            id: 2,
            slot: MealSlot.lunch,
            date: now.subtract(const Duration(hours: 2)),
            description: 'Test lunch',
          ),
        ],
      );

      await tester.pumpWidget(TestMealsScreen(repository: repo));
      await tester.pump();
      await tester.pump(const Duration(seconds: 3));

      final dismissible = find.byType(Dismissible);
      expect(dismissible, findsOneWidget);

      final dismissibleWidget = tester.widget<Dismissible>(dismissible);
      expect(dismissibleWidget.direction, DismissDirection.endToStart);
    });

    testWidgets('confirmDismiss shows dialog', (tester) async {
      final now = DateTime.now();
      final repo = FakeMealRepository(
        seedMeals: [
          Meal(
            id: 3,
            slot: MealSlot.dinner,
            date: now.subtract(const Duration(hours: 3)),
            description: 'Test dinner',
          ),
        ],
      );

      await tester.pumpWidget(TestMealsScreen(repository: repo));
      await tester.pump();
      await tester.pump(const Duration(seconds: 3));

      expect(find.byType(AlertDialog), findsNothing);

      final dismissible = find.byType(Dismissible);
      expect(dismissible, findsOneWidget);

      await tester.drag(dismissible, const Offset(-500, 0));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
    });
  });
}
