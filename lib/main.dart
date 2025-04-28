import 'dart:io' show Platform; // For platform detection
import 'package:flutter/foundation.dart' show kIsWeb; // For web detection
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:realest/firebase_options.dart';
import 'package:realest/src/views/home/desktop/home_page.dart';
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
import 'package:realest/src/views/home/mobile_home_page.dart';

// Provider and user-related imports
import 'package:realest/user_provider.dart';

final ValueNotifier<ThemeMode> themeModeNotifier = ValueNotifier(ThemeMode.dark);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase with platform-specific options
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Load environment variables from .env file
  await dotenv.load(fileName: ".env");

  // Set Firebase Auth persistence only on web platforms
  if (kIsWeb) {
    await FirebaseAuth.instance.setPersistence(Persistence.LOCAL);
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) => UserProvider(
            auth: FirebaseAuth.instance,
            firestore: FirebaseFirestore.instance,
          )..initializeUser(),
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
    _router = _createRouter(_toggleTheme);
  }

  void _toggleTheme() {
    themeModeNotifier.value =
    themeModeNotifier.value == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
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


  GoRouter _createRouter(VoidCallback toggleTheme) {

    String initialRoute = '/';
    if (!kIsWeb) {
      if (Platform.isAndroid || Platform.isIOS) {
        initialRoute = '/mobileHome';
      }
    }

    return GoRouter(
      initialLocation: initialRoute,
      redirect: (context, state) {
        if (userProvider.isLoading) return null;
        final isLoggedIn = userProvider.userRole != null;
        final currentPath = state.uri.path;

        if (currentPath == '/') return null;

        if (currentPath == '/login' && isLoggedIn) {
          _showAccessDenied(context, "You are already logged in");
          return '/home';
        }

        final protectedRoutes = [
          '/home',
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
            return '/login';
          }

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
        }
        return null;
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
        GoRoute(
          path: '/setup',
          builder: (context, state) {
            final userProvider = Provider.of<UserProvider>(context);
            return userProvider.userRole == 'investor'
                ? const InvestorSetupPage()
                : const RealtorSetupPage();
          },
        ),
        ShellRoute(
          builder: (context, state, child) => MainLayout(
            toggleTheme: toggleTheme,
            themeMode: themeModeNotifier.value,
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
                  isDarkMode: themeModeNotifier.value == ThemeMode.dark,
                );
              },
            ),
            GoRoute(
              path: '/settings',
              builder: (context, state) {
                final userProvider = Provider.of<UserProvider>(context);
                return userProvider.userRole == 'investor'
                    ? InvestorSettings(
                  toggleTheme: toggleTheme,
                  isDarkMode: themeModeNotifier.value == ThemeMode.dark,
                )
                    : RealtorSettings(
                  toggleTheme: toggleTheme,
                  isDarkMode: themeModeNotifier.value == ThemeMode.dark,
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
                    context.go('/home');
                  });
                  return const SizedBox.shrink();
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
                    context.go('/home');
                  });
                  return const SizedBox.shrink();
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
                    context.go('/home');
                  });
                  return const SizedBox.shrink();
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
              builder: (context, state) => const RealtorHomeSearch(),
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
    colorScheme: ColorScheme.light(
      primary: Colors.deepPurple,
      secondary: Colors.black87,
      surface: Colors.white,
      surfaceVariant: Colors.black,
      onSurface: Colors.black,
      onTertiary: Colors.grey[100],
      onTertiaryFixedVariant: Colors.grey[200],
    ),
    cardTheme: CardTheme( color: Colors.grey[200]),
    textTheme: const TextTheme(
      headlineSmall: TextStyle(color: Colors.black),
      headlineLarge: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
      headlineMedium: TextStyle(color: Colors.black87),
      titleLarge: TextStyle(color: Colors.black),
      titleMedium: TextStyle(color: Colors.black87),
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
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.deepPurpleAccent,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.deepPurpleAccent,
        backgroundColor: Colors.grey[100],
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        side: const BorderSide(color: Colors.deepPurpleAccent),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Colors.deepPurpleAccent),
        ),
      ),
    ),
    //expansion panel theme border round
    expansionTileTheme: ExpansionTileThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
    ),
    ),

  );

}

ThemeData _darkTheme() {
  return ThemeData(
    primaryColor: Colors.white,
    scaffoldBackgroundColor: const Color(0xFF1E1E1E),
    cardColor: const Color(0xFF2C2C2C),
    colorScheme: const ColorScheme.dark(
      primary: const Color(0xFFCA93FF),
      secondary: Colors.white70,
      surface: Color(0xFF2C2C2C),
      surfaceVariant: Color(0xFF121212),
      onSurface: Colors.white,
      onTertiary:  Color(0xFF3C3C3C),
      onTertiaryFixedVariant: Color(0xFF494949),

    ),
    cardTheme: const CardTheme(color: Color(0xFF2C2C2C)),
    textTheme: const TextTheme(
      headlineSmall: TextStyle(color: Colors.white),
      headlineLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      headlineMedium: TextStyle(color: Colors.white70),
      titleLarge: TextStyle(color: Colors.white),
      titleMedium: TextStyle(color: Colors.white70),
      bodyLarge: TextStyle(color: Colors.white),
      bodyMedium: TextStyle(color: Colors.white70),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF333333),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      hintStyle: TextStyle(color: Colors.grey[400]),
      labelStyle: const TextStyle(fontWeight: FontWeight.normal, color: Colors.white),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.deepPurpleAccent,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.deepPurpleAccent,
        backgroundColor: const Color(0xFF2C2C2C),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        side: const BorderSide(color: Colors.deepPurpleAccent),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Colors.deepPurpleAccent),
        ),
      ),
    ),
  );
}
