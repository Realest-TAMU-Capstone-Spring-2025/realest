import 'package:flutter/material.dart';

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
    return Container(
      width: 250,
      height: double.infinity,
      decoration: BoxDecoration(
        color: Colors.black, // Dark modern look
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 50), // Space at the top

          // App Logo or Branding
          const Icon(Icons.real_estate_agent, size: 50, color: Colors.white),
          const SizedBox(height: 30),

          // Nav Items
          _buildNavItem(Icons.home, "Home", 0),
          _buildNavItem(Icons.calculate, "Calculators", 1),
          _buildNavItem(Icons.people, "Clients", 2),
          _buildNavItem(Icons.assessment, "Reports", 3),
          _buildNavItem(Icons.search, "Home Search", 3),
          _buildNavItem(Icons.settings, "Settings", 3),


          const Spacer(),

          // Logout Button
          _buildNavItem(Icons.logout, "Logout", -1, isLogout: true),

          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index, {bool isLogout = false}) {
    bool isSelected = selectedIndex == index;
    return GestureDetector(
      onTap: () {
        if (isLogout) {
          // Handle Logout
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
            color: isSelected ? Colors.white.withOpacity(0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Icon(icon, color: isSelected ? Colors.white : Colors.grey[400]),
              const SizedBox(width: 15),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey[400],
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
}
