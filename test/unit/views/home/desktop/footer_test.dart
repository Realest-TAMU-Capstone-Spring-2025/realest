import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:realest/src/views/home/desktop/footer.dart';

void main() {
  group('Footer Widget Tests', () {
    testWidgets('renders branding, quick links, and newsletter signup', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Footer(),
          ),
        ),
      );

      // Verify branding elements
      expect(find.byIcon(Icons.real_estate_agent), findsOneWidget);
      expect(find.text('RealEst'), findsOneWidget);
      expect(find.text('© 2025 RealEst'), findsOneWidget);

      // Verify quick links
      expect(find.text('Quick Links'), findsOneWidget);
      expect(find.text('Overview'), findsOneWidget);
      expect(find.text('Policies'), findsOneWidget);
      expect(find.text('Terms of Use'), findsOneWidget);
      expect(find.text('Contact Us'), findsOneWidget);

      // Verify newsletter signup
      expect(find.text('Sign Up for Newsletter'), findsOneWidget);
      expect(find.text('Enter your email'), findsOneWidget);
      expect(find.text('Subscribe'), findsOneWidget);
    });

    testWidgets('adjusts layout for mobile and desktop', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Footer(),
          ),
        ),
      );

      // Verify layout for desktop
      final footerFinder = find.byType(Footer);
      expect(tester.getSize(footerFinder).width, greaterThan(800));

      // Simulate mobile layout
      tester.binding.window.physicalSizeTestValue = const Size(400, 800);
      await tester.pumpAndSettle();

      // Verify layout for mobile
      expect(tester.getSize(footerFinder).width, lessThan(800));

      // Reset window size
      tester.binding.window.clearPhysicalSizeTestValue();
    });

    testWidgets('interacts with quick links and subscribe button', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Footer(),
          ),
        ),
      );

      // Tap on a quick link
      await tester.tap(find.text('Overview'));
      await tester.pumpAndSettle();

      // Verify interaction (mock navigation logic can be added here)

      // Enter email and tap subscribe
      await tester.enterText(find.byType(TextFormField), 'test@example.com');
      await tester.tap(find.text('Subscribe'));
      await tester.pumpAndSettle();

      // Verify interaction (mock subscription logic can be added here)
    });
  });
}