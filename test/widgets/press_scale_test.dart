import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:v32/presentation/widgets/press_scale.dart';

void main() {
  group('PressScale', () {
    testWidgets('scales to 0.96 on tap down', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: PressScale(
                child: Container(
                  width: 100,
                  height: 100,
                  color: Colors.blue,
                ),
              ),
            ),
          ),
        ),
      );

      // Use tester.press to trigger onTapDown
      final pressScaleFinder = find.byType(PressScale);
      await tester.press(pressScaleFinder);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Check the Transform scale
      final transformFinder = find.descendant(
        of: pressScaleFinder,
        matching: find.byType(Transform),
      );
      
      expect(transformFinder, findsOneWidget);
      
      final transformWidget = tester.widget<Transform>(transformFinder);
      final scale = transformWidget.transform.getMaxScaleOnAxis();
      
      // Scale should be approximately 0.96 after tap down
      expect(scale, closeTo(0.96, 0.02));
    });

    testWidgets('returns to 1.0 on tap up', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: PressScale(
                child: Container(
                  width: 100,
                  height: 100,
                  color: Colors.blue,
                ),
              ),
            ),
          ),
        ),
      );

      final pressScaleFinder = find.byType(PressScale);
      
      // Press down
      await tester.press(pressScaleFinder);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Complete the tap
      await tester.tap(pressScaleFinder);
      await tester.pumpAndSettle();

      // Check final scale
      final transformFinder = find.descendant(
        of: pressScaleFinder,
        matching: find.byType(Transform),
      );
      
      final transformWidget = tester.widget<Transform>(transformFinder);
      final scale = transformWidget.transform.getMaxScaleOnAxis();
      
      // Scale should return to approximately 1.0
      expect(scale, closeTo(1.0, 0.02));
    });

    testWidgets('returns to 1.0 on tap cancel', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: PressScale(
                child: Container(
                  width: 100,
                  height: 100,
                  color: Colors.blue,
                ),
              ),
            ),
          ),
        ),
      );

      final pressScaleFinder = find.byType(PressScale);
      final center = tester.getCenter(pressScaleFinder);

      // Press down and hold
      final gesture = await tester.startGesture(center);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Cancel the gesture
      await gesture.cancel();
      await tester.pumpAndSettle();

      // Verify widget rendered
      expect(pressScaleFinder, findsOneWidget);
      
      // Check final scale
      final transformFinder = find.descendant(
        of: pressScaleFinder,
        matching: find.byType(Transform),
      );
      
      final transformWidget = tester.widget<Transform>(transformFinder);
      final scale = transformWidget.transform.getMaxScaleOnAxis();
      
      // Scale should be approximately 1.0 after cancel
      expect(scale, closeTo(1.0, 0.02));
    });

    testWidgets('onTap callback fires when tapped', (WidgetTester tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: PressScale(
                onTap: () => tapped = true,
                child: Container(
                  width: 100,
                  height: 100,
                  color: Colors.blue,
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(PressScale));
      await tester.pump();

      expect(tapped, isTrue);
    });
  });
}
