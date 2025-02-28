import 'package:flutter/material.dart';
import 'src/views/custom_login_page.dart';
import 'src/views/realtor/realtor_home.dart';
import 'src/views/investor/investor_home.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Property Investment App',
      home: const CustomLoginPage(),
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.white,
      ),
      routes: {
        '/customLogin': (context) => CustomLoginPage(),
        '/realtorHome': (context) => RealtorHomePage(),
        '/investorHome': (context) =>  InvestorHomePage(),
      },
    );
  }
}
