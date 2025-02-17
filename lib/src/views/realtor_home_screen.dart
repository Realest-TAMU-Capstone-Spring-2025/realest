import 'package:flutter/material.dart';

class RealtorHomeScreen extends StatelessWidget {
  const RealtorHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Realtor Dashboard')),
      body: Center(
        child: Text('Welcome, Realtor! Here is your dashboard.'),
      ),
    );
  }
}
