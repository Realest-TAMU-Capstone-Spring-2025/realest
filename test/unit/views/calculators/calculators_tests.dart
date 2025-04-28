// test/calculators_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:realest/src/views/calculators/calculators.dart';
import 'package:realest/src/views/calculators/piti_calculator.dart';
import 'package:realest/src/views/calculators/affordability_calculator.dart';
import 'package:realest/src/views/calculators/rental_property_calculator.dart';

void main() {
  const calculatorNames = [
    'PITI Calculator',
    'Affordability Calculator',
    'Rental Property Calculator',
  ];

  group('Calculators.build & layout selection', () {
    testWidgets('☀️ Sunny: width ≥ 800 uses wide layout with sidebar',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: const Calculators(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Calculators'), findsOneWidget);
      expect(find.byType(DropdownButtonFormField<int>), findsNothing);
    });

    testWidgets('🌧️ Rainy: width < 800 falls back to mobile layout',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 799),
            child: const Calculators(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(DropdownButtonFormField<int>), findsOneWidget);
      expect(find.text('Calculators'), findsNothing);
    });
  });

  group('_buildMobileLayout()', () {
    testWidgets('☀️ Sunny: dropdown shows all calculator options & default child',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: const Calculators(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(PitiCalculator), findsOneWidget);

      await tester.tap(find.byType(DropdownButtonFormField<int>));
      await tester.pumpAndSettle();

      expect(
        find.byType(DropdownMenuItem<int>),
        findsNWidgets(calculatorNames.length),
      );

      for (final name in calculatorNames) {
        expect(find.text(name), findsWidgets);
      }
    });

    testWidgets('🌧️ Rainy: dismissing the menu (i.e. “null” change) doesn’t crash or mutate',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: const Calculators(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(PitiCalculator), findsOneWidget);

      await tester.tap(find.byType(DropdownButtonFormField<int>));
      await tester.pumpAndSettle();

      await tester.tapAt(const Offset(0, 0));
      await tester.pumpAndSettle();

      expect(find.byType(PitiCalculator), findsOneWidget);
    });
  });

  group('_buildWideLayout()', () {
    testWidgets('☀️ Sunny: sidebar has one item per calculator', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: const Calculators(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      for (final name in calculatorNames) {
        expect(find.text(name), findsOneWidget);
      }
    });

    testWidgets('🌧️ Rainy: wide layout contains no DropdownButton',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: const Calculators(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(DropdownButtonFormField<int>), findsNothing);
    });
  });

  group('_buildSidebarItem() & selection', () {
    testWidgets('☀️ Sunny: tapping sidebar item updates the displayed calculator',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: const Calculators(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(PitiCalculator), findsOneWidget);
      expect(find.byType(AffordabilityCalculator), findsNothing);

      await tester.tap(find.text(calculatorNames[1]));
      await tester.pumpAndSettle();

      expect(find.byType(PitiCalculator), findsNothing);
      expect(find.byType(AffordabilityCalculator), findsOneWidget);
    });

    testWidgets('🌧️ Rainy: tapping the already selected item does not break UI',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: const Calculators(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text(calculatorNames[0]));
      await tester.pumpAndSettle();

      expect(find.byType(PitiCalculator), findsOneWidget);
    });
  });

  group('_buildSelectedCalculator()', () {
    testWidgets('☀️ Sunny: default index shows PitiCalculator', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Calculators()),
      );
      await tester.pumpAndSettle();

      expect(find.byType(PitiCalculator), findsOneWidget);
      expect(find.byType(AffordabilityCalculator), findsNothing);
      expect(find.byType(RentalPropertyCalculator), findsNothing);
    });

    testWidgets('🌧️ Rainy: other calculators are not visible before selecting',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Calculators()),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AffordabilityCalculator), findsNothing);
      expect(find.byType(RentalPropertyCalculator), findsNothing);
    });
  });
}
