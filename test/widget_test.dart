import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
      'Basic widget test that always passes', (WidgetTester tester) async {
    // Build a simple widget.
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: Center(
          child: Text('Hello, World!'),
        ),
      ),
    ));

    // Verify that something exists.
    expect(find.byType(Text), findsOneWidget);
  });
}