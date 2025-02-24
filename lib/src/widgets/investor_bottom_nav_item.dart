import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class InvestorBottomNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const InvestorBottomNavItem({
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
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 12.0),
              child: Icon(
                icon,
                color: isSelected ? Color(0xFFEBA682) : Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.openSans(
                color: isSelected ? Color(0xFFEBA682) : Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (isSelected)
              Container(
                margin: const EdgeInsets.only(top: 6.0),
                height: 2,
                width: 50,
                color: Color(0xFFEBA682),
              ),
          ],
        ),
      ),
    );
  }
}
