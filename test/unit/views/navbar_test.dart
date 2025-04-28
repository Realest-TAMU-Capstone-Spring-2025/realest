import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:realest/src/views/navbar.dart';
import 'package:realest/user_provider.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import '../../util/mock_firebase_util.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final mockFirebase = await MockFirebaseUtil.initializeMockFirebase();
    final firestore = mockFirebase['firestore'] as FakeFirebaseFirestore;
    final auth = mockFirebase['auth'] as MockFirebaseAuth;

    // Use the initialized mock Firebase instances
    final userProvider = UserProvider(auth: auth, firestore: firestore);
    await userProvider.initializeUser();
  });

  Future<UserProvider> makeProvider({
    required FakeFirebaseFirestore firestore,
    required MockFirebaseAuth auth,
  }) async {
    await auth.signInWithCredential(MockAuthCredential());
    final provider = UserProvider(auth: auth, firestore: firestore);
    await provider.initializeUser();
    return provider;
  }

  group('NavBar Widget Tests', () {
    late FakeFirebaseFirestore firestore;
    late MockFirebaseAuth auth;
    late UserProvider userProvider;

    setUp(() async {
      firestore = FakeFirebaseFirestore();
      auth = MockFirebaseAuth();
      userProvider = await makeProvider(firestore: firestore, auth: auth);
    });

    testWidgets('renders drawer on small screens', (WidgetTester tester) async {
      userProvider.userRole = 'investor';

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<UserProvider>.value(value: userProvider),
          ],
          child: MaterialApp(
            home: MediaQuery(
              data: const MediaQueryData(size: Size(400, 800)),
              child: NavBar(
                toggleTheme: () {},
                isDarkMode: true,
              ),
            ),
          ),
        ),
      );

      // Verify drawer is rendered
      expect(find.byType(Drawer), findsOneWidget);
    });

    testWidgets('renders sidebar on large screens', (WidgetTester tester) async {
      userProvider.userRole = 'realtor';

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<UserProvider>.value(value: userProvider),
          ],
          child: MaterialApp(
            home: MediaQuery(
              data: const MediaQueryData(size: Size(1200, 800)),
              child: NavBar(
                toggleTheme: () {},
                isDarkMode: true,
              ),
            ),
          ),
        ),
      );

      // Verify sidebar is rendered
      expect(find.byType(AnimatedContainer), findsOneWidget);
    });

    testWidgets('displays correct navigation items for realtor role', (WidgetTester tester) async {
      userProvider.userRole = 'realtor';

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<UserProvider>.value(value: userProvider),
          ],
          child: MaterialApp(
            home: NavBar(
              toggleTheme: () {},
              isDarkMode: true,
            ),
          ),
        ),
      );

      // Verify realtor-specific navigation items
      expect(find.text('Dashboard'), findsOneWidget);
      expect(find.text('Clients'), findsOneWidget);
      expect(find.text('Reports'), findsOneWidget);
      expect(find.text('Saved'), findsNothing);
    });

    testWidgets('displays correct navigation items for investor role', (WidgetTester tester) async {
      userProvider.userRole = 'investor';

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<UserProvider>.value(value: userProvider),
          ],
          child: MaterialApp(
            home: NavBar(
              toggleTheme: () {},
              isDarkMode: true,
            ),
          ),
        ),
      );

      // Verify investor-specific navigation items
      expect(find.text('My Feed'), findsOneWidget);
      expect(find.text('Saved'), findsOneWidget);
      expect(find.text('Clients'), findsNothing);
    });

    testWidgets('toggles sidebar expansion', (WidgetTester tester) async {
      userProvider.userRole = 'realtor';

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<UserProvider>.value(value: userProvider),
          ],
          child: MaterialApp(
            home: NavBar(
              toggleTheme: () {},
              isDarkMode: true,
            ),
          ),
        ),
      );

      // Verify initial state
      expect(find.byIcon(Icons.arrow_forward_ios), findsOneWidget);

      // Tap to expand sidebar
      await tester.tap(find.byIcon(Icons.arrow_forward_ios));
      await tester.pumpAndSettle();

      // Verify expanded state
      expect(find.byIcon(Icons.arrow_back_ios), findsOneWidget);
    });
  });
}