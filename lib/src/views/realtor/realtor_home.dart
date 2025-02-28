import 'package:flutter/material.dart';
import 'package:realest/src/views/realtor/realtor_dashboard.dart';
import 'realtor_calculators.dart';
import 'realtor_clients.dart';
import 'realtor_reports.dart';
import 'realtor_navbar.dart';

class RealtorHomePage extends StatefulWidget {
  const RealtorHomePage({Key? key}) : super(key: key);

  @override
  _RealtorHomePageState createState() => _RealtorHomePageState();
}

class _RealtorHomePageState extends State<RealtorHomePage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const RealtorDashboard(),
    const RealtorCalculators(),
    const RealtorClients(),
    const RealtorReports(),
  ];

  void _onNavItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Row(
        children: [
          // Left-Side Navigation Bar
          RealtorNavBar(
            selectedIndex: _selectedIndex,
            onItemTapped: _onNavItemTapped,
          ),

          // Main Content Area
          Expanded(
            child: _pages[_selectedIndex],
          ),
        ],
      ),
    );
  }
}
