import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:realest/firebase_options.dart';
import 'package:realest/src/views/realtor/realtor_home_search.dart';
import 'package:realest/src/views/realtor/realtor_settings.dart';
import 'src/views/custom_login_page.dart';
import 'src/views/investor/investor_home.dart';
import 'src/views/realtor/realtor_home.dart';
import 'src/views/realtor/realtor_setup.dart';
import 'src/views/realtor/realtor_calculators.dart';
import 'src/views/realtor/clients/realtor_clients.dart';
import 'src/views/realtor/realtor_reports.dart';
import 'src/views/investor/investor_setup.dart';
import 'package:provider/provider.dart';
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
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: _lightTheme(),
      darkTheme: _darkTheme(),
      initialRoute: '/',
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/':
            return MaterialPageRoute(
                builder: (_) => AuthGate(toggleTheme: _toggleTheme, themeMode: _themeMode));
          case '/login':
            return MaterialPageRoute(builder: (_) => const CustomLoginPage());
          case '/investorHome':
            return MaterialPageRoute(builder: (_) => const InvestorHomePage());
          case '/realtorHome':
            return MaterialPageRoute(
                builder: (_) => RealtorHomePage(
                  toggleTheme: _toggleTheme,
                  isDarkMode: _themeMode == ThemeMode.dark,
                ));
          case '/realtorSetup':
            return MaterialPageRoute(builder: (_) => const RealtorSetupPage());
          case '/realtorCalculators':
            return MaterialPageRoute(builder: (_) => const RealtorCalculators());
          case '/realtorClients':
            return MaterialPageRoute(builder: (_) => const RealtorClients());
          case '/realtorReports':
            return MaterialPageRoute(builder: (_) => const RealtorReports());
          case '/realtorHomeSearch':
            return MaterialPageRoute(builder: (_) => const RealtorHomeSearch());
          case '/investorSetup':
            return MaterialPageRoute(builder: (_) => const InvestorSetupPage());
          case '/realtorSettings':
            return MaterialPageRoute(
                builder: (_) => RealtorSettings(
                  toggleTheme: _toggleTheme,
                  isDarkMode: _themeMode == ThemeMode.dark,
                ));
          default:
            return MaterialPageRoute(builder: (_) => const CustomLoginPage());
        }
      },
    );
  }
}

/// Universal Light Theme
ThemeData _lightTheme() {
  return ThemeData(
    primaryColor: Colors.black, // Main theme color
    scaffoldBackgroundColor: Colors.white, // Page background
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
      fillColor: Colors.grey[100], // Input field background
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.deepPurple, // Primary button color
        foregroundColor: Colors.white, // Button text color
        padding: const EdgeInsets.symmetric(vertical: 14),
        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white, // White app bar
      iconTheme: IconThemeData(color: Colors.black), // Black icons
      titleTextStyle: TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold),
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
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.black, // Dark app bar
      iconTheme: IconThemeData(color: Colors.white), // White icons
      titleTextStyle: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
    ),
  );
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
              if (role == "investor") {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (ModalRoute.of(context)?.settings.name != "/investorHome") {
                    Navigator.popUntil(context, (route) => route.isFirst);
                    Navigator.pushReplacementNamed(context, "/investorHome");
                  }
                });
                return const InvestorHomePage();
              } else {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (ModalRoute.of(context)?.settings.name != "/realtorHome") {
                    Navigator.popUntil(context, (route) => route.isFirst);
                    Navigator.pushReplacementNamed(context, "/realtorHome");
                  }
                });
                return RealtorHomePage(
                  toggleTheme: toggleTheme,
                  isDarkMode: themeMode == ThemeMode.dark,
                );
              }
            }
            return const CustomLoginPage();
          },
        );
      },
    );
  }
}
