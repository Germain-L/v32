import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:v32/gen_l10n/app_localizations.dart';
import 'package:v32/presentation/widgets/day_rating_widget.dart';

void main() {
  Widget createTestableWidget({
    required Widget child,
    Locale locale = const Locale('en'),
  }) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: locale,
      home: Scaffold(body: child),
    );
  }

  group('DayRatingWidget', () {
    testWidgets('renders 3 rating options (Bad, Okay, Great)', (tester) async {
      await tester.pumpWidget(
        createTestableWidget(
          child: DayRatingWidget(
            rating: null,
            onRatingSelected: (_) {},
            subtitle: 'Tap to rate today',
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Bad'), findsOneWidget);
      expect(find.text('Okay'), findsOneWidget);
      expect(find.text('Great'), findsOneWidget);
    });

    testWidgets('tapping a rating calls onRatingSelected with correct value', (
      tester,
    ) async {
      int? selectedRating;

      await tester.pumpWidget(
        createTestableWidget(
          child: DayRatingWidget(
            rating: null,
            onRatingSelected: (value) {
              selectedRating = value;
            },
            subtitle: 'Tap to rate today',
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.text('Bad'));
      await tester.pumpAndSettle();
      expect(selectedRating, equals(1));

      await tester.tap(find.text('Okay'));
      await tester.pumpAndSettle();
      expect(selectedRating, equals(2));

      await tester.tap(find.text('Great'));
      await tester.pumpAndSettle();
      expect(selectedRating, equals(3));
    });

    testWidgets('selected rating shows highlighted style', (tester) async {
      await tester.pumpWidget(
        createTestableWidget(
          child: DayRatingWidget(
            rating: 2,
            onRatingSelected: (_) {},
            subtitle: 'Tap to rate today',
          ),
        ),
      );

      await tester.pumpAndSettle();

      final animatedContainers = tester.widgetList<AnimatedContainer>(
        find.byType(AnimatedContainer),
      );
      expect(animatedContainers.length, equals(3));

      final containerList = animatedContainers.toList();

      final unselectedDecoration1 =
          containerList[0].decoration as BoxDecoration?;
      final selectedDecoration = containerList[1].decoration as BoxDecoration?;
      final unselectedDecoration3 =
          containerList[2].decoration as BoxDecoration?;

      expect(unselectedDecoration1?.border?.top.width, equals(1));
      expect(selectedDecoration?.border?.top.width, equals(1.4));
      expect(unselectedDecoration3?.border?.top.width, equals(1));
    });

    testWidgets('renders with null rating (not set state)', (tester) async {
      await tester.pumpWidget(
        createTestableWidget(
          child: DayRatingWidget(
            rating: null,
            onRatingSelected: (_) {},
            subtitle: 'Tap to rate today',
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Not rated'), findsOneWidget);
      expect(find.text('How was your day?'), findsOneWidget);
    });

    testWidgets('renders with rating set (rated state)', (tester) async {
      await tester.pumpWidget(
        createTestableWidget(
          child: DayRatingWidget(
            rating: 3,
            onRatingSelected: (_) {},
            subtitle: 'Tap to rate this day',
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Day rated'), findsOneWidget);
    });

    testWidgets('renders subtitle text correctly', (tester) async {
      const testSubtitle = 'Custom subtitle text';

      await tester.pumpWidget(
        createTestableWidget(
          child: DayRatingWidget(
            rating: null,
            onRatingSelected: (_) {},
            subtitle: testSubtitle,
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text(testSubtitle), findsOneWidget);
    });
  });
}
