// test/views/custom_login_page_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../util/mock_firebase_util.dart';
import 'package:realest/user_provider.dart';
import 'package:realest/src/views/custom_login_page.dart';

void main() {
  late MockFirebaseAuth mockAuth;
  late FakeFirebaseFirestore mockFirestore;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final mocks = await MockFirebaseUtil.initializeMockFirebase();
    mockAuth = mocks['auth'] as MockFirebaseAuth;
    mockFirestore = mocks['firestore'] as FakeFirebaseFirestore;
  });

  setUp(() {
    mockAuth = MockFirebaseAuth();
    mockFirestore = FakeFirebaseFirestore();
    SharedPreferences.setMockInitialValues({});
  });

  Widget makeApp({Size screenSize = const Size(700, 1200)}) {
    final router = GoRouter(
      initialLocation: '/login',            // ← start here
      routes: [
        GoRoute(
          path: '/login',
          builder: (_, __) => const CustomLoginPage(),
        ),
      ],
    );

    return MediaQuery(
    // ← override the “logical screen” size here
    data: MediaQueryData(
      size: screenSize, // Use the provided screen size
      devicePixelRatio: 1.0,
    ),
    child: MultiProvider(
      providers: [
        Provider<UserProvider>(
          create: (_) => UserProvider(
            auth: mockAuth,
            firestore: mockFirestore,
          ),
        ),
      ],
      child: MaterialApp.router(
        routerConfig: router,
      ),
    ),
  );
    // return MultiProvider(
    //   providers: [
    //     Provider<UserProvider>(
    //       create: (_) => UserProvider(
    //         auth: mockAuth,
    //         firestore: mockFirestore,
    //       ),
    //     ),
    //   ],
    //   child: MaterialApp.router(
    //     routerConfig: router,
    //   ),
    // );
  }

  testWidgets('renders login form by default', (tester) async {
    // 1) Pump the app at /login
    await tester.pumpWidget(makeApp());
    //confirm the app is at /login
    expect(find.byType(CustomLoginPage), findsOneWidget);
    // 2) Advance any delayed builds / animations
    await tester.pump(const Duration(seconds: 2));

    // 3) Verify the login text fields/buttons exist
    expect(find.text('Welcome to RealEst'), findsOneWidget);
    expect(find.text('Please Sign In'), findsOneWidget);
    expect(find.text('LOGIN'), findsOneWidget);
    expect(find.text('Don\'t have an account?'), findsOneWidget);
    expect(find.text('Register'), findsOneWidget);
  });

  testWidgets('toggles between login and register views', (tester) async {
    // choose a < 800 width to hit your mobile branch
    final mobileSize = const Size(700, 1200);

    // 1) Pump the app with a custom MediaQuery size
    await tester.pumpWidget(makeApp(screenSize: mobileSize));
    await tester.pumpAndSettle();

    // 2) Tap the Register toggle
    final registerBtn = find.widgetWithText(TextButton, 'Register');
    await tester.ensureVisible(registerBtn);
    await tester.tap(registerBtn);

    // 3) Advance any delayed fade‐ins (300ms delay + 1s duration)
    await tester.pump(const Duration(milliseconds: 1300));
    await tester.pumpAndSettle();

    // 4) Now your register header is present
    expect(find.text('Create your account'), findsOneWidget);
  });

  // testWidgets('toggles between login and register views', (tester) async {
  //   // 1) Force a mobile screen width (<800) by driving the TestFlutterView
  //   tester.view.physicalSize = const Size(1200, 800);
  //   tester.view.devicePixelRatio = 1.0;
  //   addTearDown(() => tester.view.resetPhysicalSize());
  //   // Removed invalid getter as it is not defined for TestFlutterView

  //   // 2) Pump the app at /login
  //   await tester.pumpWidget(makeApp());
  //   await tester.pumpAndSettle();

  //   // 3) Locate the "Register" toggle button and tap it
  //   final registerBtn = find.widgetWithText(TextButton, 'Register');
  //   await tester.ensureVisible(registerBtn);
  //   await tester.tap(registerBtn);
    
  //   // 4) Advance time for your DelayedFadeIn (300ms delay + 1s fade)
  //   await tester.pump(const Duration(milliseconds: 1300));
  //   await tester.pumpAndSettle();

  //   // 5) Now the register‐view header should be present
  //   expect(find.text('Create your account'), findsOneWidget);
  // });

  // testWidgets('toggles between login and register views', (tester) async {
  //     await tester.pumpWidget(makeApp());
  //     await tester.binding.setSurfaceSize(const Size(1500, 1500));
  //     await tester.pumpAndSettle();

  //     // 2) Find the TextButton by its label
  //     final registerBtn = find.widgetWithText(TextButton, 'Register');

  //     // 3) Scroll it into view (if needed) and tap
  //     await tester.ensureVisible(registerBtn);
  //     await tester.pumpAndSettle();
  //     await tester.tap(registerBtn, warnIfMissed: false);
      
  //     // 4) Wait for any DelayedFadeIn delays + animations
  //     await tester.pump(const Duration(milliseconds: 1300));
  //     await tester.pumpAndSettle();

  //     // 5) Verify the register screen is shown
  //     expect(find.text('Create your account'), findsOneWidget);

  // });

  // testWidgets('shows validation errors for empty fields', (tester) async {
  //   await tester.pumpWidget(makeApp());

  //   // Tap on the login button without entering any data
  //   await tester.tap(find.text('LOGIN'));
  //   await tester.pumpAndSettle();

  //   // Verify validation errors are displayed
  //   expect(find.text('Email is required'), findsOneWidget);
  //   expect(find.text('Password is required'), findsOneWidget);
  // });

  // testWidgets('shows password strength indicator during registration', (tester) async {
  //   await tester.pumpWidget(makeApp());

  //   // Switch to register view
  //   await tester.tap(find.text('Register'));
  //   await tester.pumpAndSettle();

  //   // Enter a weak password
  //   await tester.enterText(find.byType(TextField).at(1), 'weak');
  //   await tester.pumpAndSettle();

  //   // Verify password strength indicator is displayed
  //   expect(find.textContaining('Password Strength: Weak'), findsOneWidget);

  //   // Enter a strong password
  //   await tester.enterText(find.byType(TextField).at(1), 'Strong@123');
  //   await tester.pumpAndSettle();

  //   // Verify password strength indicator updates
  //   expect(find.textContaining('Password Strength: Strong'), findsOneWidget);
  // });

  // testWidgets('displays error message for invalid email format', (tester) async {
  //   await tester.pumpWidget(makeApp());

  //   // Enter an invalid email
  //   await tester.enterText(find.byType(TextField).at(0), 'invalid-email');
  //   await tester.tap(find.text('LOGIN'));
  //   await tester.pumpAndSettle();


  //   // Enter valid registration details
  //   await tester.enterText(find.byType(TextField).at(0), 'test@example.com');
  //   await tester.enterText(find.byType(TextField).at(1), 'Password@123');
  //   await tester.enterText(find.byType(TextField).at(2), 'Password@123');
  //   await tester.tap(find.text('REGISTER'));
  //   await tester.pumpAndSettle();

  //   // Verify navigation to setup page
  //   expect(find.text('Setup your account'), findsOneWidget);
  // });

  // testWidgets('displays error message for Firebase authentication errors', (tester) async {
  //   await tester.pumpWidget(makeApp());

  //   // Enter invalid login details
  //   await tester.enterText(find.byType(TextField).at(0), 'invalid@example.com');
  //   await tester.enterText(find.byType(TextField).at(1), 'wrongpassword');
  //   await tester.tap(find.text('LOGIN'));
  //   await tester.pumpAndSettle();

  //   // Verify error message is displayed
  //   expect(find.textContaining('Invalid Credentials'), findsOneWidget);
  // });

  // testWidgets('navigates to home page for realtor role after login', (tester) async {
  //   await tester.pumpWidget(makeApp());

  //   // Mock user data for realtor role
  //   mockFirestore.collection('users').doc('testUserId').set({
  //     'email': 'realtor@example.com',
  //     'role': 'realtor',
  //     'completedSetup': true,
  //   });

  //   // Enter valid login details
  //   await tester.enterText(find.byType(TextField).at(0), 'realtor@example.com');
  //   await tester.enterText(find.byType(TextField).at(1), 'Password@123');
  //   await tester.tap(find.text('LOGIN'));
  //   await tester.pumpAndSettle();

  //   // Verify navigation to home page
  //   expect(find.text('Welcome to your dashboard'), findsOneWidget);
  // });

  // testWidgets('handles Firebase authentication errors gracefully', (tester) async {
  //   await tester.pumpWidget(makeApp());

  //   // Enter invalid login details
  //   await tester.enterText(find.byType(TextField).at(0), 'invalid@example.com');
  //   await tester.enterText(find.byType(TextField).at(1), 'wrongpassword');
  //   await tester.tap(find.text('LOGIN'));
  //   await tester.pumpAndSettle();

  //   // Verify error message is displayed
  //   expect(find.textContaining('Invalid Credentials'), findsOneWidget);
  // });

  // testWidgets('navigates to home page for investor role after login', (tester) async {
  //   await tester.pumpWidget(makeApp());

  //   // Mock user data for investor role
  //   mockFirestore.collection('users').doc('testInvestorId').set({
  //     'email': 'investor@example.com',
  //     'role': 'investor',
  //     'completedSetup': true,
  //   });

  //   // Enter valid login details
  //   await tester.enterText(find.byType(TextField).at(0), 'investor@example.com');
  //   await tester.enterText(find.byType(TextField).at(1), 'Password@123');
  //   await tester.tap(find.text('LOGIN'));
  //   await tester.pumpAndSettle();

  //   // Verify navigation to home page
  //   expect(find.text('Welcome to your dashboard'), findsOneWidget);
  // });

  // testWidgets('cancels registration and returns to login view', (tester) async {
  //   await tester.pumpWidget(makeApp());

  //   // Switch to register view
  //   await tester.tap(find.text('Register'));
  //   await tester.pumpAndSettle();

  //   // Tap on the 'Sign In' button to cancel registration
  //   await tester.tap(find.text('Sign In'));
  //   await tester.pumpAndSettle();

  //   // Verify state changes back to login view
  //   expect(find.text('Welcome to RealEst'), findsOneWidget);
  //   expect(find.text('Please Sign In'), findsOneWidget);
  //   expect(find.text('LOGIN'), findsOneWidget);
  // });
}