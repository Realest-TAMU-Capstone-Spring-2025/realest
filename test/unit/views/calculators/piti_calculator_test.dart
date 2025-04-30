import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:realest/src/views/calculators/piti_calculator.dart';
import 'package:fl_chart/fl_chart.dart';

void main() {
  group('PitiCalculator Widget Tests', () {
    testWidgets('Displays all input fields and calculate button', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(),
            child: Scaffold(
              body: const PitiCalculator(),
            ),
          ),
        ),
      );

      expect(find.text('Home Price (\$)'), findsOneWidget);
      expect(find.text('Down Payment (\$)'), findsOneWidget);
      expect(find.text('Interest Rate (%)'), findsOneWidget);
      expect(find.text('Loan Term (Years)'), findsOneWidget);
      expect(find.text('Annual Property Tax (\$)'), findsOneWidget);
      expect(find.text('Monthly Insurance (\$)'), findsOneWidget);
      expect(find.text('Calculate'), findsOneWidget);
    });

    testWidgets('Shows error message when invalid inputs are provided', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(),
            child: Scaffold(
              body: const PitiCalculator(),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Calculate'));
      await tester.pumpAndSettle(); // Ensure all animations and state updates are completed

      expect(find.textContaining('Please enter valid values to calculate your payment.'), findsOneWidget);
    });

    testWidgets('Calculates PITI correctly with valid inputs', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(),
            child: Scaffold(
              body: const PitiCalculator(),
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField).at(0), '300000');
      await tester.enterText(find.byType(TextField).at(1), '60000');
      await tester.enterText(find.byType(TextField).at(2), '5.5');
      await tester.enterText(find.byType(TextField).at(3), '30');
      await tester.enterText(find.byType(TextField).at(4), '3600');
      await tester.enterText(find.byType(TextField).at(5), '100');

      await tester.tap(find.text('Calculate'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Monthly Payment Breakdown'), findsOneWidget);
      expect(find.textContaining('Estimated Monthly Payment'), findsOneWidget);
    });

    testWidgets('Handles zero inputs gracefully', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(),
            child: Scaffold(
              body: const PitiCalculator(),
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField).at(0), '0');
      await tester.enterText(find.byType(TextField).at(1), '0');
      await tester.enterText(find.byType(TextField).at(2), '0');
      await tester.enterText(find.byType(TextField).at(3), '0');
      await tester.enterText(find.byType(TextField).at(4), '0');
      await tester.enterText(find.byType(TextField).at(5), '0');

      await tester.tap(find.text('Calculate'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Please enter valid values to calculate your payment.'), findsOneWidget);
    });

    testWidgets('Displays pie chart sections correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(),
            child: Scaffold(
              body: const PitiCalculator(),
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField).at(0), '300000');
      await tester.enterText(find.byType(TextField).at(1), '60000');
      await tester.enterText(find.byType(TextField).at(2), '5.5');
      await tester.enterText(find.byType(TextField).at(3), '30');
      await tester.enterText(find.byType(TextField).at(4), '3600');
      await tester.enterText(find.byType(TextField).at(5), '100');

      await tester.tap(find.text('Calculate'));
      await tester.pumpAndSettle();

      expect(find.byType(PieChart), findsOneWidget);
    });

    testWidgets('Calculates PITI with zero down payment', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(),
            child: Scaffold(
              body: const PitiCalculator(),
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField).at(0), '300000'); // Home Price
      await tester.enterText(find.byType(TextField).at(1), '0'); // Down Payment
      await tester.enterText(find.byType(TextField).at(2), '5.5'); // Interest Rate
      await tester.enterText(find.byType(TextField).at(3), '30'); // Loan Term
      await tester.enterText(find.byType(TextField).at(4), '3600'); // Annual Property Tax
      await tester.enterText(find.byType(TextField).at(5), '100'); // Monthly Insurance

      await tester.tap(find.text('Calculate'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Estimated Monthly Payment'), findsOneWidget);
    });

    testWidgets('Handles invalid inputs gracefully (ignores)', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(),
            child: Scaffold(
              body: const PitiCalculator(),
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField).at(0), 'abc'); // Invalid Home Price
      await tester.enterText(find.byType(TextField).at(1), 'xyz'); // Invalid Down Payment
      await tester.enterText(find.byType(TextField).at(2), '5.5'); // Valid Interest Rate
      await tester.enterText(find.byType(TextField).at(3), '30'); // Valid Loan Term
      await tester.enterText(find.byType(TextField).at(4), '3600'); // Valid Annual Property Tax
      await tester.enterText(find.byType(TextField).at(5), '100'); // Valid Monthly Insurance

      await tester.tap(find.text('Calculate'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Monthly Payment Breakdown'), findsOneWidget);
    });
  });
}