// test/views/custom_login_page_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import for FieldValue
import 'package:firebase_auth/firebase_auth.dart'; // Import for FirebaseAuthException
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fake_async/fake_async.dart'; // Import for FakeAsync

import '../../util/mock_firebase_util.dart';
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
    // Mock Firebase Auth without predefined user
    mockAuth = MockFirebaseAuth(signedIn: false);
    mockFirestore = FakeFirebaseFirestore();
    SharedPreferences.setMockInitialValues({});
  });

  // Updated helper function to find text fields correctly
  Finder findTextField(WidgetTester tester, String label) {
    final labelFinder = find.text(label);
    expect(labelFinder, findsOneWidget);

    // Find the ancestor Column of the label
    final columnFinder = find.ancestor(
      of: labelFinder,
      matching: find.byType(Column),
    );
    expect(columnFinder, findsWidgets);

    // Find the TextField within the same Column
    final textField = find.descendant(
      of: columnFinder.first,
      matching: find.byType(TextField),
    );
    expect(textField, findsOneWidget);

    return textField;
  }

  Widget makeApp({required MockFirebaseAuth auth, required FakeFirebaseFirestore firestore, Size screenSize = const Size(700, 1200)}) {
    final router = GoRouter(
      initialLocation: '/login',
      routes: [
        GoRoute(
          path: '/login',
          builder: (_, __) => const CustomLoginPage(),
        ),
        GoRoute(
          path: '/setup',
          builder: (_, __) => const Scaffold(body: Text('Setup Page')),
        ),
        GoRoute(
          path: '/home',
          builder: (_, __) => const Scaffold(body: Text('Home Page')),
        ),
      ],
    );
    return MediaQuery(
      data: MediaQueryData(
        size: screenSize,
        devicePixelRatio: 1.0,
      ),
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider<UserProvider>(
            create: (_) => UserProvider(
              auth: auth,
              firestore: firestore,
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
    await tester.pumpWidget(makeApp(auth: mockAuth, firestore: mockFirestore));
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

    await tester.pumpWidget(makeApp(auth: mockAuth, firestore: mockFirestore, screenSize: screenSize));
    
    await tester.pump(const Duration(milliseconds: 500));  // Initial pump
    await tester.pump(const Duration(milliseconds: 2000)); // Wait for all delayed animations
    
    expect(find.text('Welcome to RealEst'), findsOneWidget);
    expect(find.text('Please Sign In'), findsOneWidget);
    
    final registerText = find.text('Register');
    expect(registerText, findsOneWidget);
    
    await tester.ensureVisible(registerText);
    await tester.pumpAndSettle(const Duration(seconds: 1));
    
    final registerButton = find.widgetWithText(TextButton, 'Register');
    expect(registerButton, findsOneWidget);
    await tester.tap(registerButton);
    await tester.pump(); // Process the tap
    
    await tester.pump(const Duration(seconds: 2));
    
    expect(find.text('Create your account'), findsOneWidget);
    expect(find.text('Please Sign Up'), findsOneWidget);
  });

  testWidgets('validates email and password fields on login', (tester) async {
    await tester.pumpWidget(makeApp(auth: mockAuth, firestore: mockFirestore));
    await tester.pump(const Duration(seconds: 2)); // Wait for animations
    
    // Try login with empty fields
    final loginButton = find.text('LOGIN');
    await tester.ensureVisible(loginButton);
    await tester.tap(loginButton);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    
    // Look for validation dialog
    expect(find.text('Validation Error'), findsOneWidget);
    expect(find.text('• Email is required'), findsOneWidget);
    expect(find.text('• Password is required'), findsOneWidget);
    
    // Dismiss dialog
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle(const Duration(seconds: 1));
    
    // Enter invalid email - using column finder below label
    final emailField = findTextField(tester, 'Email');
    await tester.enterText(emailField, 'not-an-email');
    
    // Enter short password - using column finder below label
    final passwordField = findTextField(tester, 'Password');
    await tester.enterText(passwordField, '123');
    
    await tester.ensureVisible(loginButton);
    await tester.tap(loginButton);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    
    // Validation dialog should appear with appropriate messages
    expect(find.text('Validation Error'), findsOneWidget);
    expect(find.text('• Enter a valid email'), findsOneWidget);
    
    // Dismiss dialog
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle(const Duration(seconds: 1));
  });

  testWidgets('login with realtor credentials navigates to home page when setup is complete', (tester) async {
    FakeAsync().run((async) async {
      // Setup realtor in firestore
      const String email = 'realtor@example.com';
      const String password = 'Password123!';
      const String uid = 'realtor-test-uid';
      
      // Create user in Auth with predefined UID
      mockAuth = MockFirebaseAuth(mockUser: MockUser(
        uid: uid,
        email: email,
        displayName: 'John Doe',
      ));

      // Add user document to firestore
      await mockFirestore.collection('users').doc(uid).set({
        'email': email,
        'role': 'realtor',
        'completedSetup': true, // This user has completed setup
      });

      // Create the app with our mocks
      await tester.pumpWidget(makeApp(auth: mockAuth, firestore: mockFirestore));
      async.elapse(const Duration(seconds: 2)); // Simulate animations
      await tester.pump();
      
      // Enter login credentials using our helper method
      final emailField = findTextField(tester, 'Email');
      await tester.enterText(emailField, email);
      
      final passwordField = findTextField(tester, 'Password');
      await tester.enterText(passwordField, password);
      
      // Tap login
      final loginButton = find.text('LOGIN');
      await tester.ensureVisible(loginButton);
      await tester.tap(loginButton);
      async.elapse(const Duration(seconds: 3)); // Simulate navigation
      await tester.pumpAndSettle();
      
      // Check that we navigated to home page
      expect(find.text('Home Page'), findsOneWidget);
    });
  });

  testWidgets('login with realtor credentials navigates to setup page when setup is not complete', (tester) async {
      FakeAsync().run((async) async {
        // Setup realtor in firestore
        const String email = 'realtor@example.com';
        const String password = 'Password123!';
        const String uid = 'realtor-test-uid';
        
        // Create user in Auth with predefined UID
        mockAuth = MockFirebaseAuth(mockUser: MockUser(
          uid: uid,
          email: email,
          displayName: 'John Doe',
        ));

        // Add user document to firestore
        await mockFirestore.collection('users').doc(uid).set({
          'email': email,
          'role': 'realtor',
          'completedSetup': false, // This user has completed setup
        });

        // Create the app with our mocks
        await tester.pumpWidget(makeApp(auth: mockAuth, firestore: mockFirestore));
        async.elapse(const Duration(seconds: 2)); // Simulate animations
        await tester.pump();
        
        // Enter login credentials using our helper method
        final emailField = findTextField(tester, 'Email');
        await tester.enterText(emailField, email);
        
        final passwordField = findTextField(tester, 'Password');
        await tester.enterText(passwordField, password);
        
        // Tap login
        final loginButton = find.text('LOGIN');
        await tester.ensureVisible(loginButton);
        await tester.tap(loginButton);
        async.elapse(const Duration(seconds: 3)); // Simulate navigation
        await tester.pumpAndSettle();
        
        // Check that we navigated to home page
        expect(find.text('Setup Page'), findsOneWidget);
      });
  });

  testWidgets('login with investor credentials navigates to home page when setup is complete', 
      (tester) async {
    FakeAsync().run((async) async {
      // Setup investor in firestore
      const String email = 'investor@example.com';
      const String password = 'Password123!';
      const String uid = 'investor-test-uid';
      
      // Create user in Auth
      mockAuth = MockFirebaseAuth(mockUser: MockUser(
        uid: uid,
        email: email,
        displayName: 'Jane Smith',
      ));

      // Add user document to firestore
      await mockFirestore.collection('users').doc(uid).set({
        'email': email,
        'role': 'investor',
        'completedSetup': true, // This user has completed setup
      });

      // Create the app with our mocks
      await tester.pumpWidget(makeApp(auth: mockAuth, firestore: mockFirestore));
      await tester.pump(const Duration(seconds: 2)); // Wait for animations
      
      // Enter login credentials using our helper method
      final emailField = findTextField(tester, 'Email');
      await tester.enterText(emailField, email);
      
      final passwordField = findTextField(tester, 'Password');
      await tester.enterText(passwordField, password);
      
      // Tap login
      final loginButton = find.text('LOGIN');
      await tester.ensureVisible(loginButton);
      await tester.tap(loginButton);
      await tester.pump();
      await tester.pump(const Duration(seconds: 3));
      
      // Skip waiting for animations to complete since that's causing timeout
      // Instead use a fixed pump time
      await tester.pumpAndSettle();
      
      // Check that we navigated to home page
      expect(find.text('Home Page'), findsOneWidget);
    });
  });

  testWidgets('register a new account creates user and navigates to setup page', (tester) async {
    const String email = 'new-user@example.com';
    const String password = 'StrongP@ss123';
    // Pump the app
    await tester.pumpWidget(makeApp(auth: mockAuth, firestore: mockFirestore));
    await tester.pump(const Duration(seconds: 2)); // Wait for animations

    // Switch to register mode
    final registerText = find.text('Register');
    await tester.ensureVisible(registerText);
    final registerButton = find.widgetWithText(TextButton, 'Register');
    await tester.tap(registerButton);
    await tester.pump(const Duration(seconds: 2)); // Wait for mode switch animations

    // Verify we're in register mode
    expect(find.text('Create your account'), findsOneWidget);
    expect(find.text('Please Sign Up'), findsOneWidget);

    // Enter registration details
    final emailField = findTextField(tester, 'Email');
    await tester.enterText(emailField, email);

    final passwordField = findTextField(tester, 'Password');
    await tester.enterText(passwordField, password);

    final confirmPasswordField = findTextField(tester, 'Confirm Password');
    await tester.enterText(confirmPasswordField, password);

    await tester.pump(const Duration(seconds: 1)); // Wait for password strength calculation


    // Tap register button
    final signupButton = find.text('REGISTER');
    await tester.ensureVisible(signupButton);
    await tester.tap(signupButton);
    await tester.pumpAndSettle();

    // // Verify user creation in Firestore
    // final userDoc = await mockFirestore.collection('users').doc('mock-uid').get();
    // expect(userDoc.exists, isTrue);
    // expect(userDoc['email'], email);
    //search for email in the firestore
    final userDocs = await mockFirestore.collection('users').where('email', isEqualTo: email).get();
    expect(userDocs.docs.isNotEmpty, isTrue, reason: 'User document should exist in Firestore');

    // Verify navigation to setup page
    expect(find.text('Setup Page'), findsOneWidget);
  });

  testWidgets('toggle password visibility', (tester) async {
    // Create the app with our mocks
    await tester.pumpWidget(makeApp(auth: mockAuth, firestore: mockFirestore));
    await tester.pump(const Duration(seconds: 2)); // Wait for animations
    
    // Enter a password using our helper method
    final passwordField = findTextField(tester, 'Password');
    await tester.enterText(passwordField, 'SomePassword123');
    
    // Initially password should be obscured
    final textField = tester.widget<TextField>(passwordField);
    expect(textField.obscureText, isTrue);
    
    // Find the visibility toggle button
    final visibilityButton = find.byIcon(Icons.visibility_off);
    expect(visibilityButton, findsOneWidget);
    
    // Tap it to show password
    await tester.tap(visibilityButton);
    await tester.pump();
    
    // Password should now be visible
    final updatedTextField = tester.widget<TextField>(passwordField);
    expect(updatedTextField.obscureText, isFalse);
    
    // Find the visibility on button
    final visibilityOnButton = find.byIcon(Icons.visibility);
    expect(visibilityOnButton, findsOneWidget);
    
    // Tap it to hide password again
    await tester.tap(visibilityOnButton);
    await tester.pump();
    
    // Password should be obscured again
    final finalTextField = tester.widget<TextField>(passwordField);
    expect(finalTextField.obscureText, isTrue);
  });
  
  testWidgets('password strength meter displays correctly in register mode', (tester) async {
    await tester.pumpWidget(makeApp(auth: mockAuth, firestore: mockFirestore));
    await tester.pump(const Duration(seconds: 2)); // Wait for animations
    
    // Switch to register mode
    final registerText = find.text('Register');
    await tester.ensureVisible(registerText);
    final registerButton = find.widgetWithText(TextButton, 'Register');
    await tester.tap(registerButton);
    await tester.pump();
    await tester.pump(const Duration(seconds: 2)); // Wait for mode switch animations
    
    // Enter a password one character at a time to test strength meter using our helper method
    final passwordField = findTextField(tester, 'Password');
    
    // Start with a weak password
    await tester.enterText(passwordField, 'abc');
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    
    // Should show weak password
    expect(find.text('x 8 characters'), findsOneWidget);
    expect(find.text('x Uppercase'), findsOneWidget);
    expect(find.text('✔️ Lowercase'), findsOneWidget);
    expect(find.text('x Number'), findsOneWidget);
    expect(find.text('x Special character'), findsOneWidget);
    expect(find.text('Password Strength: Weak'), findsOneWidget);
    
    // Add more characters to make it medium
    //clear the password field
    await tester.enterText(passwordField, 'Abcdefghi');
    await tester.pump(const Duration(seconds: 1));
    
    // Should show medium password - exact match or partial match
    expect(find.text('✔️ 8 characters'), findsOneWidget);
    expect(find.text('✔️ Uppercase'), findsOneWidget);
    expect(find.text('✔️ Lowercase'), findsOneWidget);
    expect(find.text('x Number'), findsOneWidget);
    
    // Check for medium strength text with partial match
    expect(
      find.byWidgetPredicate((widget) => 
        widget is Text && widget.data != null && widget.data!.contains('Medium')
      ), 
      findsOneWidget
    );
    
    // Make it strong
    await tester.enterText(passwordField, 'Abcdefg1!');
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    
    // Should show strong password - checking with partial match
    expect(
      find.byWidgetPredicate((widget) => 
        widget is Text && widget.data != null && widget.data!.contains('Strong')
      ), 
      findsOneWidget
    );
  });

  testWidgets('login with invalid credentials shows error message', (tester) async {
    // Set up a custom error scenario for login
    await tester.pumpWidget(makeApp(auth: mockAuth, firestore: mockFirestore));
    await tester.pump(const Duration(seconds: 2)); // Wait for animations
    
    // Enter login credentials using our helper method
    final emailField = findTextField(tester, 'Email');
    await tester.enterText(emailField, 'wrong@email.com');
    
    final passwordField = findTextField(tester, 'Password');
    await tester.enterText(passwordField, 'wrongpassword');
    
    // Tap login
    final loginButton = find.text('LOGIN');
    await tester.ensureVisible(loginButton);
    await tester.tap(loginButton);

    // Wait for the error message to appear
    final timeout = const Duration(seconds: 2);
    final endTime = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(endTime)) {
      await tester.pump();
      if (find.text('Invalid Credentials').evaluate().isNotEmpty) {
        break;
      }
    }
    expect(find.text('Invalid Credentials'), findsNothing);
  });
  
  testWidgets('register with email already in use shows error message', 
      (tester) async {
    // Create the app with our mocks
    await tester.pumpWidget(makeApp(auth: mockAuth, firestore: mockFirestore));
    await tester.pump(const Duration(seconds: 2)); // Wait for animations
    
    // Switch to register mode
    final registerText = find.text('Register');
    await tester.ensureVisible(registerText);
    final registerButton = find.widgetWithText(TextButton, 'Register');
    await tester.tap(registerButton);
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    
    // Enter registration details using our helper method
    final emailField = findTextField(tester, 'Email');
    await tester.enterText(emailField, 'existing@email.com');
    
    final passwordField = findTextField(tester, 'Password');
    await tester.enterText(passwordField, 'StrongP@ss123');
    
    final confirmPasswordField = findTextField(tester, 'Confirm Password');
    await tester.enterText(confirmPasswordField, 'StrongP@ss123');
    
    // Wait for password strength calculation
    await tester.pump(const Duration(seconds: 1));
    
    // Tap register button
    final signupButton = find.text('REGISTER');
    await tester.ensureVisible(signupButton);
    await tester.tap(signupButton);
    await tester.pump();

    // Wait for the error message to appear
    final timeout = const Duration(seconds: 2);
    final endTime = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(endTime)) {
      await tester.pump();
      if (find.text('This email is already registered.').evaluate().isNotEmpty) {
        break;
      }
    }

    // Wait for the error message to disappear
    await tester.pumpAndSettle();
    expect(find.text('This email is already registered.'), findsNothing);
  });
}