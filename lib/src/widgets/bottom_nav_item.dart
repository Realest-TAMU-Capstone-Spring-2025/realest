import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// A widget representing a single item in a bottom navigation bar.
class BottomNavItem extends StatelessWidget {
  /// The icon to display for the navigation item.
  final IconData icon;

  /// The label text for the navigation item.
  final String label;

  /// Indicates whether the item is currently selected.
  final bool isSelected;

  /// Callback function triggered when the item is tapped.
  final VoidCallback onTap;

  const BottomNavItem({
    Key? key,
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap, // Trigger the callback when tapped.
        child: Column(
          mainAxisSize: MainAxisSize.min, // Minimize vertical space.
          children: [
            // Icon with conditional coloring based on selection.
            Padding(
              padding: const EdgeInsets.only(top: 12.0),
              child: Icon(
                icon,
                color: isSelected ? Colors.lightBlue : Colors.white,
              ),
            ),
            const SizedBox(height: 4), // Spacing between icon and label.
            // Label text with conditional coloring and bold font.
            Text(
              label,
              style: GoogleFonts.openSans(
                color: isSelected ? Colors.lightBlue : Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            // Underline indicator for selected item.
            if (isSelected)
              Container(
                margin: const EdgeInsets.only(top: 6.0),
                height: 2,
                width: 50,
                color: Colors.lightBlue,
              ),
          ],
        ),
      ),
    );
  }
}