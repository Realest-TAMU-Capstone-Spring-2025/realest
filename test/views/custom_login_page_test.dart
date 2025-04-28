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
    final Size screenSize = const Size(1200, 1200);

    await tester.pumpWidget(makeApp(screenSize: screenSize));
    
    await tester.pump(const Duration(milliseconds: 500));  // Initial pump
    await tester.pump(const Duration(milliseconds: 2000)); // Wait for all delayed animations
    
    expect(find.text('Welcome to RealEst'), findsOneWidget);
    expect(find.text('Please Sign In'), findsOneWidget);
    
    final registerText = find.text('Register');
    expect(registerText, findsOneWidget);
    
    await tester.ensureVisible(registerText);
    await tester.pumpAndSettle();
    
    final registerButton = find.widgetWithText(TextButton, 'Register');
    expect(registerButton, findsOneWidget);
    await tester.tap(registerButton);
    await tester.pump(); // Process the tap
    
    await tester.pump(const Duration(seconds: 2));
    
    expect(find.text('Create your account'), findsOneWidget);
    expect(find.text('Please Sign Up'), findsOneWidget);
  });
}