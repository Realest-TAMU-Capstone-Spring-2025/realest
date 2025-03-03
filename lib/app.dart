import 'package:flutter/material.dart';
import 'src/views/custom_login_page.dart';
import 'src/views/realtor/realtor_home.dart';
import 'src/views/investor/investor_home.dart';

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.light; // Default Light Mode

  void _toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Property Investment App',
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.white,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
      ),
      initialRoute: '/customLogin',
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/customLogin':
            return MaterialPageRoute(builder: (_) => const CustomLoginPage());
          case '/realtorHome':
            return MaterialPageRoute(
                builder: (_) => RealtorHomePage(
                  isDarkMode: _themeMode == ThemeMode.dark,
                  toggleTheme: _toggleTheme,
                ));
          case '/investorHome':
            return MaterialPageRoute(builder: (_) => const InvestorHomePage());
          default:
            return MaterialPageRoute(builder: (_) => const CustomLoginPage());
        }
      },
    );
  }
}
