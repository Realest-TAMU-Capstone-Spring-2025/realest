import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:realest/src/views/home/desktop/home_page.dart';
import 'dart:ui';
import 'package:realest/src/views/home/desktop/header_hero_page.dart';
import 'package:realest/src/views/home/desktop/app_overview.dart';
import 'package:realest/src/views/home/desktop/value_proposition.dart';
import 'package:realest/src/views/home/desktop/progress_metrics.dart';
import 'package:realest/src/views/home/desktop/realtor_stats.dart';
import 'package:realest/src/views/home/desktop/footer.dart';
import 'package:fake_async/fake_async.dart';

void main() {
  group('HomePage Widget Tests', () {
    testWidgets('renders icon, title, and CTA', (WidgetTester tester) async {
      // FakeAsync().run((async) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: HomePage(),
            ),
          ),
        );
        await tester.pumpAndSettle();
        // async.elapse(const Duration(seconds: 1));

        // Verify HeaderHeroPage is rendered
        expect(find.byType(HeaderHeroPage), findsOneWidget);
        // Verify AppOverview is rendered
        expect(find.byType(AppOverview), findsOneWidget);
        // Verify ValuePropositions is rendered
        expect(find.byType(ValuePropositions), findsOneWidget);
        // Verify ProgressMetricsSection is rendered
        expect(find.byType(ProgressMetricsSection), findsOneWidget);
        // Verify RealtorStats is rendered
        expect(find.byType(RealtorStats), findsOneWidget);
        // Verify Footer is rendered
        expect(find.byType(Footer), findsOneWidget);
      // });
    });

    testWidgets('scrolling updates gif opacity', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HomePage(),
          ),
        ),
      );

      final scrollableFinder = find.byWidgetPredicate(
        (widget) => widget is SingleChildScrollView && widget.controller != null,
      );
      final headerHeroPageFinder = find.byType(HeaderHeroPage);

      // Verify initial opacity
      HeaderHeroPage headerHeroPage = tester.widget(headerHeroPageFinder);
      expect(headerHeroPage.gifOpacity, 1.0);

      // Scroll down
      await tester.drag(scrollableFinder, const Offset(0, -500));
      await tester.pump();

      // Verify opacity has changed
      headerHeroPage = tester.widget(headerHeroPageFinder);
      expect(headerHeroPage.gifOpacity, lessThan(1.0));
    });
  });
}