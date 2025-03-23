import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:realest/firebase_options.dart';
import 'package:realest/src/views/custom_login_page.dart';
import 'package:realest/src/views/investor/investor_home.dart';
import 'package:realest/src/views/realtor/dashboard/realtor_dashboard.dart';
import 'package:realest/src/views/realtor/realtor_setup.dart';
import 'package:realest/src/views/realtor/realtor_calculators.dart';
import 'package:realest/src/views/realtor/clients/realtor_clients.dart';
import 'package:realest/src/views/realtor/realtor_reports.dart';
import 'package:realest/src/views/realtor/realtor_home_search.dart';
import 'package:realest/src/views/realtor/realtor_settings.dart';
import 'package:realest/src/views/realtor/realtor_navbar.dart'; // Import Sidebar
import 'realtor_user_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => UserProvider()),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.light; // Default Theme

  void _toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: _lightTheme(),
      darkTheme: _darkTheme(),
      routerConfig: _router(_toggleTheme, _themeMode),
    );
  }
}

/// **GoRouter Configuration**
/// **GoRouter Configuration**
GoRouter _router(VoidCallback toggleTheme, ThemeMode themeMode) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => AuthGate(toggleTheme: toggleTheme, themeMode: themeMode),
      ),
      GoRoute(path: '/login', builder: (context, state) => const CustomLoginPage()),
      GoRoute(path: '/investorHome', builder: (context, state) => const InvestorHomePage()),

      // Realtor Pages
      ShellRoute(
        builder: (context, state, child) => MainLayout(
          child: child,
          toggleTheme: toggleTheme,
          themeMode: themeMode,
        ), // Sidebar Layout
        routes: [
          GoRoute(path: '/realtorDashboard', builder: (context, state) => RealtorDashboard(toggleTheme: toggleTheme, isDarkMode: themeMode == ThemeMode.dark)),
          GoRoute(path: '/realtorSetup', builder: (context, state) => const RealtorSetupPage()),
          GoRoute(path: '/realtorCalculators', builder: (context, state) => const RealtorCalculators()),
          GoRoute(path: '/realtorClients', builder: (context, state) => const RealtorClients()),
          GoRoute(path: '/realtorReports', builder: (context, state) => const RealtorReports()),
          GoRoute(path: '/realtorHomeSearch', builder: (context, state) => const RealtorHomeSearch()),
          GoRoute(path: '/realtorSettings', builder: (context, state) => RealtorSettings(toggleTheme: toggleTheme, isDarkMode: themeMode == ThemeMode.dark)),
        ],
      ),
    ],
  );
}

/// **🏠 Sidebar Layout Wrapper**
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
        title: Text("RealEst"),
        leading: IconButton(
          icon: Icon(Icons.menu),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
      )
          : null,
      drawer: isSmallScreen
          ? Drawer(
        child: RealtorNavBar(
          toggleTheme: toggleTheme,
          isDarkMode: themeMode == ThemeMode.dark,
        ),
      )
          : null,

      body: Row(
        children: [
          if (!isSmallScreen) // ✅ Sidebar for large screens
            RealtorNavBar(
              toggleTheme: toggleTheme,
              isDarkMode: themeMode == ThemeMode.dark,
            ),
          Expanded(child: child), // Page content
        ],
      ),
    );
  }
}

class AuthGate extends StatelessWidget {
  final VoidCallback toggleTheme;
  final ThemeMode themeMode;

  const AuthGate({Key? key, required this.toggleTheme, required this.themeMode}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.idTokenChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final user = snapshot.data;
        if (user == null) return const CustomLoginPage();

        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
          builder: (context, userSnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(body: Center(child: CircularProgressIndicator()));
            }

            if (userSnapshot.hasData && userSnapshot.data!.exists) {
              final role = userSnapshot.data!['role'];
              if (role == "investor") {
                Future.microtask(() => context.go('/investorHome'));
                return const InvestorHomePage();
              } else {
                Future.microtask(() => context.go('/realtorDashboard'));
                return RealtorDashboard(toggleTheme: toggleTheme,
                    isDarkMode: themeMode == ThemeMode.dark);
              }
            }
            return const CustomLoginPage();
          },
        );
      },
    );
  }
}

/// Universal Light Theme
ThemeData _lightTheme() {
  return ThemeData(
    primaryColor: Colors.black, // Main theme color
    scaffoldBackgroundColor: Colors.grey[100], // Page background
    cardColor: Colors.grey[200], // Card background
    colorScheme: const ColorScheme.light(
      primary: Colors.deepPurple, // Buttons and selected navbar item
      secondary: Colors.black87, // Secondary elements
      surface: Colors.white, // Default text color
      surfaceVariant: Colors.black, // Navbar background
      onSurface: Colors.black,
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Colors.black),
      bodyMedium: TextStyle(color: Colors.black87),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white, // Input field background
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
    ),
  );
}

/// **Universal Dark Theme**
ThemeData _darkTheme() {
  return ThemeData(
    primaryColor: Colors.white, // Main theme color
    scaffoldBackgroundColor: CupertinoColors.darkBackgroundGray, // Page background
    cardColor: Colors.grey[900], // Card background
    colorScheme: const ColorScheme.dark(
      primary: Colors.deepPurpleAccent, // Buttons and selected navbar item
      secondary: Colors.white70, // Secondary elements
      surfaceVariant: Colors.black, // Navbar background
      surface: Colors.black,
      onSurface: Colors.white, // Default text color
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Colors.white),
      bodyMedium: TextStyle(color: Colors.white70),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.grey[850], // Input field background
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.deepPurpleAccent, // Primary button color
        foregroundColor: Colors.white, // Button text color
        padding: const EdgeInsets.symmetric(vertical: 14),
        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    ),
  );
}
