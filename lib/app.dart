import 'package:flutter/material.dart';
import 'src/views/role_selection_screen.dart';
import 'src/views/realtor_login_screen.dart';
import 'src/views/investor_login_screen.dart';
import 'src/views/realtor_home_screen.dart';
import 'src/views/investor_home_screen.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Property Investment App',
      theme: ThemeData(primarySwatch: Colors.blue),
      // The first screen the user sees is the role selection screen.
      home: RoleSelectionScreen(),
      routes: {
        '/realtorLogin': (context) => RealtorLoginScreen(),
        '/investorLogin': (context) => InvestorLoginScreen(),
        '/realtor': (context) => RealtorHomeScreen(),
        '/investor': (context) => InvestorHomeScreen(),
      },
    );
  }
}
