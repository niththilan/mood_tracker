// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:mood_tracker/main.dart';
import 'package:mood_tracker/services/theme_service.dart';

void main() {
  testWidgets('Mood tracker app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame with proper providers
    await tester.pumpWidget(
      MultiProvider(
        providers: [ChangeNotifierProvider(create: (_) => ThemeService())],
        child: MoodTrackerApp(),
      ),
    );

    // Pump a few frames to let the app initialize
    await tester.pump();
    await tester.pump(Duration(seconds: 1));

    // Verify that the app has basic UI elements
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
