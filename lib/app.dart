import 'package:flutter/material.dart';
import 'src/views/roleselectionScreen.dart';
import 'src/views/realtorloginScreen.dart';
import 'src/views/investorloginScreen.dart';
import 'src/views/realtorhomeScreen.dart';
import 'src/views/investorhomeScreen.dart';

class MyApp extends StatelessWidget {
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
