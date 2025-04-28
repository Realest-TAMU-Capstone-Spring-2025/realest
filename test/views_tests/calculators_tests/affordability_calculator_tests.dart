// File: test/widgets/affordability_calculator_test.dart

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:realest/src/views/calculators/affordability_calculator.dart';

void main() {
  group('AffordabilityCalculator widget tests', () {
    testWidgets('☀️ sunny-day: valid inputs show correct results',
        (WidgetTester tester) async {
      // 1) Render the widget
      await tester.pumpWidget(
        const MaterialApp(home: AffordabilityCalculator()),
      );
      await tester.pumpAndSettle();

      // 2) Enter valid inputs
      await tester.enterText(
          find.byKey(const Key('incomeField')), '120000');
      await tester.enterText(
          find.byKey(const Key('interestField')), '3.5');
      await tester.enterText(
          find.byKey(const Key('debtField')), '500');

      // 3) Tap the button by its label
      await tester.tap(find.text('Calculate'));
      await tester.pumpAndSettle();

      // 4) Expect the success message
      expect(find.textContaining('You can afford a loan'), findsOneWidget);
    });

    testWidgets('🌧 rainy-day: empty or invalid input shows prompt',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: AffordabilityCalculator()),
      );
      await tester.pumpAndSettle();

      // Tap without entering anything
      await tester.tap(find.text('Calculate'));
      await tester.pumpAndSettle();

      // Should show the validation prompt
      expect(find.text('Please enter valid numbers in all fields'),
          findsOneWidget);
    });
  });
}
