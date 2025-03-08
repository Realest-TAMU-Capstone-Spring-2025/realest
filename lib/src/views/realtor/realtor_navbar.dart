import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'realtor_profile_pic.dart'; // Ensure this is imported

class RealtorNavBar extends StatefulWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;
  final VoidCallback toggleTheme;
  final bool isDarkMode;

  const RealtorNavBar({
    Key? key,
    required this.selectedIndex,
    required this.onItemTapped,
    required this.toggleTheme,
    required this.isDarkMode,
  }) : super(key: key);

  @override
  _RealtorNavBarState createState() => _RealtorNavBarState();
}

class _RealtorNavBarState extends State<RealtorNavBar> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return MouseRegion(
      onEnter: (_) => setState(() => _isExpanded = true),
      onExit: (_) => setState(() => _isExpanded = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        width: _isExpanded ? 250 : 80, // Increased widths to avoid overflow
        height: double.infinity,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceVariant,
        ),
        child: Column(
          // Removed ClipRect to avoid unnecessary clipping
          children: [
            // Logo widget with adjusted padding
            const SizedBox(height: 20),
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: _isExpanded ? 100 : 50,
              height: _isExpanded ? 100 : 50,
              child: RealtorProfilePic(
                toggleTheme: widget.toggleTheme,
                isDarkMode: widget.isDarkMode,
                onAccountSettings: () => widget.onItemTapped(5),
              ),
            ),
            const SizedBox(height: 30),
            _NavItem(
              icon: Icons.home,
              label: "Home",
              index: 0,
              isSelected: widget.selectedIndex == 0,
              onTap: widget.onItemTapped,
              theme: theme,
              isExpanded: _isExpanded,
            ),
            _NavItem(
              icon: Icons.search,
              label: "Home Search",
              index: 1,
              isSelected: widget.selectedIndex == 1,
              onTap: widget.onItemTapped,
              theme: theme,
              isExpanded: _isExpanded,
            ),
            _NavItem(
              icon: Icons.calculate,
              label: "Calculators",
              index: 2,
              isSelected: widget.selectedIndex == 2,
              onTap: widget.onItemTapped,
              theme: theme,
              isExpanded: _isExpanded,
            ),
            _NavItem(
              icon: Icons.people,
              label: "Clients",
              index: 3,
              isSelected: widget.selectedIndex == 3,
              onTap: widget.onItemTapped,
              theme: theme,
              isExpanded: _isExpanded,
            ),
            _NavItem(
              icon: Icons.assessment,
              label: "Reports",
              index: 4,
              isSelected: widget.selectedIndex == 4,
              onTap: widget.onItemTapped,
              theme: theme,
              isExpanded: _isExpanded,
            ),
            const Spacer(),
            InkWell(
              onTap: () => widget.onItemTapped(0),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Icon(
                  Icons.real_estate_agent,
                  size: 42,
                  color: Colors.white,
                ),
              ),
            ),

            if (_isExpanded)
              InkWell(
                onTap: () => widget.onItemTapped(0),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12.0, 0, 12.0, 12.0), // Reduced top padding
                  child: Text(
                    "RealEst",
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Future<void> _showLogoutDialog(BuildContext context) async {
    final theme = Theme.of(context);
    final bool isDarkMode = theme.brightness == Brightness.dark;

    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: theme.cardColor,
          title: Text(
            "Confirm Logout",
            style: TextStyle(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            "Are you sure you want to log out?",
            style: TextStyle(
              color: theme.colorScheme.onSurface.withOpacity(0.8),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                "Cancel",
                style: TextStyle(color: theme.colorScheme.primary),
              ),
            ),
            // TextButton(
            //   onPressed: () async {
            //     Navigator.of(context).pop();
            //     await FirebaseAuth.instance.signOut();
            //     Navigator.pushReplacementNamed(context, '/login');
            //   },
            //   child: Text(
            //     "Logout",
            //     style: TextStyle(color: isDarkMode ? Colors.redAccent : Colors.red),
            //   ),
            // ),
          ],
        );
      },
    );
  }
}

class _NavItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final int index;
  final bool isSelected;
  final Function(int) onTap;
  final ThemeData theme;
  final bool isExpanded;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.index,
    required this.isSelected,
    required this.onTap,
    required this.theme,
    required this.isExpanded,
  });

  @override
  __NavItemState createState() => __NavItemState();
}

class __NavItemState extends State<_NavItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: () => widget.onTap(widget.index),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 8),
            decoration: BoxDecoration(
              color: _isHovered
                  ? Colors.white
                  : (widget.isSelected
                  ? widget.theme.colorScheme.primary.withOpacity(0.2)
                  : Colors.transparent),
              borderRadius: BorderRadius.circular(10),
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: widget.isExpanded ? 194 : 54,
              ),
              child: Row(
                mainAxisAlignment:
                widget.isExpanded ? MainAxisAlignment.start : MainAxisAlignment.center,
                children: [
                  AnimatedScale(
                    scale: _isHovered ? 1.2 : 1.0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      widget.icon,
                      color: _isHovered
                          ? Colors.deepPurpleAccent
                          : (widget.isSelected
                          ? Colors.deepPurpleAccent
                          : CupertinoColors.white),
                    ),
                  ),
                  if (widget.isExpanded) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.label,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: _isHovered
                              ? Colors.deepPurpleAccent
                              : (widget.isSelected
                              ? Colors.deepPurpleAccent
                              : CupertinoColors.white),
                          fontSize: 16,
                          fontWeight: widget.isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
