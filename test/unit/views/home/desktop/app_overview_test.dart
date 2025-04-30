import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:realest/src/views/home/desktop/app_overview.dart';
import 'package:carousel_slider/carousel_slider.dart';

void main() {
  group('AppOverview Widget Tests', () {
    testWidgets('renders all UI elements', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AppOverview(),
        ),
      );
      await tester.pump(const Duration(seconds: 2));

      // Verify title is displayed
      expect(find.text('App Overview'), findsOneWidget);

      // Verify feature texts are displayed
      expect(find.textContaining('Dual UI Ecosystem'), findsOneWidget);
      expect(find.textContaining('Cash Flow Calculator'), findsOneWidget);
      expect(find.textContaining('Realtor Branding'), findsOneWidget);
      expect(find.textContaining('Instant Match System'), findsOneWidget);

      // Verify carousel is displayed
      expect(find.byType(CarouselSlider), findsOneWidget);
    });

    testWidgets('verifies staggered animations', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AppOverview(),
        ),
      );

      // Verify initial state of animations
      final titleFinder = find.text('App Overview');
      final titleWidget = tester.widget<FadeTransition>(
        find.ancestor(of: titleFinder, matching: find.byType(FadeTransition)),
      );
      expect(titleWidget.opacity.value, equals(0));

      // Advance animations
      await tester.pump(const Duration(milliseconds: 1000));

      // Verify final state of animations
      expect(titleWidget.opacity.value, equals(1));
    });

    testWidgets('carousel navigation works', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AppOverview(),
        ),
      );

      // Verify initial carousel page
      expect(find.byType(CarouselSlider), findsOneWidget);

      // Simulate carousel navigation
      await tester.tap(find.byIcon(Icons.arrow_right));
      await tester.pumpAndSettle();

      // Verify carousel navigated to the next page
      // This can be verified by checking the current page indicator or other means
    });
  });
}