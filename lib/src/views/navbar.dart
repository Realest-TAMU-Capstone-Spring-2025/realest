import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../user_provider.dart';
import 'profile_pic.dart';

/// A responsive navigation bar that displays as a sidebar on large screens
/// and a drawer on small screens.
class NavBar extends StatefulWidget {
  /// Callback to toggle the theme (dark/light mode).
  final VoidCallback toggleTheme;

  /// Indicates if dark mode is currently active.
  final bool isDarkMode;

  const NavBar({
    Key? key,
    required this.toggleTheme,
    required this.isDarkMode,
  }) : super(key: key);

  @override
  _NavBarState createState() => _NavBarState();
}

/// State for [NavBar], managing the sidebar/drawer expansion state.
class _NavBarState extends State<NavBar> {
  /// Tracks whether the sidebar is expanded (for large screens).
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    // Fetch user data when the widget is initialized.
    Provider.of<UserProvider>(context, listen: false).fetchUserData();
  }

  @override
  Widget build(BuildContext context) {
    // Determine if the screen is small (width < 800px).
    bool isSmallScreen = MediaQuery.of(context).size.width < 800;

    // Return a drawer for small screens or a sidebar for large screens.
    return isSmallScreen ? _buildDrawer(context) : _buildSidebar(context);
  }

  /// Builds the drawer for mobile screens.
  Widget _buildDrawer(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);

    return Drawer(
      child: Column(
        children: [
          // Drawer header with user profile information.
          DrawerHeader(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // User's profile picture.
                CircleAvatar(
                  radius: 40,
                  child: ProfilePic(
                    toggleTheme: widget.toggleTheme,
                    onAccountSettings: () => context.go("/settings"),
                  ),
                ),
                const SizedBox(height: 10),
                // Display user's full name.
                Text(
                  '${userProvider.firstName ?? ''} ${userProvider.lastName ?? ''}'.trim(),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
          // Navigation items for the drawer.
          ..._buildNavItems(context, true),
        ],
      ),
    );
  }

  /// Builds the sidebar for large screens.
  Widget _buildSidebar(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      width: _isExpanded ? 230 : 80, // Expand or collapse sidebar width.
      height: double.infinity,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(2, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: 30),
          // Logo icon for the app.
          InkWell(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Icon(Icons.real_estate_agent, size: 42, color: Colors.white),
            ),
          ),
          const SizedBox(height: 10),
          // Display app name when sidebar is expanded.
          if (_isExpanded)
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Text(
                "RealEst",
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          const SizedBox(height: 30),
          // Navigation items for the sidebar.
          ..._buildNavItems(context, false),
          const Spacer(), // Push content to the bottom.
          // Button to toggle sidebar expansion.
          Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: Icon(_isExpanded ? Icons.arrow_back_ios : Icons.arrow_forward_ios),
                  color: Colors.white,
                  onPressed: () {
                    setState(() => _isExpanded = !_isExpanded);
                  },
                ),
              ],
            ),
          ),
          // Animated profile picture at the bottom.
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: _isExpanded ? 100 : 50,
            height: _isExpanded ? 100 : 50,
            child: ProfilePic(
              toggleTheme: widget.toggleTheme,
              onAccountSettings: () => context.go("/settings"),
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  /// Builds the navigation items based on user role (realtor or investor).
  List<Widget> _buildNavItems(BuildContext context, bool isDrawer) {
    final userProvider = Provider.of<UserProvider>(context);
    // Return different nav items based on user role.
    return userProvider.userRole == "realtor"
        ? [
      // Navigation items for realtors.
      _NavItem(icon: Icons.dashboard, label: "Dashboard", route: '/home', isDrawer: isDrawer),
      _NavItem(icon: Icons.search, label: "Home Search", route: '/search', isDrawer: isDrawer),
      _NavItem(icon: Icons.calculate, label: "Calculators", route: '/calculators', isDrawer: isDrawer),
      _NavItem(icon: Icons.people, label: "Clients", route: '/clients', isDrawer: isDrawer),
      _NavItem(icon: Icons.assessment, label: "Reports", route: '/reports', isDrawer: isDrawer),
    ]
        : [
      // Navigation items for investors.
      _NavItem(icon: Icons.home, label: "My Feed", route: '/home', isDrawer: isDrawer),
      _NavItem(icon: Icons.search, label: "Home Search", route: '/search', isDrawer: isDrawer),
      _NavItem(icon: Icons.calculate, label: "Calculators", route: '/calculators', isDrawer: isDrawer),
      _NavItem(icon: Icons.favorite, label: "Saved", route: '/saved', isDrawer: isDrawer),
      _NavItem(icon: Icons.close, label: "Disliked", route: '/disliked', isDrawer: isDrawer),
    ];
  }
}

/// A single navigation item widget for the sidebar or drawer.
class _NavItem extends StatefulWidget {
  /// The icon to display for the navigation item.
  final IconData icon;

  /// The label text for the navigation item.
  final String label;

  /// The route to navigate to when the item is tapped.
  final String route;

  /// Indicates if the item is in a drawer (true) or sidebar (false).
  final bool isDrawer;

  /// Optional callback for custom tap behavior.
  final VoidCallback? onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.route,
    required this.isDrawer,
    this.onTap,
  });

  @override
  __NavItemState createState() => __NavItemState();
}

/// State for [_NavItem], handling hover and selection states.
class __NavItemState extends State<_NavItem> {
  /// Tracks whether the item is being hovered over.
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    // Check if the current route matches this item's route.
    bool isSelected = GoRouterState.of(context).matchedLocation == widget.route;

    // Get sidebar expansion state from parent NavBar.
    bool isSidebarExpanded = context.findAncestorStateOfType<_NavBarState>()?._isExpanded ?? false;
    final theme = Theme.of(context);

    return MouseRegion(
      // Update hover state on mouse enter/exit.
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        // Navigate to the route or call custom onTap when tapped.
        onTap: () {
          widget.onTap != null ? widget.onTap!() : context.go(widget.route);
          if (widget.isDrawer) Navigator.pop(context); // Close drawer on tap.
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          child: ClipRect(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 8),
              // Apply different background based on hover/selection state.
              decoration: BoxDecoration(
                color: _isHovered
                    ? Colors.deepPurpleAccent.withOpacity(0.5)
                    : isSelected
                    ? Colors.deepPurpleAccent.withOpacity(0.2)
                    : Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: isSidebarExpanded || widget.isDrawer
                    ? MainAxisAlignment.start
                    : MainAxisAlignment.center,
                children: [
                  // Icon with tooltip for sidebar, scaled on hover.
                  widget.isDrawer
                      ? AnimatedScale(
                    scale: _isHovered ? 1.2 : 1.0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      widget.icon,
                      color: isSelected
                          ? Colors.deepPurpleAccent
                          : widget.isDrawer
                          ? theme.primaryColor
                          : Colors.white,
                    ),
                  )
                      : TooltipTheme(
                    data: TooltipThemeData(
                      textStyle: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.deepPurple,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Tooltip(
                      message: widget.label,
                      child: AnimatedScale(
                        scale: _isHovered ? 1.2 : 1.0,
                        duration: const Duration(milliseconds: 200),
                        child: Icon(
                          widget.icon,
                          color: isSelected ? Colors.deepPurpleAccent : Colors.white,
                        ),
                      ),
                    ),
                  ),
                  // Display label text when sidebar is expanded or in drawer.
                  if (isSidebarExpanded || widget.isDrawer)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 12),
                        child: Text(
                          widget.label,
                          softWrap: false,
                          style: TextStyle(
                            color: _isHovered
                                ? Colors.deepPurpleAccent
                                : isSelected
                                ? Colors.deepPurpleAccent
                                : widget.isDrawer
                                ? theme.primaryColor
                                : Colors.white,
                            fontSize: 16,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}