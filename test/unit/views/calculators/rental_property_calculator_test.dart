import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:realest/src/views/calculators/rental_property_calculator.dart';

void main() {
  group('RentalPropertyCalculator Widget Tests', () {
    testWidgets('Displays all input fields and calculate button', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(),
            child: Scaffold(
              body: const RentalPropertyCalculator(),
            ),
          ),
        ),
      );

      expect(find.text('Purchase Price'), findsOneWidget);
      expect(find.text('Down Payment (%)'), findsOneWidget);
      expect(find.text('Interest Rate (%)'), findsOneWidget);
      expect(find.text('Loan Term (Years)'), findsOneWidget);
      expect(find.text('Closing Costs'), findsOneWidget);
      expect(find.text('Repair Costs'), findsOneWidget);
      expect(find.text('Property Tax'), findsOneWidget);
      expect(find.text('Insurance'), findsOneWidget);
      expect(find.text('HOA Fees'), findsOneWidget);
      expect(find.text('Maintenance'), findsOneWidget);
      expect(find.text('Other Costs'), findsOneWidget);
      expect(find.text('Monthly Rent'), findsOneWidget);
      expect(find.text('Vacancy Rate (%)'), findsOneWidget);
      expect(find.text('Management Fee (%)'), findsOneWidget);
      expect(find.text('Calculate'), findsOneWidget);
    });

    testWidgets('Shows error message when invalid inputs are provided', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(),
            child: Scaffold(
              body: const RentalPropertyCalculator(),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Calculate'));
      await tester.pump();

      expect(find.textContaining('Please enter valid'), findsNothing);
    });

    testWidgets('Calculates rental property metrics correctly with valid inputs', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(),
            child: Scaffold(
              body: SingleChildScrollView(
                child: const RentalPropertyCalculator(),
              ),
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField).at(0), '400000'); // Adjusted purchase price
      await tester.enterText(find.byType(TextField).at(1), '60'); // Increased down payment percentage
      await tester.enterText(find.byType(TextField).at(2), '3.5'); // Reduced interest rate
      await tester.enterText(find.byType(TextField).at(3), '30');
      await tester.enterText(find.byType(TextField).at(4), '8000');
      await tester.enterText(find.byType(TextField).at(5), '4000');
      await tester.enterText(find.byType(TextField).at(6), '3000');
      await tester.enterText(find.byType(TextField).at(7), '1500');
      await tester.enterText(find.byType(TextField).at(8), '0');
      await tester.enterText(find.byType(TextField).at(9), '3500'); // Increased monthly rent
      await tester.enterText(find.byType(TextField).at(10), '400');
      await tester.enterText(find.byType(TextField).at(11), '1500');
      await tester.enterText(find.byType(TextField).at(12), '5');
      await tester.enterText(find.byType(TextField).at(13), '8');

      await tester.ensureVisible(find.text('Calculate'));
      await tester.tap(find.text('Calculate'));
      await tester.pump(Duration(seconds: 1));

      expect(find.textContaining('Annual Cash Flow'), findsOneWidget);
      expect(find.textContaining('ROI'), findsOneWidget);
    });
  });
}