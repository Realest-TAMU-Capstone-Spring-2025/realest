import 'package:flutter/material.dart';
import 'package:realest/src/views/realtor/realtor_dashboard.dart';
import 'package:realest/src/views/realtor/realtor_home_search.dart';
import 'package:realest/src/views/realtor/realtor_settings.dart';
import 'calculators/realtor_calculators.dart';
import 'realtor_clients.dart';
import 'realtor_reports.dart';
import 'realtor_navbar.dart';

class RealtorHomePage extends StatefulWidget {
  final VoidCallback toggleTheme;
  final bool isDarkMode;

  const RealtorHomePage({Key? key, required this.toggleTheme, required this.isDarkMode}) : super(key: key);

  @override
  _RealtorHomePageState createState() => _RealtorHomePageState();
}

class _RealtorHomePageState extends State<RealtorHomePage> {
  int _selectedIndex = 0;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      const RealtorDashboard(),
      const RealtorCalculators(),
      const RealtorClients(),
      const RealtorReports(),
      const RealtorHomeSearch(),
      RealtorSettings(toggleTheme: widget.toggleTheme, isDarkMode: widget.isDarkMode),
    ];
  }

  void _onNavItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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