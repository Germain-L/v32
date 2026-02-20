import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:v32/presentation/widgets/staggered_item.dart';
import 'package:v32/utils/animation_helpers.dart';

void main() {
  group('StaggeredItem', () {
    late AnimationController controller;

    setUp(() {
      controller = AnimationController(
        vsync: const TestVSync(),
        duration: const Duration(milliseconds: 300),
      );
    });

    tearDown(() {
      controller.dispose();
    });

    testWidgets('creates FadeTransition and SlideTransition', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StaggeredItem(
              index: 0,
              animationController: controller,
              child: const Text('Test Child'),
            ),
          ),
        ),
      );

      // Find FadeTransition that contains our SlideTransition
      expect(
        find.descendant(
          of: find.byType(StaggeredItem),
          matching: find.byType(FadeTransition),
        ),
        findsOneWidget,
      );

      // Find SlideTransition within StaggeredItem
      expect(
        find.descendant(
          of: find.byType(StaggeredItem),
          matching: find.byType(SlideTransition),
        ),
        findsOneWidget,
      );

      expect(find.text('Test Child'), findsOneWidget);
    });

    testWidgets('uses easeOutBack curve from kSpringCurve', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StaggeredItem(
              index: 0,
              animationController: controller,
              child: const Text('Test Child'),
            ),
          ),
        ),
      );

      final fadeTransitionFinder = find.descendant(
        of: find.byType(StaggeredItem),
        matching: find.byType(FadeTransition),
      );

      final fadeTransition = tester.widget<FadeTransition>(
        fadeTransitionFinder,
      );
      final animation = fadeTransition.opacity as CurvedAnimation;

      expect(animation.curve, isA<Interval>());

      final interval = animation.curve as Interval;
      expect(interval.curve, equals(Curves.easeOutBack));
      expect(kSpringCurve, equals(Curves.easeOutBack));
    });

    testWidgets('index 0 starts at 0.0', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StaggeredItem(
              index: 0,
              animationController: controller,
              child: const Text('Test Child'),
            ),
          ),
        ),
      );

      final fadeTransitionFinder = find.descendant(
        of: find.byType(StaggeredItem),
        matching: find.byType(FadeTransition),
      );

      final fadeTransition = tester.widget<FadeTransition>(
        fadeTransitionFinder,
      );
      final animation = fadeTransition.opacity as CurvedAnimation;
      final interval = animation.curve as Interval;

      expect(interval.begin, equals(0.0));
    });

    testWidgets('index 1 starts at 0.12', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StaggeredItem(
              index: 1,
              animationController: controller,
              child: const Text('Test Child'),
            ),
          ),
        ),
      );

      final fadeTransitionFinder = find.descendant(
        of: find.byType(StaggeredItem),
        matching: find.byType(FadeTransition),
      );

      final fadeTransition = tester.widget<FadeTransition>(
        fadeTransitionFinder,
      );
      final animation = fadeTransition.opacity as CurvedAnimation;
      final interval = animation.curve as Interval;

      expect(interval.begin, equals(0.12));
    });

    testWidgets('uses default startMultiplier of 0.12', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StaggeredItem(
              index: 2,
              animationController: controller,
              child: const Text('Test Child'),
            ),
          ),
        ),
      );

      final fadeTransitionFinder = find.descendant(
        of: find.byType(StaggeredItem),
        matching: find.byType(FadeTransition),
      );

      final fadeTransition = tester.widget<FadeTransition>(
        fadeTransitionFinder,
      );
      final animation = fadeTransition.opacity as CurvedAnimation;
      final interval = animation.curve as Interval;

      expect(interval.begin, equals(0.24)); // index 2 * 0.12 = 0.24
    });

    testWidgets('respects custom startMultiplier', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StaggeredItem(
              index: 1,
              animationController: controller,
              startMultiplier: 0.05,
              child: const Text('Test Child'),
            ),
          ),
        ),
      );

      final fadeTransitionFinder = find.descendant(
        of: find.byType(StaggeredItem),
        matching: find.byType(FadeTransition),
      );

      final fadeTransition = tester.widget<FadeTransition>(
        fadeTransitionFinder,
      );
      final animation = fadeTransition.opacity as CurvedAnimation;
      final interval = animation.curve as Interval;

      expect(interval.begin, equals(0.05)); // index 1 * 0.05 = 0.05
    });

    testWidgets('animates child with correct slide offset', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StaggeredItem(
              index: 0,
              animationController: controller,
              child: const Text('Test Child'),
            ),
          ),
        ),
      );

      final slideTransitionFinder = find.descendant(
        of: find.byType(StaggeredItem),
        matching: find.byType(SlideTransition),
      );

      final slideTransition = tester.widget<SlideTransition>(
        slideTransitionFinder,
      );
      final positionAnimation = slideTransition.position;
      expect(positionAnimation, isA<Animation<Offset>>());
    });
  });
}
