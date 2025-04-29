import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:realest/src/views/home/desktop/header_hero_page.dart';

void main() {
  group('HeaderHeroPage Widget Tests', () {

    testWidgets('renders header with logo and title', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HeaderHeroPage(gifOpacity: 0.5),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('RealEst'), findsOneWidget);
      expect(find.byIcon(Icons.real_estate_agent), findsOneWidget);
      expect(find.text('Automate Analysis, Multiply Deals'), findsOneWidget);
      expect(find.text('Turn spreadsheet hours into investor-ready insights instantly.'), findsOneWidget);
    });
  });
}