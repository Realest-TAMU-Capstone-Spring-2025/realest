import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:realest/src/views/navbar.dart';
import 'package:realest/user_provider.dart';
import '../../util/mock_firebase_util.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';
import 'package:realest/src/views/profile_pic.dart';

void main() {
  late MockFirebaseAuth mockAuth;
  late FakeFirebaseFirestore mockFirestore;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final mocks = await MockFirebaseUtil.initializeMockFirebase();
    mockAuth = mocks['auth'] as MockFirebaseAuth;
    mockFirestore = mocks['firestore'] as FakeFirebaseFirestore;
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> setupRealtor() async {
    const String email = 'realtor@example.com';
    const String uid = 'realtor-test-uid';

    mockAuth = MockFirebaseAuth(mockUser: MockUser(
      uid: uid,
      email: email,
      displayName: 'John Doe',
    ));

    // Sign in the user
    await mockAuth.signOut();
    await mockAuth.signInWithEmailAndPassword(email: email, password: 'password');

    // Set mock data in Firestore
    await mockFirestore.collection('users').doc(uid).set({
      'email': email,
      'role': 'realtor',
      'firstName': 'John',
      'lastName': 'Doe',
      'completedSetup': true,
    });

    // Initialize UserProvider with mock data
    final userProvider = UserProvider(auth: mockAuth, firestore: mockFirestore);
    await userProvider.fetchUserData();
  }

  Future<void> setupInvestor() async {
    const String email = 'investor@example.com';
    const String uid = 'investor-test-uid';

    mockAuth = MockFirebaseAuth(mockUser: MockUser(
      uid: uid,
      email: email,
      displayName: 'Jane Smith',
    ));

    //sign in the user
   
    //sign out any signed in user
    await mockAuth.signOut();
    await mockAuth.signInWithEmailAndPassword(email: email, password: 'password');

    await mockFirestore.collection('users').doc(uid).set({
      'email': email,
      'role': 'investor',
      'completedSetup': true,
    });
  }

  Widget makeApp({required MockFirebaseAuth auth, required FakeFirebaseFirestore firestore, Size screenSize = const Size(700, 1200), bool isDarkMode = false}) {
    final router = GoRouter(
      initialLocation: '/home',
      routes: [
        GoRoute(
          path: '/login',
          builder: (_, __) => Scaffold(
          body: ListView(
            children:[
              Text('Login Page'),
            ], // Added missing closing square bracket
          ),
          ),
        ),
        GoRoute(
          path: '/setup',
          builder: (_, __) => const Scaffold(body: Text('Setup Page')),
        ),
        GoRoute(
          path: '/home',
          builder: (_, __) => Scaffold(
            body: ListView(
              children: [
                Text('Home Page'),
                NavBar(
                  toggleTheme: () => print('Toggle Theme'),
                  isDarkMode: false, // Set the appropriate value for isDarkMode
                ),
              ],
            ),
          ),
        ),
        GoRoute(
          path: '/settings',
          builder: (_, __) => Scaffold(
        body: ListView(
          children:[
            Text('Settings Page'),
            NavBar(
          toggleTheme: () => print('Toggle Theme'),
          isDarkMode: false, // Set the appropriate value for isDarkMode
            ),
          ],
        ),
          ),
        ),
        GoRoute(
          path: '/search',
          builder: (_, __) => Scaffold(
        body: ListView(
          children:[
            Text('Search Page'),
            NavBar(
          toggleTheme: () => print('Toggle Theme'),
          isDarkMode: false, // Set the appropriate value for isDarkMode
            ),
          ],
        ),
          ),
        ),
        GoRoute(
          path: 'calculators',
          builder: (_, __) => Scaffold(
        body: ListView(
          children:[
            Text('Calculators Page'),
            NavBar(
          toggleTheme: () => print('Toggle Theme'),
          isDarkMode: false, // Set the appropriate value for isDarkMode
            ),
          ],
        ),
          ),
        ),
        GoRoute(
          path: '/clients',
          builder: (_, __) => Scaffold(
        body: ListView(
          children:[
            Text('Clients Page'),
            NavBar(
          toggleTheme: () => print('Toggle Theme'),
          isDarkMode: false, // Set the appropriate value for isDarkMode
            ),
          ],
        ),
          ),
        ),
        GoRoute(
          path: '/reports',
          builder: (_, __) => Scaffold(
        body: ListView(
          children:[
            Text('Reports Page'),
            NavBar(
          toggleTheme: () => print('Toggle Theme'),
          isDarkMode: false, // Set the appropriate value for isDarkMode
            ),
          ],
        ),
          ),
        ),
        GoRoute(
          path: '/saved',
          builder: (_, __) => Scaffold(
        body: ListView(
          children:[
            Text('Saved Page'),
            NavBar(
          toggleTheme: () => print('Toggle Theme'),
          isDarkMode: false, // Set the appropriate value for isDarkMode
            ),
          ],
        ),
          ),
        ),
        GoRoute(
          path: '/disliked',
          builder: (_, __) => Scaffold(
        body: ListView(
          children:[
            Text('Disliked Page'),
            NavBar(
          toggleTheme: () => print('Toggle Theme'),
          isDarkMode: false, // Set the appropriate value for isDarkMode
            ),
          ],
        ),
          ),
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

  testWidgets('NavBar displays correctly for realtor on small screens', (tester) async {
    await setupRealtor();
    await tester.pumpWidget(makeApp(auth: mockAuth, firestore: mockFirestore, screenSize: const Size(400, 800)));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 1));

    // // Verify DrawerHeader is displayed
    expect(find.byType(DrawerHeader), findsOneWidget);
    _scaffoldKey.currentState?.openDrawer();
    await tester.pumpAndSettle();
    //manually trigger the drawer
    //click home search
    await tester.tap(find.text('Home Search'));
    await tester.pumpAndSettle();
    expect (find.text('Search Page'), findsOneWidget);
  });

  testWidgets('NavBar displays correctly for investor on small screens', (tester) async {
    await setupInvestor();
    await tester.pumpWidget(makeApp(auth: mockAuth, firestore: mockFirestore, screenSize: const Size(400, 800)));
    await tester.pumpAndSettle();

    expect(find.byType(DrawerHeader), findsOneWidget);
    _scaffoldKey.currentState?.openDrawer();
    await tester.pumpAndSettle();

    // Verify Drawer is displayed
    expect(find.text('My Feed'), findsOneWidget);
    expect(find.text('Home Search'), findsOneWidget);
    expect(find.text('Calculators'), findsOneWidget);
    expect(find.text('Saved'), findsOneWidget);
  });

  testWidgets('NavBar toggles theme when toggleTheme is called', (tester) async {
    bool isDarkMode = false;
    await tester.pumpWidget(makeApp(
      auth: mockAuth,
      firestore: mockFirestore,
      screenSize: const Size(1200, 800), // Set screen size to large
      isDarkMode: isDarkMode,
    ));
    await tester.pumpAndSettle();

    // Simulate theme toggle
    final toggleButton = find.byKey(Key('theme-toggle-button'));
    await tester.ensureVisible(toggleButton); // Ensure the button is visible
    await tester.tap(toggleButton, warnIfMissed: false);
    await tester.pumpAndSettle();
  });

  testWidgets('NavBar shows correct items based on role (realtor)', (tester) async {
    // Test realtor view
    await setupRealtor();
    await tester.pumpWidget(makeApp(auth: mockAuth, firestore: mockFirestore));
    await tester.pumpAndSettle();

    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('Clients'), findsOneWidget);
    expect(find.text('Reports'), findsOneWidget);
  });
  testWidgets('NavBar shows correct items based on role, large screen test (investor)', (tester) async {
    // Test realtor view
    await setupInvestor();
    await tester.pumpWidget(makeApp(auth: mockAuth, firestore: mockFirestore));
    await tester.pumpAndSettle();
    // open the drawer
    _scaffoldKey.currentState?.openDrawer();
    await tester.pumpAndSettle();

    expect(find.text('My Feed'), findsOneWidget);
    expect(find.text('Saved'), findsOneWidget);
    expect(find.text('Calculators'), findsOneWidget);
  });
}