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
  await FirebaseAuth.instance.setPersistence(Persistence.LOCAL);
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) => UserProvider()..initializeUser(),
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
  void redirectToHomeWithNotification(BuildContext context, {String message = 'Access Denied'}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
      ),
    );

    context.go('/home');
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
          path: '/loading',
          builder: (context, state) => const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          ),
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) => const CustomLoginPage(),
        ),
        ShellRoute(
          builder: (context, state, child) => MainLayout(
            child: child,
            toggleTheme: toggleTheme,
            themeMode: themeMode,
          ),
          routes: [
            // Shared endpoints with role-based content
            GoRoute(
              path: '/home',
              builder: (context, state) {
                final userProvider = Provider.of<UserProvider>(context, listen: false);
                print(userProvider.userRole);
                return userProvider.userRole == 'investor'
                    ? const PropertySwipingView()
                    : RealtorDashboard(
                        toggleTheme: toggleTheme,
                        isDarkMode: themeMode == ThemeMode.dark,
                      );
              },
            ),
            GoRoute(
              path: '/setup',
              builder: (context, state) {
                final userProvider = Provider.of<UserProvider>(context, listen: false);
                return userProvider.userRole == 'investor'
                    ? const InvestorSetupPage()
                    : const RealtorSetupPage();
              },
            ),
            GoRoute(
              path: '/settings',
              builder: (context, state) {
                final userProvider = Provider.of<UserProvider>(context, listen: false);
                return userProvider.userRole == 'investor'
                    ? InvestorSettings(
                        toggleTheme: toggleTheme,
                        isDarkMode: themeMode == ThemeMode.dark,
                      )
                    : RealtorSettings(
                        toggleTheme: toggleTheme,
                        isDarkMode: themeMode == ThemeMode.dark,
                      );
              },
            ),
            GoRoute(
              path: '/calculators',
              builder: (context, state) => const Calculators(),
            ),

            // Investor-specific routes
            GoRoute(
              path: '/saved',
              builder: (context, state) => _roleProtectedView(
                context,
                allowedRole: 'investor',
                view: SavedProperties(),
                fallbackMessage: 'Saved properties only available to investors',
              ),
            ),

            // Realtor-specific routes
            GoRoute(
              path: '/clients',
              builder: (context, state) => _roleProtectedView(
                context,
                allowedRole: 'realtor',
                view: const RealtorClients(),
                fallbackMessage: 'Client management only available to realtors',
              ),
            ),
            GoRoute(
              path: '/reports',
              builder: (context, state) => _roleProtectedView(
                context,
                allowedRole: 'realtor',
                view: const RealtorReports(),
                fallbackMessage: 'Reports only available to realtors',
              ),
            ),
            GoRoute(
              path: '/search',
              builder: (context, state) => _roleProtectedView(
                context,
                allowedRole: 'realtor',
                view: const RealtorHomeSearch(),
                fallbackMessage: 'Property search only available to realtors',
              ),
            ),
          ],
        ),
      ],
      redirect: (context, state) async {
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        final isLoggedIn = userProvider.uid != null;
        final currentPath = state.uri.toString();

        if (userProvider.isLoading) {
          return '/loading';
        }

        if (isLoggedIn && userProvider.userRole == null) {
          await userProvider.fetchUserData();
          if (userProvider.userRole == null) {
            return '/login';
          }
        }

        if (!currentPath.startsWith('/login') && !isLoggedIn) {
          return '/login';
        }

        if (isLoggedIn) {
          final userRole = userProvider.userRole!;
          final validPaths = _getAllowedPaths(userRole);
          
          if (!validPaths.contains(currentPath)) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Redirected: $currentPath unavailable')),
              );
            });
            return '/home';
          }
        }

        return null;
      },
    );
  }

  List<String> _getAllowedPaths(String userRole) {
    const sharedPaths = ['/home', '/setup', '/settings', '/calculators', '/login', '/loading'];
    final roleSpecificPaths = {
      'investor': ['/saved'],
      'realtor': ['/clients', '/reports', '/search']
    };
    return [...sharedPaths, ...roleSpecificPaths[userRole] ?? []];
  }

  Widget _roleProtectedView(
    BuildContext context, {
    required String allowedRole,
    required Widget view,
    required String fallbackMessage,
  }) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    
    if (userProvider.userRole != allowedRole) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(fallbackMessage)),
        );
        context.go('/home');
      });
      return const SizedBox.shrink(); // Temporary empty widget
    }
    
    return view;
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