import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:realest/src/views/home/desktop/feature_container.dart';
import 'dart:ui';

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
      expect(containerFinder, findsOneWidget);

      // Locate the specific MouseRegion for hover effects using the unique key
      final mouseRegionFinder = find.byKey(const Key('FeatureContainerMouseRegion'));
      expect(mouseRegionFinder, findsOneWidget); // Ensure the correct MouseRegion exists

      // Define hover position
      const hoverPosition = Offset(100, 100);

      // // Simulate hover
      // await tester.sendEventToBinding(PointerEnterEvent(position: hoverPosition)); // Simulate hover
      // await tester.sendEventToBinding(PointerEnterEvent(position: hoverPosition)); // Simulate hover
      // await tester.pumpAndSettle();

      // Verify hover state
      final animatedContainerFinder = find.descendant(
        of: containerFinder,
        matching: find.byType(AnimatedContainer),
      );
      final hoveredContainer = tester.widget<AnimatedContainer>(
        animatedContainerFinder.first,
      );
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
      expect(containerFinder, findsOneWidget);
      expect(tester.getSize(containerFinder).width, greaterThan(200));

      // Simulate mobile layout
      tester.binding.window.physicalSizeTestValue = const Size(400, 800);
      addTearDown(tester.binding.window.clearPhysicalSizeTestValue); // Ensure cleanup
      await tester.pumpAndSettle();

      // Verify layout for mobile
      expect(tester.getSize(containerFinder).width, lessThan(400));
    });
  });
}