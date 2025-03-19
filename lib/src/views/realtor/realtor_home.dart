import 'package:flutter/material.dart';
import 'package:realest/src/views/realtor/realtor_dashboard.dart';
import 'package:realest/src/views/realtor/realtor_home_search.dart';
import 'package:realest/src/views/realtor/realtor_settings.dart';
import 'realtor_calculators.dart';
import 'clients/realtor_clients.dart';
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
      RealtorDashboard(toggleTheme: widget.toggleTheme, isDarkMode: widget.isDarkMode),
      const RealtorHomeSearch(),
      const RealtorCalculators(),
      const RealtorClients(),
      const RealtorReports(),
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
          // Left-Side Navigation Bar remains fixed
          RealtorNavBar(
            selectedIndex: _selectedIndex,
            onItemTapped: _onNavItemTapped,
            toggleTheme: widget.toggleTheme,
            isDarkMode: widget.isDarkMode,
          ),
          // Right side: Header on top of the pages
          // Expanded(
          //   child: Column(
          //     children: [
          //       // Header with an icon before the text, tappable to set index to 0
          //       Container(
          //         width: double.infinity,
          //         padding: const EdgeInsets.all(16.0),
          //         color: Colors.black,
          //         child: GestureDetector(
          //           onTap: () {
          //             setState(() {
          //               _selectedIndex = 0; // Set index to 0 when tapped
          //             });
          //           },
          //           child: Row(
          //             mainAxisAlignment: MainAxisAlignment.center,
          //             children: [
          //               const Icon(
          //                 Icons.real_estate_agent,
          //                 color: Colors.white,
          //                 size: 30,
          //               ),
          //               const SizedBox(width: 8),
          //               Text(
          //                 'RealEst',
          //                 textAlign: TextAlign.center,
          //                 style: Theme.of(context)
          //                     .textTheme
          //                     .bodyLarge
          //                     ?.copyWith(
          //                   color: Colors.white,
          //                   fontSize: 24,
          //                   fontWeight: FontWeight.bold,
          //                 ),
          //               ),
          //             ],
          //           ),
          //         ),
          //       ),
          //       // Main Content Area for pages
          //
          //     ],
          //   ),
          // ),
          Expanded(
            child: _pages[_selectedIndex],
          ),
        ],
      ),
    );
  }
}