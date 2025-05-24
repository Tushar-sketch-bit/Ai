// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ui/main.dart';

void main() {
  testWidgets('Philosophy Bot app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const PhilosophyBotApp());

    // Verify that the welcome message appears
    expect(find.text('Welcome to Philosophy Bot'), findsOneWidget);
    expect(
      find.text(
        'Ask me anything about philosophy, psychology, or spirituality.',
      ),
      findsOneWidget,
    );

    // Verify that the input field is present
    expect(
      find.widgetWithText(TextField, 'Ask a philosophical question...'),
      findsOneWidget,
    );
  });
}
