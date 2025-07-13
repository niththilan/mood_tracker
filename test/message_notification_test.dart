import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Message Notification Badge Tests', () {
    testWidgets('Notification badge should be hidden when count is 0', (
      WidgetTester tester,
    ) async {
      // Create a test widget with notification badge
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                // Create a mock state instance to test the badge
                final mockWidget = Container(
                  width: 50,
                  height: 50,
                  color: Colors.blue,
                );

                // Test badge with count = 0
                final badge = _buildTestNotificationBadge(
                  child: mockWidget,
                  count: 0,
                );

                return badge;
              },
            ),
          ),
        ),
      );

      // The badge should not be visible when count is 0
      expect(find.text('0'), findsNothing);
      expect(find.byType(Container), findsOneWidget);
    });

    testWidgets('Notification badge should show count when greater than 0', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                final mockWidget = Container(
                  width: 50,
                  height: 50,
                  color: Colors.blue,
                );

                // Test badge with count = 5
                final badge = _buildTestNotificationBadge(
                  child: mockWidget,
                  count: 5,
                );

                return badge;
              },
            ),
          ),
        ),
      );

      // The badge should show the count
      expect(find.text('5'), findsOneWidget);
    });

    testWidgets('Notification badge should show 99+ for counts over 99', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                final mockWidget = Container(
                  width: 50,
                  height: 50,
                  color: Colors.blue,
                );

                // Test badge with count = 150
                final badge = _buildTestNotificationBadge(
                  child: mockWidget,
                  count: 150,
                );

                return badge;
              },
            ),
          ),
        ),
      );

      // The badge should show 99+
      expect(find.text('99+'), findsOneWidget);
    });
  });
}

// Helper method to create a test notification badge
Widget _buildTestNotificationBadge({
  required Widget child,
  required int count,
}) {
  if (count == 0) {
    return child;
  }

  return Stack(
    children: [
      child,
      Positioned(
        right: 0,
        top: 0,
        child: Container(
          padding: EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: Colors.red,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white, width: 1),
          ),
          constraints: BoxConstraints(minWidth: 16, minHeight: 16),
          child: Text(
            count > 99 ? '99+' : count.toString(),
            style: TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    ],
  );
}
