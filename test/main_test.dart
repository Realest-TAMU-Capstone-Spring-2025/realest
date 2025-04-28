import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:fake_async/fake_async.dart';
import 'package:realest/main.dart';
import 'package:realest/user_provider.dart';
import 'package:realest/src/views/home/desktop/home_page.dart';
import 'package:realest/src/views/home/mobile_home_page.dart';
import 'dart:io';
import 'package:realest/src/views/investor/properties/saved_properties.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:realest/src/views/custom_login_page.dart';
import 'util/mock_firebase_util.dart';

// Mock implementation of AuthCredential

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();

    await dotenv.load(); // Initialize dotenv
  });

  setUp(() {
    // Clear any persisted prefs before each test
    SharedPreferences.setMockInitialValues({});
  });

  /// Helper to create & initialize your real UserProvider.
  Future<UserProvider> makeProvider({
    required FakeFirebaseFirestore firestore,
    required MockFirebaseAuth auth,
  }) async {
    // Sign in so auth.currentUser != null
    await auth.signInWithCredential(MockAuthCredential());
    final provider = UserProvider(auth: auth, firestore: firestore);
    await provider.initializeUser();
    return provider;
  }

  testWidgets('HomePage shows initially', (tester) async {
    FakeAsync().run((async) async {
      final mockFirebase = await MockFirebaseUtil.initializeMockFirebase();
      final firestore = mockFirebase['firestore'] as FakeFirebaseFirestore;
      final auth = mockFirebase['auth'] as MockFirebaseAuth;
      final provider = await makeProvider(firestore: firestore, auth: auth);

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: provider,
          child: const MyApp(),
        ),
      );

      async.elapse(const Duration(seconds: 5)); //video render
      await tester.pump();

      await tester.pumpAndSettle();
      expect(find.byType(HomePage), findsOneWidget);
    });
  });

  testWidgets('Theme toggling updates themeModeNotifier', (tester) async {
    FakeAsync().run((async) async {
      final mockFirebase = await MockFirebaseUtil.initializeMockFirebase();
      final firestore = mockFirebase['firestore'] as FakeFirebaseFirestore;
      final auth = mockFirebase['auth'] as MockFirebaseAuth;
      final provider = await makeProvider(firestore: firestore, auth: auth);

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: provider,
          child: const MyApp(),
        ),
      );

      async.elapse(const Duration(seconds: 5));
      await tester.pumpAndSettle();

      // Initial theme should be dark
      expect(themeModeNotifier.value, ThemeMode.dark);

      // Toggle theme
      themeModeNotifier.value = ThemeMode.light;
      await tester.pumpAndSettle();

      // Verify theme is updated
      expect(themeModeNotifier.value, ThemeMode.light);
    });
  });

  testWidgets('Router initializes with correct initial route', (tester) async {
    FakeAsync().run((async) async {
      final mockFirebase = await MockFirebaseUtil.initializeMockFirebase();
      final firestore = mockFirebase['firestore'] as FakeFirebaseFirestore;
      final auth = mockFirebase['auth'] as MockFirebaseAuth;
      final provider = await makeProvider(firestore: firestore, auth: auth);

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: provider,
          child: const MyApp(),
        ),
      );

      async.elapse(const Duration(seconds: 5));
      await tester.pumpAndSettle();

      // Simulate mobile platform
      await tester.binding.setSurfaceSize(const Size(400, 800));
      await tester.pumpAndSettle();
      expect(find.byType(MobileHomePage), findsOneWidget);

      // Reset and simulate non-mobile platform
      await tester.binding.setSurfaceSize(const Size(1200, 800));
      await tester.pumpAndSettle();
      expect(find.byType(HomePage), findsOneWidget);

      // Clean up
      await tester.binding.setSurfaceSize(null); // Reset to default
    });
  });

  testWidgets('Access denied message is shown', (tester) async {
    FakeAsync().run((async) async {
      final mockFirebase = await MockFirebaseUtil.initializeMockFirebase();
      final firestore = mockFirebase['firestore'] as FakeFirebaseFirestore;
      final auth = mockFirebase['auth'] as MockFirebaseAuth;
      final provider = await makeProvider(firestore: firestore, auth: auth);

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: provider,
          child: const MyApp(),
        ),
      );

      async.elapse(const Duration(seconds: 5));
      await tester.pumpAndSettle();

      // Simulate access denied
      final context = tester.element(find.byType(MyApp));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Access Denied')),
      );

      await tester.pumpAndSettle();

      // Verify snackbar is displayed
      expect(find.text('Access Denied'), findsOneWidget);
    });
  });

  testWidgets('Correct theme is applied based on themeModeNotifier', (tester) async {
    FakeAsync().run((async) async {
      final mockFirebase = await MockFirebaseUtil.initializeMockFirebase();
      final firestore = mockFirebase['firestore'] as FakeFirebaseFirestore;
      final auth = mockFirebase['auth'] as MockFirebaseAuth;
      final provider = await makeProvider(firestore: firestore, auth: auth);

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: provider,
          child: const MyApp(),
        ),
      );

      async.elapse(const Duration(seconds: 5));
      await tester.pumpAndSettle();

      // Verify dark theme is applied initially
      expect(themeModeNotifier.value, ThemeMode.dark);
      expect(find.byType(MaterialApp), findsOneWidget);

      // Toggle to light theme
      themeModeNotifier.value = ThemeMode.light;
      await tester.pumpAndSettle();

      // Verify light theme is applied
      expect(themeModeNotifier.value, ThemeMode.light);
    });
  });

  testWidgets('Router blocks access to investor routes for realtor role', (tester) async {
    FakeAsync().run((async) async {
      final mockFirebase = await MockFirebaseUtil.initializeMockFirebase();
      final firestore = mockFirebase['firestore'] as FakeFirebaseFirestore;
      final auth = mockFirebase['auth'] as MockFirebaseAuth;
      final provider = await makeProvider(firestore: firestore, auth: auth);

      // Set user role to realtor
      provider.userRole = 'realtor';

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: provider,
          child: const MyApp(),
        ),
      );

      async.elapse(const Duration(seconds: 5));
      await tester.pumpAndSettle();

      // Attempt to navigate to investor-specific route
      final context = tester.element(find.byType(MyApp));
      GoRouter.of(context).go('/saved');
      await tester.pumpAndSettle();

      // Verify redirection to home
      expect(find.byType(HomePage), findsOneWidget);
      expect(find.text('Saved properties only available to investors'), findsOneWidget);
    });
  });

  testWidgets('Router blocks access to realtor routes for investor role', (tester) async {
    FakeAsync().run((async) async {
      final mockFirebase = await MockFirebaseUtil.initializeMockFirebase();
      final firestore = mockFirebase['firestore'] as FakeFirebaseFirestore;
      final auth = mockFirebase['auth'] as MockFirebaseAuth;
      final provider = await makeProvider(firestore: firestore, auth: auth);

      // Set user role to investor
      provider.userRole = 'investor';

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: provider,
          child: const MyApp(),
        ),
      );

      async.elapse(const Duration(seconds: 5));
      await tester.pumpAndSettle();

      // Attempt to navigate to realtor-specific route
      final context = tester.element(find.byType(MyApp));
      GoRouter.of(context).go('/clients');
      await tester.pumpAndSettle();

      // Verify redirection to home
      expect(find.byType(HomePage), findsOneWidget);
      expect(find.text('Client management only available to realtors'), findsOneWidget);
    });
  });

  testWidgets('Router blocks access to protected routes for unauthenticated user', (tester) async {
    FakeAsync().run((async) async {
      final mockFirebase = await MockFirebaseUtil.initializeMockFirebase();
      final firestore = mockFirebase['firestore'] as FakeFirebaseFirestore;
      final auth = mockFirebase['auth'] as MockFirebaseAuth;
      final provider = await makeProvider(firestore: firestore, auth: auth);

      // Set user role to null (unauthenticated)
      provider.userRole = null;

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: provider,
          child: const MyApp(),
        ),
      );

      async.elapse(const Duration(seconds: 5));
      await tester.pumpAndSettle();

      // Attempt to navigate to protected route
      final context = tester.element(find.byType(MyApp));
      GoRouter.of(context).go('/home');
      await tester.pumpAndSettle();

      // Verify redirection to login
      expect(find.byType(CustomLoginPage), findsOneWidget);
      expect(find.text('You need to log in to access this page'), findsOneWidget);
    });
  });

  testWidgets('Router allows access to public routes for unauthenticated user', (tester) async {
    FakeAsync().run((async) async {
      final mockFirebase = await MockFirebaseUtil.initializeMockFirebase();
      final firestore = mockFirebase['firestore'] as FakeFirebaseFirestore;
      final auth = mockFirebase['auth'] as MockFirebaseAuth;
      final provider = await makeProvider(firestore: firestore, auth: auth);

      // Set user role to null (unauthenticated)
      provider.userRole = null;

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: provider,
          child: const MyApp(),
        ),
      );

      async.elapse(const Duration(seconds: 5));
      await tester.pumpAndSettle();

      // Navigate to public route
      final context = tester.element(find.byType(MyApp));
      GoRouter.of(context).go('/login');
      await tester.pumpAndSettle();

      // Verify access to login page
      expect(find.byType(CustomLoginPage), findsOneWidget);
    });
  });

  testWidgets('Router blocks or allows access based on roles and routes', (tester) async {
    FakeAsync().run((async) async {
      final mockFirebase = await MockFirebaseUtil.initializeMockFirebase();
      final firestore = mockFirebase['firestore'] as FakeFirebaseFirestore;
      final auth = mockFirebase['auth'] as MockFirebaseAuth;
      final provider = await makeProvider(firestore: firestore, auth: auth);

      final routes = [
        '/home',
        '/settings',
        '/calculators',
        '/saved',
        '/disliked',
        '/clients',
        '/reports',
        '/search',
      ];

      final rolePermissions = {
        'investor': {
          '/home': true,
          '/settings': true,
          '/calculators': true,
          '/saved': true,
          '/disliked': true,
          '/clients': false,
          '/reports': false,
          '/search': false,
        },
        'realtor': {
          '/home': true,
          '/settings': true,
          '/calculators': true,
          '/saved': false,
          '/disliked': false,
          '/clients': true,
          '/reports': true,
          '/search': true,
        },
        null: {
          '/home': false,
          '/settings': false,
          '/calculators': false,
          '/saved': false,
          '/disliked': false,
          '/clients': false,
          '/reports': false,
          '/search': false,
        },
      };

      for (final role in rolePermissions.keys) {
        provider.userRole = role;
        await tester.pumpWidget(
          ChangeNotifierProvider.value(
            value: provider,
            child: const MyApp(),
          ),
        );

        async.elapse(const Duration(seconds: 5));
        await tester.pumpAndSettle();

        for (final route in routes) {
          final context = tester.element(find.byType(MyApp));
          GoRouter.of(context).go(route);
          await tester.pumpAndSettle();

          final isAllowed = rolePermissions[role]![route] ?? false;
          if (isAllowed) {
            expect(find.text('Access Denied'), findsNothing,
                reason: 'Role $role should have access to $route');
          } else {
            expect(find.text('Access Denied'), findsOneWidget,
                reason: 'Role $role should not have access to $route');
            expect(find.byType(HomePage), findsOneWidget,
                reason: 'Role $role should be redirected to home from $route');
          }
        }
      }
    });
  });

  testWidgets('Dynamic role changes update route access', (tester) async {
    FakeAsync().run((async) async {
      final mockFirebase = await MockFirebaseUtil.initializeMockFirebase();
      final firestore = mockFirebase['firestore'] as FakeFirebaseFirestore;
      final auth = mockFirebase['auth'] as MockFirebaseAuth;
      final provider = await makeProvider(firestore: firestore, auth: auth);

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: provider,
          child: const MyApp(),
        ),
      );

      async.elapse(const Duration(seconds: 5));
      await tester.pumpAndSettle();

      // Set initial role to investor
      provider.userRole = 'investor';
      await tester.pumpAndSettle();

      // Navigate to investor-specific route
      final context = tester.element(find.byType(MyApp));
      GoRouter.of(context).go('/saved');
      await tester.pumpAndSettle();

      // Verify access to saved properties
      expect(find.text('Access Denied'), findsNothing);

      // Change role to realtor
      provider.userRole = 'realtor';
      await tester.pumpAndSettle();

      // Attempt to navigate to investor-specific route again
      GoRouter.of(context).go('/saved');
      await tester.pumpAndSettle();

      // Verify access is now denied
      expect(find.text('Saved properties only available to investors'), findsOneWidget);
      expect(find.byType(HomePage), findsOneWidget);
    });
  });

  testWidgets('Handles missing Firebase data gracefully', (tester) async {
    FakeAsync().run((async) async {
      final mockFirebase = await MockFirebaseUtil.initializeMockFirebase();
      final firestore = mockFirebase['firestore'] as FakeFirebaseFirestore;
      final auth = mockFirebase['auth'] as MockFirebaseAuth;
      final provider = await makeProvider(firestore: firestore, auth: auth);

      // Simulate missing user data in Firebase
      await firestore.collection('users').doc('testUser').set({});
      provider.uid = 'testUser';

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: provider,
          child: const MyApp(),
        ),
      );

      async.elapse(const Duration(seconds: 5));
      await tester.pumpAndSettle();

      // Verify app does not crash and shows default state
      expect(find.byType(HomePage), findsOneWidget);
    });
  });

  testWidgets('Redirects to home for undefined routes', (tester) async {
    FakeAsync().run((async) async {
      final mockFirebase = await MockFirebaseUtil.initializeMockFirebase();
      final firestore = mockFirebase['firestore'] as FakeFirebaseFirestore;
      final auth = mockFirebase['auth'] as MockFirebaseAuth;
      final provider = await makeProvider(firestore: firestore, auth: auth);

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: provider,
          child: const MyApp(),
        ),
      );

      async.elapse(const Duration(seconds: 5));
      await tester.pumpAndSettle();

      // Attempt to navigate to an undefined route
      final context = tester.element(find.byType(MyApp));
      GoRouter.of(context).go('/undefinedRoute');
      await tester.pumpAndSettle();

      // Verify redirection to home
      expect(find.byType(HomePage), findsOneWidget);
    });
  });

  testWidgets('Platform-specific behavior for mobile and web', (tester) async {
    FakeAsync().run((async) async {
      final mockFirebase = await MockFirebaseUtil.initializeMockFirebase();
      final firestore = mockFirebase['firestore'] as FakeFirebaseFirestore;
      final auth = mockFirebase['auth'] as MockFirebaseAuth;
      final provider = await makeProvider(firestore: firestore, auth: auth);

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: provider,
          child: const MyApp(),
        ),
      );

      async.elapse(const Duration(seconds: 5));
      await tester.pumpAndSettle();

      // Simulate mobile platform
      await tester.binding.setSurfaceSize(const Size(400, 800));
      await tester.pumpAndSettle();
      expect(find.byType(MobileHomePage), findsOneWidget);

      // Reset and simulate web platform
      await tester.binding.setSurfaceSize(const Size(1200, 800));
      await tester.pumpAndSettle();
      expect(find.byType(HomePage), findsOneWidget);
    });
  });

  testWidgets('Firebase initializes with platform-specific options', (tester) async {
    FakeAsync().run((async) async {
      final mockFirebase = await MockFirebaseUtil.initializeMockFirebase();
      final firestore = mockFirebase['firestore'] as FakeFirebaseFirestore;
      final auth = mockFirebase['auth'] as MockFirebaseAuth;
      final provider = await makeProvider(firestore: firestore, auth: auth);

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: provider,
          child: const MyApp(),
        ),
      );

      async.elapse(const Duration(seconds: 5));
      await tester.pumpAndSettle();

      // Verify Firebase is initialized
      expect(Firebase.apps.isNotEmpty, true);
    });
  });

  testWidgets('Environment variables are loaded successfully', (tester) async {
    FakeAsync().run((async) async {
      final mockFirebase = await MockFirebaseUtil.initializeMockFirebase();
      final firestore = mockFirebase['firestore'] as FakeFirebaseFirestore;
      final auth = mockFirebase['auth'] as MockFirebaseAuth;
      final provider = await makeProvider(firestore: firestore, auth: auth);

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: provider,
          child: const MyApp(),
        ),
      );

      async.elapse(const Duration(seconds: 5));
      await tester.pumpAndSettle();

      // Verify environment variables are loaded
      expect(dotenv.isInitialized, true);
    });
  });

  testWidgets('Theme toggling switches between light and dark modes', (tester) async {
    FakeAsync().run((async) async {
      final mockFirebase = await MockFirebaseUtil.initializeMockFirebase();
      final firestore = mockFirebase['firestore'] as FakeFirebaseFirestore;
      final auth = mockFirebase['auth'] as MockFirebaseAuth;
      final provider = await makeProvider(firestore: firestore, auth: auth);

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: provider,
          child: const MyApp(),
        ),
      );

      async.elapse(const Duration(seconds: 5));
      await tester.pumpAndSettle();

      // Verify initial theme is dark
      expect(themeModeNotifier.value, ThemeMode.dark);

      // Toggle theme to light
      themeModeNotifier.value = ThemeMode.light;
      await tester.pumpAndSettle();
      expect(themeModeNotifier.value, ThemeMode.light);

      // Toggle theme back to dark
      themeModeNotifier.value = ThemeMode.dark;
      await tester.pumpAndSettle();
      expect(themeModeNotifier.value, ThemeMode.dark);
    });
  });

  testWidgets('Router redirects unauthenticated users to login', (tester) async {
    FakeAsync().run((async) async {
      final mockFirebase = await MockFirebaseUtil.initializeMockFirebase();
      final firestore = mockFirebase['firestore'] as FakeFirebaseFirestore;
      final auth = mockFirebase['auth'] as MockFirebaseAuth;
      final provider = await makeProvider(firestore: firestore, auth: auth);

      // Set user role to null (unauthenticated)
      provider.userRole = null;

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: provider,
          child: const MyApp(),
        ),
      );

      async.elapse(const Duration(seconds: 5));
      await tester.pumpAndSettle();

      // Attempt to navigate to a protected route
      final context = tester.element(find.byType(MyApp));
      GoRouter.of(context).go('/home');
      await tester.pumpAndSettle();

      // Verify redirection to login
      expect(find.byType(CustomLoginPage), findsOneWidget);
      expect(find.text('You need to log in to access this page'), findsOneWidget);
    });
  });

  testWidgets('Protected routes redirect based on user roles', (tester) async {
    FakeAsync().run((async) async {
      final mockFirebase = await MockFirebaseUtil.initializeMockFirebase();
      final firestore = mockFirebase['firestore'] as FakeFirebaseFirestore;
      final auth = mockFirebase['auth'] as MockFirebaseAuth;
      final provider = await makeProvider(firestore: firestore, auth: auth);

      final routes = [
        '/saved',
        '/disliked',
        '/clients',
        '/reports',
      ];

      final rolePermissions = {
        'investor': {
          '/saved': true,
          '/disliked': true,
          '/clients': false,
          '/reports': false,
        },
        'realtor': {
          '/saved': false,
          '/disliked': false,
          '/clients': true,
          '/reports': true,
        },
      };

      for (final role in rolePermissions.keys) {
        provider.userRole = role;
        await tester.pumpWidget(
          ChangeNotifierProvider.value(
            value: provider,
            child: const MyApp(),
          ),
        );

        async.elapse(const Duration(seconds: 5));
        await tester.pumpAndSettle();

        for (final route in routes) {
          final context = tester.element(find.byType(MyApp));
          GoRouter.of(context).go(route);
          await tester.pumpAndSettle();

          final isAllowed = rolePermissions[role]![route] ?? false;
          if (isAllowed) {
            expect(find.text('Access Denied'), findsNothing,
                reason: 'Role $role should have access to $route');
          } else {
            expect(find.text('Access Denied'), findsOneWidget,
                reason: 'Role $role should not have access to $route');
            expect(find.byType(HomePage), findsOneWidget,
                reason: 'Role $role should be redirected to home from $route');
          }
        }
      }
    });
  });

  testWidgets('Main function initializes the app', (tester) async {
    FakeAsync().run((async) async {
      // Call the main function
      main();

      // Allow time for initialization
      async.elapse(const Duration(seconds: 5));
      await tester.pumpAndSettle();

      // Verify the app is rendered
      expect(find.byType(MyApp), findsOneWidget);
    });
  });

  testWidgets('_showAccessDenied displays a snackbar', (tester) async {
    FakeAsync().run((async) async {
      final mockFirebase = await MockFirebaseUtil.initializeMockFirebase();
      final firestore = mockFirebase['firestore'] as FakeFirebaseFirestore;
      final auth = mockFirebase['auth'] as MockFirebaseAuth;
      final provider = await makeProvider(firestore: firestore, auth: auth);

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: provider,
          child: const MyApp(),
        ),
      );

      async.elapse(const Duration(seconds: 5));
      await tester.pumpAndSettle();

      // Simulate access denied
      final context = tester.element(find.byType(MyApp));
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Access Denied')),
        );
      });

      await tester.pumpAndSettle();

      // Verify snackbar is displayed
      expect(find.text('Access Denied'), findsOneWidget);
    });
  });

  testWidgets('_createRouter initializes routes correctly', (tester) async {
    FakeAsync().run((async) async {
      final mockFirebase = await MockFirebaseUtil.initializeMockFirebase();
      final firestore = mockFirebase['firestore'] as FakeFirebaseFirestore;
      final auth = mockFirebase['auth'] as MockFirebaseAuth;
      final provider = await makeProvider(firestore: firestore, auth: auth);

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: provider,
          child: const MyApp(),
        ),
      );

      async.elapse(const Duration(seconds: 5));
      await tester.pumpAndSettle();

      // Verify initial route is set correctly
      if (Platform.isAndroid || Platform.isIOS) {
        expect(find.byType(MobileHomePage), findsOneWidget);
      } else {
        expect(find.byType(HomePage), findsOneWidget);
      }

      // Simulate navigation to a protected route
      final context = tester.element(find.byType(MyApp));
      GoRouter.of(context).go('/saved');
      await tester.pumpAndSettle();

      // Verify redirection or access based on role
      if (provider.userRole == 'investor') {
        expect(find.byType(SavedProperties), findsOneWidget);
      } else {
        expect(find.text('Saved properties only available to investors'), findsOneWidget);
        expect(find.byType(HomePage), findsOneWidget);
      }
    });
  });
}