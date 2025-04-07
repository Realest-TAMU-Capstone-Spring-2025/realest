import 'dart:io' show Platform; // For platform detection
import 'package:flutter/foundation.dart' show kIsWeb; // For web detection
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:realest/firebase_options.dart';
import 'package:realest/src/views/home/overview/overview_page.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// Views related to the investor
import 'package:realest/src/views/investor/investor_settings.dart';
import 'package:realest/src/views/investor/investor_setup.dart';
import 'package:realest/src/views/investor/properties/disliked_properties.dart';
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
import 'package:realest/src/views/mobile_home_page.dart';

// Provider and user-related imports
import 'user_provider.dart';

final ValueNotifier<ThemeMode> themeModeNotifier = ValueNotifier(ThemeMode.light);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await dotenv.load(fileName: ".env");
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
  late final UserProvider userProvider;

  @override
  void initState() {
    super.initState();
    userProvider = Provider.of<UserProvider>(context, listen: false);
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
  void _showAccessDenied(BuildContext context, String message) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    });
  }

  GoRouter _createRouter(VoidCallback toggleTheme, ThemeMode themeMode) {
    // Determine the initial route based on the platform
    String initialRoute = '/';
    if (!kIsWeb) {
      // If not on web, check if the platform is Android or iOS (mobile)
      if (Platform.isAndroid || Platform.isIOS) {
        initialRoute = '/mobileHome'; // Redirect mobile users to the login page
      }
    }

    return GoRouter(
      initialLocation: initialRoute, // Set the platform-specific initial route
      redirect: (context, state) {
        if(userProvider.isLoading) return null;
        final isLoggedIn = userProvider.userRole != null;
        final currentPath = state.uri.path;

        if (currentPath == '/') return null;

        // Redirect logic for '/login'
        if (currentPath == '/login' && isLoggedIn){
          _showAccessDenied(context, "You are already logged in");
          return '/home';
        }

        // Protected routes logic
        final protectedRoutes = [
          '/home',
          '/setup',
          '/settings',
          '/calculators',
          '/saved',
          '/disliked',
          '/clients',
          '/reports',
          '/search'
        ];

        if (protectedRoutes.contains(currentPath)) {
          if (!isLoggedIn) {
            _showAccessDenied(context, "You need to log in to access this page");
            return '/login'; // Redirect unauthenticated users to login
          }

          // Role-specific route protection
          if (currentPath == '/saved' && userProvider.userRole != 'investor') {
            _showAccessDenied(context, 'Saved properties only available to investors');
            return '/home';
          }
          if (currentPath == '/disliked' && userProvider.userRole != 'investor') {
            _showAccessDenied(context, 'Disliked properties only available to investors');
            return '/home';
          }
          if (currentPath == '/clients' && userProvider.userRole != 'realtor') {
            _showAccessDenied(context, 'Client management only available to realtors');
            return '/home';
          }
          if (currentPath == '/reports' && userProvider.userRole != 'realtor') {
            _showAccessDenied(context, 'Reports only available to realtors');
            return '/home';
          }
          if (currentPath == '/search' && userProvider.userRole != 'realtor') {
            _showAccessDenied(context, 'Property search only available to realtors');
            return '/home';
          }
        }
        return null; // No redirection needed
      },
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const HomePage(),
        ),
        GoRoute(
          path: '/mobileHome',
          builder: (context, state) => const MobileHomePage(),
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) => const CustomLoginPage(),
        ),
        ShellRoute(
          builder: (context, state, child) => MainLayout(
            toggleTheme: toggleTheme,
            themeMode: themeMode,
            child: child,
          ),
          routes: [
            GoRoute(
              path: '/home',
              builder: (context, state) {
                final userProvider = Provider.of<UserProvider>(context);
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
                final userProvider = Provider.of<UserProvider>(context);
                return userProvider.userRole == 'investor'
                    ? const InvestorSetupPage()
                    : const RealtorSetupPage();
              },
            ),
            GoRoute(
              path: '/settings',
              builder: (context, state) {
                final userProvider = Provider.of<UserProvider>(context);
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
            GoRoute(
              path: '/saved',
              builder: (context, state) {
                final userProvider = Provider.of<UserProvider>(context);
                if (userProvider.userRole != 'investor') {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Saved properties only available to investors')),
                    );
                    context.go('/home'); // Redirect back to home
                  });
                  return const SizedBox.shrink(); // Temporary empty widget
                }
                return SavedProperties();
              },
            ),
            GoRoute(
              path: '/disliked',
              builder: (context, state) {
                final userProvider = Provider.of<UserProvider>(context);
                if (userProvider.userRole != 'investor') {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Disliked properties only available to investors')),
                    );
                    context.go('/home'); // Redirect back to home
                  });
                  return const SizedBox.shrink(); // Temporary empty widget
                }
                return DislikedProperties();
              },
            ),
            GoRoute(
              path: '/clients',
              builder: (context, state) {
                final userProvider = Provider.of<UserProvider>(context);
                if (userProvider.userRole != 'realtor') {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Client management only available to realtors')),
                    );
                    context.go('/home'); // Redirect back to home
                  });
                  return const SizedBox.shrink(); // Temporary empty widget
                }
                return const RealtorClients();
              },
            ),
            GoRoute(
              path: '/reports',
              builder: (context, state) {
                final userProvider = Provider.of<UserProvider>(context);
                if (userProvider.userRole != 'realtor') {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Reports only available to realtors')),
                    );
                    context.go('/home');
                  });
                  return const SizedBox.shrink();
                }
                return const RealtorReports();
              },
            ),
            GoRoute(
              path: '/search',
              builder: (context, state) {
                final userProvider = Provider.of<UserProvider>(context);
                if (userProvider.userRole != 'realtor') {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Property search only available to realtors')),
                    );
                    context.go('/home'); // Redirect back to home
                  });
                  return const SizedBox.shrink(); // Temporary empty widget
                }
                return const RealtorHomeSearch();
              },
            ),
          ],
        ),
      ],
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