import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../widgets/bottom_nav_item.dart';
import 'realtor_home_screen.dart';
import 'realtor_clients_screen.dart';
import 'realtor_dashboard_screen.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _notificationsEnabled = true;
  bool _darkModeEnabled = false;

  void _onItemTapped(int index) {
    if (index == 0) {
      // Navigate to Home screen.
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const RealtorHomeScreen()),
      );
    } else if (index == 1) {
      // Navigate to People screen.
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const ClientsPage()),
      );
    } else if (index == 2) {
      // Already on Settings.
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const DashboardPage()),
      );
    }
  }

  /// Helper widget for section headers with grey background.
  Widget _groupHeader(String title) {
    return Container(
      color: Colors.grey[300],
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      child: Text(
        title,
        style: GoogleFonts.openSans(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          'Settings',
          style: GoogleFonts.openSans(
            fontSize: 32,
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        automaticallyImplyLeading: false, // Removes the back arrow.
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: ListView(
        children: [
          // Account Group
          _groupHeader('Account'),
          ListTile(
            leading: const Icon(Icons.person, color: Colors.black54),
            title: Text(
              'Account Information',
              style: GoogleFonts.openSans(
                  fontSize: 16, fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              'View and edit your account info',
              style: GoogleFonts.openSans(fontSize: 14),
            ),
            onTap: () {
              // Navigate to account information page.
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.lock_outline, color: Colors.black54),
            title: Text(
              'Change Password',
              style: GoogleFonts.openSans(
                  fontSize: 16, fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              'Update your password',
              style: GoogleFonts.openSans(fontSize: 14),
            ),
            onTap: () {
              // Navigate to change password page.
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.link, color: Colors.black54),
            title: Text(
              'Linked Accounts',
              style: GoogleFonts.openSans(
                  fontSize: 16, fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              'Manage your linked accounts',
              style: GoogleFonts.openSans(fontSize: 14),
            ),
            onTap: () {
              // Navigate to linked accounts page.
            },
          ),
          // Preferences Group
          _groupHeader('Preferences'),
          SwitchListTile(
            title: Text(
              'Notifications',
              style: GoogleFonts.openSans(
                  fontSize: 16, fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              'Enable or disable notifications',
              style: GoogleFonts.openSans(fontSize: 14),
            ),
            value: _notificationsEnabled,
            onChanged: (bool value) {
              setState(() {
                _notificationsEnabled = value;
              });
            },
            secondary: const Icon(Icons.notifications, color: Colors.black54),
          ),
          const Divider(),
          SwitchListTile(
            title: Text(
              'Dark Mode',
              style: GoogleFonts.openSans(
                  fontSize: 16, fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              'Switch to dark theme',
              style: GoogleFonts.openSans(fontSize: 14),
            ),
            value: _darkModeEnabled,
            onChanged: (bool value) {
              setState(() {
                _darkModeEnabled = value;
              });
              // Optionally, implement theme switching logic here.
            },
            secondary: const Icon(Icons.dark_mode, color: Colors.black54),
          ),

          // Privacy & Security Group
          _groupHeader('Privacy & Security'),
          ListTile(
            leading: const Icon(Icons.privacy_tip, color: Colors.black54),
            title: Text(
              'Privacy Settings',
              style: GoogleFonts.openSans(
                  fontSize: 16, fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              'Control your privacy options',
              style: GoogleFonts.openSans(fontSize: 14),
            ),
            onTap: () {
              // Navigate to privacy settings page.
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.security, color: Colors.black54),
            title: Text(
              'Security Settings',
              style: GoogleFonts.openSans(
                  fontSize: 16, fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              'Manage your security preferences',
              style: GoogleFonts.openSans(fontSize: 14),
            ),
            onTap: () {
              // Navigate to security settings page.
            },
          ),

          // Help & About Group
          _groupHeader('Help & About'),
          ListTile(
            leading: const Icon(Icons.help_outline, color: Colors.black54),
            title: Text(
              'Help & Support',
              style: GoogleFonts.openSans(
                  fontSize: 16, fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              'Get assistance and report issues',
              style: GoogleFonts.openSans(fontSize: 14),
            ),
            onTap: () {
              // Navigate to help & support page.
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info_outline, color: Colors.black54),
            title: Text(
              'About',
              style: GoogleFonts.openSans(
                  fontSize: 16, fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              'App information, version, and legal info',
              style: GoogleFonts.openSans(fontSize: 14),
            ),
            onTap: () {
              // Navigate to about page or show a dialog.
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.description, color: Colors.black54),
            title: Text(
              'Terms & Conditions',
              style: GoogleFonts.openSans(
                  fontSize: 16, fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              'Review our terms and policies',
              style: GoogleFonts.openSans(fontSize: 14),
            ),
            onTap: () {
              // Navigate to terms & conditions page.
            },
          ),
          const Divider(),

          // Log Out Row
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.black54),
            title: Text(
              'Log Out',
              style: GoogleFonts.openSans(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            onTap: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushReplacementNamed(context, '/roleSelection');
            },
          ),
          const Divider(),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.only(bottom: 18.0),
        color: const Color(0xFF212834),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 1),
            Row(
              children: [
                BottomNavItem(
                  icon: Icons.home,
                  label: 'Home',
                  isSelected: false,
                  onTap: () => _onItemTapped(0),
                ),
                BottomNavItem(
                  icon: Icons.people,
                  label: 'Clients',
                  isSelected: false,
                  onTap: () => _onItemTapped(1),
                ),
                BottomNavItem(
                  icon: Icons.bookmark,
                  label: 'Saved',
                  isSelected:  false,
                  onTap: () => _onItemTapped(2),
                ),
                BottomNavItem(
                  icon: Icons.settings,
                  label: 'Settings',
                  isSelected: true,
                  onTap: () => _onItemTapped(3),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
