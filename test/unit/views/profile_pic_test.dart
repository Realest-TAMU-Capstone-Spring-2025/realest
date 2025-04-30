import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:realest/user_provider.dart';
import 'package:realest/src/views/profile_pic.dart';
import '../../util/mock_firebase_util.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    SharedPreferences.setMockInitialValues({});
  });

  group('ProfilePic Widget Tests', () {
    late UserProvider mockUserProvider;

    setUp(() {
      //create dummy and then load into userprovider
      //sign in as realtor
      mockUserProvider = UserProvider(
        auth: mockAuth,
        firestore: mockFirestore,
      );
      mockAuth.signInWithEmailAndPassword(
        email: 'realtor@example.com',
        password: 'password123',
      );
      mockUserProvider.fetchUserData();
    });

    testWidgets('Displays profile picture from URL', (WidgetTester tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<UserProvider>.value(
          value: mockUserProvider,
          child: MaterialApp(
            home: ProfilePic(
              toggleTheme: () {},
              onAccountSettings: () {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle(); // Ensure all async operations are completed

      final profileImage = find.byType(CircleAvatar);
      expect(profileImage, findsOneWidget);
    });

    testWidgets('Displays default profile picture when URL is empty', (WidgetTester tester) async {
      mockUserProvider.profilePic = '';

      await tester.pumpWidget(
        ChangeNotifierProvider<UserProvider>.value(
          value: mockUserProvider,
          child: MaterialApp(
            home: ProfilePic(
              toggleTheme: () {},
              onAccountSettings: () {},
            ),
          ),
        ),
      );

      final defaultImage = find.byType(CircleAvatar);
      expect(defaultImage, findsOneWidget);
    });

    testWidgets('Account settings button triggers callback', (WidgetTester tester) async {
      bool accountSettingsCalled = false;

      await tester.pumpWidget(
        ChangeNotifierProvider<UserProvider>.value(
          value: mockUserProvider,
          child: MaterialApp(
            home: ProfilePic(
              toggleTheme: () {},
              onAccountSettings: () {
                accountSettingsCalled = true;
              },
            ),
          ),
        ),
      );

      final profileImage = find.byType(CircleAvatar);
      await tester.tap(profileImage);
      await tester.pumpAndSettle();

      final accountSettingsButton = find.text('Account Settings');
      await tester.tap(accountSettingsButton);
      await tester.pumpAndSettle();

      expect(accountSettingsCalled, isTrue);
    });

    testWidgets('Toggle theme switch triggers callback', (WidgetTester tester) async {
      bool toggleThemeCalled = false;

      await tester.pumpWidget(
        ChangeNotifierProvider<UserProvider>.value(
          value: mockUserProvider,
          child: MaterialApp(
            home: ProfilePic(
              toggleTheme: () {
                toggleThemeCalled = true;
              },
              onAccountSettings: () {},
            ),
          ),
        ),
      );

      final profileImage = find.byType(CircleAvatar);
      await tester.tap(profileImage);
      await tester.pumpAndSettle();

      final toggleThemeSwitch = find.text('Dark Mode');
      await tester.tap(toggleThemeSwitch);
      await tester.pumpAndSettle();

      expect(toggleThemeCalled, isTrue);
    });
  });
}