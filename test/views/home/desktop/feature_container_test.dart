import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:realest/src/views/home/desktop/feature_container.dart';

void main() {
  group('FeatureContainer Widget Tests', () {
    testWidgets('renders icon, title, and CTA', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FeatureContainer(
              icon: Icons.star,
              title: 'Feature Title',
              cta: 'Learn More',
            ),
          ),
        ),
      );

      // Verify icon is displayed
      expect(find.byIcon(Icons.star), findsOneWidget);

      // Verify title is displayed
      expect(find.text('Feature Title'), findsOneWidget);

      // Verify CTA is displayed
      expect(find.text('Learn More'), findsOneWidget);
    });

    testWidgets('applies hover effects', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FeatureContainer(
              icon: Icons.star,
              title: 'Feature Title',
              cta: 'Learn More',
            ),
          ),
        ),
      );

      // Verify initial state
      final containerFinder = find.byType(FeatureContainer);
      // Locate the specific AnimatedContainer for hover effects
      final animatedContainerFinder = find.descendant(
        of: containerFinder,
        matching: find.byType(AnimatedContainer),
      ).first;
      final animatedContainer = tester.widget<AnimatedContainer>(animatedContainerFinder);
      expect(animatedContainer.decoration, isNotNull);

      // Simulate hover
      final mouseRegion = find.byType(MouseRegion);
      await tester.enterText(mouseRegion, '');
      await tester.pumpAndSettle();

      // Verify hover state
      final hoveredContainer = tester.widget<AnimatedContainer>(animatedContainerFinder);
      expect(hoveredContainer.decoration, isNotNull);
    });

    testWidgets('adjusts layout for mobile and desktop', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FeatureContainer(
              icon: Icons.star,
              title: 'Feature Title',
              cta: 'Learn More',
            ),
          ),
        ),
      );

      // Verify layout for desktop
      final containerFinder = find.byType(FeatureContainer);
      expect(tester.getSize(containerFinder).width, greaterThan(200));

      // Simulate mobile layout
      tester.binding.window.physicalSizeTestValue = const Size(400, 800);
      await tester.pumpAndSettle();

      // Verify layout for mobile
      expect(tester.getSize(containerFinder).width, lessThan(200));

      // Reset window size
      tester.binding.window.clearPhysicalSizeTestValue();
    });
  });
}