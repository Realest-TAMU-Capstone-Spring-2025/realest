import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:realest/src/views/calculators/affordability_calculator.dart';

void main() {
  group('AffordabilityCalculator Widget Tests', () {
    testWidgets('Displays all input fields and calculate button', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(),
            child: Scaffold(
              body: const AffordabilityCalculator(),
            ),
          ),
        ),
      );

      expect(find.text('Annual Income (\$)'), findsOneWidget);
      expect(find.text('Monthly Debt (\$)'), findsOneWidget);
      expect(find.text('Down Payment (\$ or %)'), findsOneWidget);
      expect(find.text('Interest Rate (%)'), findsOneWidget);
      expect(find.text('Loan Term (Years)'), findsOneWidget);
      expect(find.text('Calculate'), findsOneWidget);
    });

    testWidgets('Shows error message when invalid inputs are provided', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(),
            child: Scaffold(
              body: const AffordabilityCalculator(),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Calculate'));
      await tester.pump();

      expect(find.text('Please enter valid numbers in all fields'), findsOneWidget);
    });

    testWidgets('Calculates affordability correctly with valid inputs', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(),
            child: Scaffold(
              body: const AffordabilityCalculator(),
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField).at(0), '120000');
      await tester.enterText(find.byType(TextField).at(1), '500');
      await tester.enterText(find.byType(TextField).at(2), '20000');
      await tester.enterText(find.byType(TextField).at(3), '5');
      await tester.enterText(find.byType(TextField).at(4), '30');

      await tester.tap(find.text('Calculate'));
      await tester.pump();

      expect(find.textContaining('Estimated Price Range'), findsOneWidget);
      expect(find.textContaining('Low'), findsOneWidget);
      expect(find.textContaining('Target'), findsOneWidget);
      expect(find.textContaining('High'), findsOneWidget);
      expect(find.textContaining('Monthly Budget'), findsOneWidget);
      expect(find.textContaining('Mortgage Breakdown'), findsOneWidget);
    });
  });
}
