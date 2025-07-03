import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mood_tracker/widgets/interactive_logo.dart';

void main() {
  group('Interactive Logo Tests', () {
    testWidgets('InteractiveLogo renders correctly', (
      WidgetTester tester,
    ) async {
      bool tapped = false;

      // Build the widget
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: InteractiveLogo(
                size: 100,
                onTap: () {
                  tapped = true;
                },
              ),
            ),
          ),
        ),
      );

      // Verify the logo is rendered
      expect(find.byType(InteractiveLogo), findsOneWidget);

      // Test tap functionality
      await tester.tap(find.byType(InteractiveLogo));
      expect(tapped, isTrue);
    });

    testWidgets('StaticLogo renders correctly', (WidgetTester tester) async {
      // Build the widget
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: Center(child: StaticLogo(size: 100)))),
      );

      // Verify the static logo is rendered
      expect(find.byType(StaticLogo), findsOneWidget);
    });

    testWidgets('InteractiveLogo responds to size changes', (
      WidgetTester tester,
    ) async {
      // Build the widget with initial size
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: Center(child: InteractiveLogo(size: 50))),
        ),
      );

      // Find the SizedBox that contains the logo
      final sizedBox = tester.widget<SizedBox>(
        find
            .descendant(
              of: find.byType(InteractiveLogo),
              matching: find.byType(SizedBox),
            )
            .first,
      );

      // Verify the size is correct
      expect(sizedBox.width, equals(50));
      expect(sizedBox.height, equals(50));
    });

    testWidgets('InteractiveLogo handles animation state', (
      WidgetTester tester,
    ) async {
      // Build the widget with animations disabled
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(child: InteractiveLogo(size: 100, isAnimating: false)),
          ),
        ),
      );

      // Verify the logo is rendered even with animations disabled
      expect(find.byType(InteractiveLogo), findsOneWidget);

      // Pump a few frames to ensure no errors occur
      await tester.pump(Duration(milliseconds: 100));
      await tester.pump(Duration(milliseconds: 100));
    });
  });
}
