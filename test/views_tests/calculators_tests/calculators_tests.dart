// test/calculators_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
// TODO: adjust this import to point at your calculators.dart
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

      // Should find the sidebar title...
      expect(find.text('Calculators'), findsOneWidget);
      // ...and should NOT find the mobile dropdown
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

      // Should find the dropdown selector...
      expect(find.byType(DropdownButtonFormField<int>), findsOneWidget);
      // ...and should NOT find the sidebar title
      expect(find.text('Calculators'), findsNothing);
    });
  });

    group('_buildMobileLayout()', () {
      testWidgets('☀️ Sunny: dropdown shows all calculator options & default child',
          (WidgetTester tester) async {
        // 1) Render Calculators in mobile mode
        await tester.pumpWidget(
          MaterialApp(
            home: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: const Calculators(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // 2) By default, PitiCalculator should be showing
        expect(find.byType(PitiCalculator), findsOneWidget);

        // 3) Tap the dropdown to open the menu
        await tester.tap(find.byType(DropdownButtonFormField<int>));
        await tester.pumpAndSettle();

        // 4) Verify that we now have exactly 3 menu items in the overlay...
        expect(
          find.byType(DropdownMenuItem<int>),
          findsNWidgets(calculatorNames.length),
        );

        // 5) …and that each label appears at least once
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

        // default child still visible
        expect(find.byType(PitiCalculator), findsOneWidget);

        // open menu…
        await tester.tap(find.byType(DropdownButtonFormField<int>));
        await tester.pumpAndSettle();

        // …then tap outside of it to dismiss (simulates a “null” selection)
        await tester.tapAt(const Offset(0, 0));
        await tester.pumpAndSettle();

        // nothing blew up and we’re still on PitiCalculator
        expect(find.byType(PitiCalculator), findsOneWidget);
      });
    });


    testWidgets('🌧️ Rainy: onChanged(null) does not crash or change selection',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: const Calculators(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Grab the dropdown and call onChanged(null)
      final dropdownFinder = find.byType(DropdownButtonFormField<int>);
      final dropdown =
          tester.widget<DropdownButtonFormField<int>>(dropdownFinder);
      // Should not throw when passing null
      dropdown.onChanged!(null);

      // After rebuild, still PitiCalculator
      await tester.pumpAndSettle();
      expect(find.byType(PitiCalculator), findsOneWidget);
    });
  });

  group('_buildWideLayout()', () {
    testWidgets('☀️ Sunny: sidebar has one item per calculator',
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

      // Before tap, only PitiCalculator is visible
      expect(find.byType(PitiCalculator), findsOneWidget);
      expect(find.byType(AffordabilityCalculator), findsNothing);

      // Tap the second sidebar item
      await tester.tap(find.text(calculatorNames[1]));
      await tester.pumpAndSettle();

      // Now AffordabilityCalculator should be visible
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

      // Default is index 0; tap it again
      await tester.tap(find.text(calculatorNames[0]));
      await tester.pumpAndSettle();

      // Should still show PitiCalculator and no errors
      expect(find.byType(PitiCalculator), findsOneWidget);
    });
  });

  group('_buildSelectedCalculator()', () {
    testWidgets('☀️ Sunny: default index shows PitiCalculator',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Calculators()),
      );
      await tester.pumpAndSettle();

      expect(find.byType(PitiCalculator), findsOneWidget);
      expect(find.byType(AffordabilityCalculator), findsNothing);
      expect(find.byType(RentalPropertyCalculator), findsNothing);
    });

    testWidgets(
        '🌧️ Rainy: other calculators are not visible before selecting', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Calculators()),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AffordabilityCalculator), findsNothing);
      expect(find.byType(RentalPropertyCalculator), findsNothing);
    });
  });
}
