import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:realest/src/views/realtor/realtor_reports.dart';

void main() {
  group('RealtorReports Widget Tests', () {
    testWidgets('renders the RealtorReports widget correctly', (WidgetTester tester) async {
      // Build the widget
      await tester.pumpWidget(
        const MaterialApp(
          home: RealtorReports(),
        ),
      );

      // Verify the text is displayed
      expect(find.text('View Reports Here'), findsOneWidget);

      // Verify the text style
      final textWidget = tester.widget<Text>(find.text('View Reports Here'));
      expect(textWidget.style?.fontSize, 24);
      expect(textWidget.style?.fontWeight, FontWeight.bold);
    });

    testWidgets('has a centered layout', (WidgetTester tester) async {
      // Build the widget
      await tester.pumpWidget(
        const MaterialApp(
          home: RealtorReports(),
        ),
      );

      // Verify the Center widget is present
      expect(find.byType(Center), findsOneWidget);

      // Verify the Text widget is a child of Center
      final centerWidget = tester.widget<Center>(find.byType(Center));
      expect(centerWidget.child, isA<Text>());
    });

    testWidgets('uses a Scaffold widget', (WidgetTester tester) async {
      // Build the widget
      await tester.pumpWidget(
        const MaterialApp(
          home: RealtorReports(),
        ),
      );

      // Verify the Scaffold widget is present
      expect(find.byType(Scaffold), findsOneWidget);
    });
  });
}