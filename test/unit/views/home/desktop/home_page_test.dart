import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:realest/src/views/home/desktop/home_page.dart';
import 'package:realest/src/views/home/desktop/header_hero_page.dart';
import 'package:realest/src/views/home/desktop/app_overview.dart';
import 'package:realest/src/views/home/desktop/value_proposition.dart';
import 'package:realest/src/views/home/desktop/progress_metrics.dart';
import 'package:realest/src/views/home/desktop/realtor_stats.dart';
import 'package:realest/src/views/home/desktop/footer.dart';
import 'package:visibility_detector/visibility_detector.dart';

void main() {
  setUpAll(() {
    VisibilityDetectorController.instance.updateInterval = Duration.zero;
  });

  group('HomePage Widget Tests', () {
    testWidgets('renders icon, title, and CTA', (WidgetTester tester) async {
      // Build the widget
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HomePage(),
          ),
        ),
      );

      // Wait for animations and timers to complete
      await tester.pumpAndSettle();

      // Verify all key widgets are rendered
      expect(find.byType(HeaderHeroPage), findsOneWidget);
      expect(find.byType(AppOverview), findsOneWidget);
      expect(find.byType(ValuePropositions), findsOneWidget);
      expect(find.byType(ProgressMetricsSection), findsOneWidget);
      expect(find.byType(RealtorStats), findsOneWidget);
      expect(find.byType(Footer), findsOneWidget);
    });

    testWidgets('scrolling updates gif opacity', (WidgetTester tester) async {
      // Mock a scroll controller
      final scrollController = ScrollController();

      // Build the widget with the mock scroll controller
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HomePage(scrollController: scrollController),
          ),
        ),
      );

      // Wait for the widget tree to stabilize
      await tester.pumpAndSettle();

      // Scroll down
      scrollController.jumpTo(500); // Simulate scrolling
      await tester.pump();

      // Wait for any animations or timers triggered by jumpTo
      await tester.pumpAndSettle();

      // Verify opacity has changed
      final headerHeroPageFinder = find.byType(HeaderHeroPage);
      final HeaderHeroPage headerHeroPage = tester.widget(headerHeroPageFinder);
      expect(headerHeroPage.gifOpacity, lessThan(1.0));
    });
  });
}