import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:realest/src/views/home/mobile_home_page.dart';
import 'package:go_router/go_router.dart';
import '../../../util/mock_firebase_util.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/animation.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    TestWidgetsFlutterBinding.instance.window.physicalSizeTestValue = const Size(400, 800);
    TestWidgetsFlutterBinding.instance.window.devicePixelRatioTestValue = 1.0;
  });

  tearDownAll(() {
    TestWidgetsFlutterBinding.instance.window.clearPhysicalSizeTestValue();
    TestWidgetsFlutterBinding.instance.window.clearDevicePixelRatioTestValue();
  });

  late GoRouter mockRouter;

  Widget makeApp() {
    mockRouter = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const MobileHomePage(),
          ),
          GoRoute(
            path: '/login',
            builder: (context, state) {
              if (state.uri.queryParameters['register'] == 'true') {
                return const Text('Sign Up Page');
              }
              return const Text('Login Page');
            },
          ),
        ]
      );
    return MediaQuery(
      data: const MediaQueryData(),
      child: MaterialApp.router(
        routerConfig: mockRouter,
      ),
    );
  }

  testWidgets('MobileHomePage displays logo, welcome text, and buttons', (WidgetTester tester) async {
    // Build the widget tree
    await tester.pumpWidget(makeApp());
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.real_estate_agent), findsOneWidget);
    expect(find.text('Welcome to RealEst'), findsOneWidget);
    expect(find.text('Automate Analysis, Multiply Deals'), findsOneWidget);
    expect(find.text('Log In'), findsOneWidget);
    expect(find.text('Sign Up'), findsOneWidget);
  });

  testWidgets('Log In button navigates to login page', (WidgetTester tester) async {
    // Build the widget tree
    // Tap the Log In button
    await tester.pumpWidget(makeApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Log In'));
    await tester.pumpAndSettle();

    // Verify navigation to the login page
    expect(find.text('Login Page'), findsOneWidget);
  });

  testWidgets('Sign Up button navigates to registration page with query parameters', (WidgetTester tester) async {
    // Build the widget tree
    await tester.pumpWidget(makeApp());

    // Ensure animations are completed
    await tester.pump(const Duration(milliseconds: 1200));
    await tester.pumpAndSettle();

    // Tap the Sign Up button
    await tester.tap(find.text('Sign Up'));
    await tester.pumpAndSettle();

    expect(find.text('Sign Up Page'), findsOneWidget);
  });
}