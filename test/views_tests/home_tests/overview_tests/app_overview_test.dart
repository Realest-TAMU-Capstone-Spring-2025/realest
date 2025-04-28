// test/app_overview_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:realest/src/views/home/overview/app_overview.dart'; // ← update this to your actual package

void main() {
  const neonPurple = Color(0xFFa78cde);

  testWidgets('sunny: _startAnimations sets _isVisible=true and advances controllers',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: AppOverview()));
    await tester.pumpAndSettle();

    // Grab the private state as dynamic
    final state = tester.state(find.byType(AppOverview)) as dynamic;

    // Ensure we start from a known baseline
    state._isVisible = false;
    state._titleController.reset();
    state._leftTextController.reset();
    state._carouselControllerAnim.reset();

    // Call the method under test
    state._startAnimations();
    await tester.pump(); // let the setState take effect

    // Assertions
    expect(state._isVisible, isTrue);
    expect(state._titleController.value, greaterThan(0.0));
    expect(state._leftTextController.value, greaterThan(0.0));
    expect(state._carouselControllerAnim.value, greaterThan(0.0));
  });

  testWidgets('rainy: _resetAnimations sets _isVisible=false and resets controllers',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: AppOverview()));
    await tester.pumpAndSettle();

    final state = tester.state(find.byType(AppOverview)) as dynamic;

    // First, advance them so reset has something to do
    state._startAnimations();
    await tester.pump();
    expect(state._isVisible, isTrue);
    expect(state._titleController.value, greaterThan(0.0));

    // Now reset
    state._resetAnimations();
    await tester.pump();

    expect(state._isVisible, isFalse);
    expect(state._titleController.value, equals(0.0));
    expect(state._leftTextController.value, equals(0.0));
    expect(state._carouselControllerAnim.value, equals(0.0));
  });

  testWidgets('sunny: didUpdateWidget triggers animations when not visible',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: AppOverview()));
    await tester.pumpAndSettle();

    final state = tester.state(find.byType(AppOverview)) as dynamic;

    // Simulate invisible
    state._isVisible = false;
    state._titleController.reset();

    // Call didUpdateWidget
    state.didUpdateWidget(const AppOverview());
    await tester.pump();

    expect(state._isVisible, isTrue);
    expect(state._titleController.value, greaterThan(0.0));
  });

  testWidgets('rainy: didUpdateWidget does nothing when already visible',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: AppOverview()));
    await tester.pumpAndSettle();

    final state = tester.state(find.byType(AppOverview)) as dynamic;

    // Simulate already visible
    state._isVisible = true;
    state._titleController.reset();

    state.didUpdateWidget(const AppOverview());
    await tester.pump();

    // No restart
    expect(state._isVisible, isTrue);
    expect(state._titleController.value, equals(0.0));
  });

  testWidgets('sunny: tapping right-arrow advances the carousel dot',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: AppOverview()));
    await tester.pumpAndSettle();

    // Locate all the dot Containers
    Finder dotsRow = find.descendant(
        of: find.byType(Row).last, matching: find.byType(Container));
    final before = tester.widgetList<Container>(dotsRow).toList();
    expect((before[0].decoration as BoxDecoration).color, equals(neonPurple));

    // Tap the right arrow
    await tester.tap(find.byIcon(Icons.arrow_right));
    await tester.pumpAndSettle();

    final after = tester.widgetList<Container>(dotsRow).toList();
    expect((after[1].decoration as BoxDecoration).color, equals(neonPurple));
  });

  testWidgets('rainy: tapping left-arrow on first page keeps dot at 0',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: AppOverview()));
    await tester.pumpAndSettle();

    Finder dotsRow = find.descendant(
        of: find.byType(Row).last, matching: find.byType(Container));
    final before = tester.widgetList<Container>(dotsRow).toList();
    expect((before[0].decoration as BoxDecoration).color, equals(neonPurple));

    // Tap the left arrow
    await tester.tap(find.byIcon(Icons.arrow_left));
    await tester.pumpAndSettle();

    final after = tester.widgetList<Container>(dotsRow).toList();
    expect((after[0].decoration as BoxDecoration).color, equals(neonPurple));
  });
}
