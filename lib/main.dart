import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:realest/firebase_options.dart';
import 'package:realest/src/views/home/overview/overview_page.dart';

// Views related to the investor
import 'package:realest/src/views/investor/investor_settings.dart';
import 'package:realest/src/views/investor/investor_setup.dart';
import 'package:realest/src/views/investor/properties/saved_properties.dart';
import 'package:realest/src/views/investor/swiping/property_swiping.dart';

// Views related to the realtor
import 'package:realest/src/views/realtor/dashboard/realtor_dashboard.dart';
import 'package:realest/src/views/realtor/home search/realtor_home_search.dart';
import 'package:realest/src/views/realtor/realtor_setup.dart';
import 'package:realest/src/views/calculators/calculators.dart';
import 'package:realest/src/views/realtor/clients/realtor_clients.dart';
import 'package:realest/src/views/realtor/realtor_reports.dart';
import 'package:realest/src/views/realtor/realtor_settings.dart';

// Common views
import 'package:realest/src/views/custom_login_page.dart';
import 'package:realest/src/views/navbar.dart'; // Sidebar navigation

// Provider and user-related imports
import 'user_provider.dart';

final ValueNotifier<ThemeMode> themeModeNotifier = ValueNotifier(ThemeMode.light);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) {
            final userProvider = UserProvider();
            userProvider.fetchUserData(); // Fetch user data on app start
            return userProvider;
          },
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = _createRouter(
          () {
        setState(() {
          themeModeNotifier.value = themeModeNotifier.value == ThemeMode.light
              ? ThemeMode.dark
              : ThemeMode.light;
        });
      },
      themeModeNotifier.value,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeModeNotifier,
      builder: (context, themeMode, child) {
        return MaterialApp.router(
          debugShowCheckedModeBanner: false,
          themeMode: themeMode,
          theme: _lightTheme(),
          darkTheme: _darkTheme(),
          routerConfig: _router,
        );
      },
    );
  }

  GoRouter _createRouter(VoidCallback toggleTheme, ThemeMode themeMode) {
    return GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const HomePage(),
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) => const CustomLoginPage(),
        ),
        // Investor routes with navbar
        ShellRoute(
          builder: (context, state, child) => MainLayout(
            child: child,
            toggleTheme: toggleTheme,
            themeMode: themeMode,
          ),
          routes: [
            GoRoute(
              path: '/investorHome',
              builder: (context, state) => const PropertySwipingView(),
            ),
            GoRoute(
              path: '/investorSettings',
              builder: (context, state) => InvestorSettings(
                toggleTheme: toggleTheme,
                isDarkMode: themeMode == ThemeMode.dark,
              ),
            ),
            GoRoute(
              path: '/investorCalculators',
              builder: (context, state) => const Calculators(),
            ),
            GoRoute(
              path: '/investorSavedProperties',
              builder: (context, state) => SavedProperties(),
            ),
          ],
        ),
        // Realtor routes with navbar
        ShellRoute(
          builder: (context, state, child) => MainLayout(
            child: child,
            toggleTheme: toggleTheme,
            themeMode: themeMode,
          ),
          routes: [
            GoRoute(
              path: '/realtorDashboard',
              builder: (context, state) => RealtorDashboard(
                toggleTheme: toggleTheme,
                isDarkMode: themeMode == ThemeMode.dark,
              ),
            ),
            GoRoute(
              path: '/realtorCalculators',
              builder: (context, state) => const Calculators(),
            ),
            GoRoute(
              path: '/realtorClients',
              builder: (context, state) => const RealtorClients(),
            ),
            GoRoute(
              path: '/realtorReports',
              builder: (context, state) => const RealtorReports(),
            ),
            GoRoute(
              path: '/realtorHomeSearch',
              builder: (context, state) => const RealtorHomeSearch(),
            ),
            GoRoute(
              path: '/realtorSettings',
              builder: (context, state) => RealtorSettings(
                toggleTheme: toggleTheme,
                isDarkMode: themeMode == ThemeMode.dark,
              ),
            ),
          ],
        ),
        // Setup routes without navbar (standalone)
        GoRoute(
          path: '/investorSetup',
          builder: (context, state) => const InvestorSetupPage(),
        ),
        GoRoute(
          path: '/realtorSetup',
          builder: (context, state) => const RealtorSetupPage(),
        ),
      ],
      debugLogDiagnostics: true,
    );
  }
}

class AuthWrapper extends StatelessWidget {
  final VoidCallback toggleTheme;
  final ThemeMode themeMode;

  const AuthWrapper({Key? key, required this.toggleTheme, required this.themeMode}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(), // More stable than idTokenChanges
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final user = snapshot.data;
        if (user == null) {
          return const CustomLoginPage();
        }

        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
          builder: (context, userSnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(body: Center(child: CircularProgressIndicator()));
            }

            if (userSnapshot.hasData && userSnapshot.data!.exists) {
              final role = userSnapshot.data!['role'];
              final currentPath = GoRouterState.of(context).uri.path;

              // Only redirect if on a non-role-specific route
              if (role == 'investor' && !currentPath.startsWith('/investor')) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  context.go('/investorHome');
                });
                return const PropertySwipingView();
              } else if (role == 'realtor' && !currentPath.startsWith('/realtor')) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  context.go('/realtorDashboard');
                });
                return RealtorDashboard(toggleTheme: toggleTheme, isDarkMode: themeMode == ThemeMode.dark);
              }

              // If already on a valid route, return the current page
              return MainLayout(
                child: const SizedBox(), // Placeholder, actual child comes from router
                toggleTheme: toggleTheme,
                themeMode: themeMode,
              );
            }

            return const CustomLoginPage();
          },
        );
      },
    );
  }
}

class MainLayout extends StatelessWidget {
  final Widget child;
  final VoidCallback toggleTheme;
  final ThemeMode themeMode;

  MainLayout({required this.child, required this.toggleTheme, required this.themeMode, Key? key})
      : super(key: key);

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    bool isSmallScreen = MediaQuery.of(context).size.width < 800;

    return Scaffold(
      key: _scaffoldKey,
      appBar: isSmallScreen
          ? AppBar(
        title: const Text("RealEst"),
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
      )
          : null,
      drawer: isSmallScreen
          ? Drawer(
        child: NavBar(
          toggleTheme: toggleTheme,
          isDarkMode: themeMode == ThemeMode.dark,
        ),
      )
          : null,
      body: Row(
        children: [
          if (!isSmallScreen)
            NavBar(
              toggleTheme: toggleTheme,
              isDarkMode: themeMode == ThemeMode.dark,
            ),
          Expanded(child: child),
        ],
      ),
    );
  }
}

ThemeData _lightTheme() {
  return ThemeData(
    primaryColor: Colors.black,
    scaffoldBackgroundColor: Colors.white24,
    cardColor: Colors.grey[200],
    colorScheme: const ColorScheme.light(
      primary: Colors.deepPurple,
      secondary: Colors.black87,
      surface: Colors.white,
      surfaceVariant: Colors.black,
      onSurface: Colors.black,
      onTertiary: Colors.white38,
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Colors.black),
      bodyMedium: TextStyle(color: Colors.black87),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.grey.shade100,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      hintStyle: TextStyle(color: Colors.grey[500]),
      labelStyle: const TextStyle(fontWeight: FontWeight.normal),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
  );
}

ThemeData _darkTheme() {
  return ThemeData(
    primaryColor: Colors.white,
    scaffoldBackgroundColor: Colors.black54,
    cardColor: Colors.grey[900],
    colorScheme: const ColorScheme.dark(
      primary: Colors.deepPurpleAccent,
      secondary: Colors.white70,
      surfaceVariant: Colors.black,
      surface: Colors.black,
      onSurface: Colors.white,
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Colors.white),
      bodyMedium: TextStyle(color: Colors.white70),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.grey.shade100,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      hintStyle: TextStyle(color: Colors.grey[500]),
      labelStyle: const TextStyle(fontWeight: FontWeight.normal),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.deepPurpleAccent,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14),
        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    ),
  );
}