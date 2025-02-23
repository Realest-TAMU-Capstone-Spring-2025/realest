import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/bottom_nav_item.dart';
import 'realtor_home_screen.dart';
import 'realtor_settings_screen.dart';
import 'realtor_dashboard_screen.dart';

class ClientsPage extends StatelessWidget {
  const ClientsPage({Key? key}) : super(key: key);

  // Dummy user name.
  final String userName = "John Doe";

  // Dummy list of clients.
  final List<String> clients = const [
    "Eshwar Gadi",
    "Dinesh Balakrishnan",
    "Arjun Som",
    "Daniel Pandyan",
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          'Clients',
          style: GoogleFonts.openSans(
            fontSize: 32,
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black),
        automaticallyImplyLeading: false, // Removes the back arrow.
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header with logo and user name.
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Display the logo.
                  Image.asset(
                    'assets/images/profile.png',
                    height: 100,
                  ),
                  const SizedBox(height: 8),
                  // Display the user name.
                  Text(
                    userName,
                    style: GoogleFonts.openSans(
                        fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            // Container for the client list.
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16.0),
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: clients.length,
                separatorBuilder: (context, index) => const Divider(),
                itemBuilder: (context, index) {
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue,
                      child: Text(
                        clients[index][0],
                        style: GoogleFonts.openSans(
                           fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                    title: Text(
                      clients[index],
                      style: GoogleFonts.openSans(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    trailing: const Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Colors.black54,
                    ),
                    onTap: () {
                      // Handle client tap.
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.only(bottom: 18.0),
        color: const Color(0xFF212834),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 1),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                BottomNavItem(
                  icon: Icons.home,
                  label: 'Home',
                  isSelected: false,
                  onTap: () {
                    // Navigate to Home screen.
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const RealtorHomeScreen()),
                    );
                  },
                ),
                BottomNavItem(
                  icon: Icons.group,
                  label: 'Clients',
                  isSelected: true,
                  onTap: () {
                    // Already on Clients page.
                  },
                ),
                BottomNavItem(
                  icon: Icons.bookmark,
                  label: 'Saved',
                  isSelected: false,
                  onTap: () {
                    // Navigate to Settings page.
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const DashboardPage()),
                    );
                  },
                ),
                BottomNavItem(
                  icon: Icons.settings,
                  label: 'Settings',
                  isSelected: false,
                  onTap: () {
                    // Navigate to Settings page.
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const SettingsPage()),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
