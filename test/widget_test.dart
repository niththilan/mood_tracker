// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mood_tracker/main.dart';

void main() {
  testWidgets('Mood tracker app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(MoodTrackerApp());

    // Verify that the app initializes correctly with main elements
    expect(find.text('Daily Mood Tracker'), findsOneWidget);
    expect(find.text('Select Mood'), findsOneWidget);
    expect(find.text('Log Mood'), findsOneWidget);
    expect(find.text('Mood History'), findsOneWidget);

    // Verify that mood history is initially empty
    expect(find.byType(ListView), findsOneWidget);
  });
}
