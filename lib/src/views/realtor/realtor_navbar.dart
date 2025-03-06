import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RealtorNavBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;

  const RealtorNavBar({
    Key? key,
    required this.selectedIndex,
    required this.onItemTapped,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isDarkMode = theme.brightness == Brightness.dark;

    return Container(
      width: 250,
      height: double.infinity,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant, // Navbar Background Color from Theme
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 50), // Space at the top

          // App Logo or Branding
          Icon(Icons.real_estate_agent, size: 50, color: CupertinoColors.white),
          const SizedBox(height: 30),

          // Nav Items
          _buildNavItem(Icons.home, "Home", 0, theme, isDarkMode),
          _buildNavItem(Icons.calculate, "Calculators", 1, theme, isDarkMode),
          _buildNavItem(Icons.people, "Clients", 2, theme, isDarkMode),
          _buildNavItem(Icons.assessment, "Reports", 3, theme, isDarkMode),
          _buildNavItem(Icons.search, "Home Search", 4, theme, isDarkMode),
          _buildNavItem(Icons.settings, "Settings", 5, theme, isDarkMode),

          const Spacer(),

          // Logout Button with Confirmation Dialog
          _buildNavItem(Icons.logout, "Logout", -1, theme, isDarkMode, isLogout: true, context: context),

          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index, ThemeData theme, bool isDarkMode,
      {bool isLogout = false, BuildContext? context}) {
    bool isSelected = selectedIndex == index;
    return GestureDetector(
      onTap: () async {
        if (isLogout) {
          _showLogoutDialog(context!); // Show confirmation popup
        } else {
          onItemTapped(index);
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 15),
          decoration: BoxDecoration(
            color: isSelected ? theme.colorScheme.primary.withOpacity(0.2) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Icon(icon, color: isSelected ? Colors.deepPurpleAccent: CupertinoColors.white),
              const SizedBox(width: 15),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.deepPurpleAccent : CupertinoColors.white,
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// **Logout Confirmation Dialog**
  void _showLogoutDialog(BuildContext context) {
    final theme = Theme.of(context);
    final bool isDarkMode = theme.brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: theme.cardColor, // Keep theme color
          title: Text(
            "Confirm Logout",
            style: TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.bold),
          ),
          content: Text(
            "Are you sure you want to log out?",
            style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.8)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(), // Close the dialog
              child: Text("Cancel", style: TextStyle(color: theme.colorScheme.primary)),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop(); // Close dialog first
                await FirebaseAuth.instance.signOut();
                Navigator.pushReplacementNamed(context, '/login'); // Redirect to login
              },
              child: Text("Logout", style: TextStyle(color: isDarkMode ? Colors.redAccent : Colors.red)),
            ),
          ],
        );
      },
    );
  }
}
