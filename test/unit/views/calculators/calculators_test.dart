import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:realest/src/views/calculators/calculators.dart';
import 'package:realest/src/views/calculators/piti_calculator.dart';
import 'package:realest/src/views/calculators/affordability_calculator.dart';
import 'package:realest/src/views/calculators/rental_property_calculator.dart';
import '../../../flutter_test_config.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  Widget createTestableWidget(Widget child, Size size) {
    return MaterialApp(
      home: Scaffold(
        body: LayoutBuilder(
          builder: (context, constraints) {
            return MediaQuery(
              data: MediaQueryData(size: size),
              child: child,
            );
          },
        ),
      ),
    );
  }

  group('Calculators Widget Tests', () {
    testWidgets('renders mobile layout with dropdown', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400, // Constrain width to simulate mobile layout
              height: 800, // Constrain height to simulate mobile layout
              child: Calculators(),
            ),
          ),
        ),
      );

      // Verify the dropdown is present
      expect(find.byType(DropdownButtonFormField<int>), findsOneWidget);
    });

    testWidgets('renders wide layout with sidebar', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      await tester.pumpWidget(createTestableWidget(const Calculators(), const Size(800, 1200)));
      await tester.pumpAndSettle();

      // Verify sidebar is present
      expect(find.text('Calculators'), findsOneWidget);

      // Verify default calculator is PITI Calculator
      expect(find.byType(PitiCalculator), findsOneWidget);
    });

    testWidgets('dropdown changes selected calculator in mobile layout', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 800));
      await tester.pumpWidget(createTestableWidget(const Calculators(), const Size(400, 800)));
      await tester.pumpAndSettle();

      // Open dropdown
      await tester.tap(find.byType(DropdownButtonFormField<int>));
      await tester.pumpAndSettle();

      // Select Affordability Calculator
      await tester.tap(find.text('Affordability Calculator').last);
      await tester.pumpAndSettle();

      // Verify Affordability Calculator is displayed
      expect(find.byType(AffordabilityCalculator), findsOneWidget);
    });

    testWidgets('sidebar changes selected calculator in wide layout', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      await tester.pumpWidget(createTestableWidget(const Calculators(), const Size(800, 1200)));
      await tester.pumpAndSettle();

      // Tap on Rental Property Calculator in the sidebar
      await tester.tap(find.text('Rental Property Calculator'));
      await tester.pumpAndSettle();

      // Verify Rental Property Calculator is displayed
      expect(find.byType(RentalPropertyCalculator), findsOneWidget);
    });

    testWidgets('switches between mobile and wide layouts based on screen size', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 800));
      await tester.pumpWidget(createTestableWidget(const Calculators(), const Size(400, 800)));
      await tester.pumpAndSettle();

      // Verify mobile layout
      expect(find.byType(DropdownButtonFormField<int>), findsOneWidget);

      // Switch to wide layout
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      await tester.pumpWidget(createTestableWidget(const Calculators(), const Size(800, 1200)));
      await tester.pumpAndSettle();

      // Verify wide layout
      expect(find.text('Calculators'), findsOneWidget);
    });
  });
}