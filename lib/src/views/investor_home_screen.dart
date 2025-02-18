import 'package:flutter/material.dart';

class InvestorHomeScreen extends StatelessWidget {
  const InvestorHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Investor Dashboard')),
      body: Center(
        child: Text('Welcome, Investor! Here is your dashboard.'),
      ),
    );
  }
}
