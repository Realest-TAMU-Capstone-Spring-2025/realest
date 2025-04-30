import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../user_provider.dart';
import 'profile_pic.dart';

class NavBar extends StatefulWidget {
  final VoidCallback toggleTheme;
  final bool isDarkMode;

  const NavBar({
    Key? key,
    required this.toggleTheme,
    required this.isDarkMode,
  }) : super(key: key);

  @override
  _NavBarState createState() => _NavBarState();
}

class _NavBarState extends State<NavBar> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    bool isSmallScreen = MediaQuery.of(context).size.width < 800;

    return isSmallScreen ? _buildDrawer(context) : _buildSidebar(context);
  }

  @override
  void initState() {
    super.initState();
    Provider.of<UserProvider>(context, listen: false).fetchUserData();
  }

  /// **📌 Drawer for Mobile**
  Widget _buildDrawer(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);

    return SizedBox(
      height: MediaQuery.of(context).size.height,
      child: Drawer(
        child: ListView(
          children: [
            DrawerHeader(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 40,
                    child: ProfilePic(
                      toggleTheme: widget.toggleTheme,
                      onAccountSettings: () => GoRouter.of(context).go("/settings"),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // User Details
                  Text(
                    '${userProvider.firstName ?? ''} ${userProvider.lastName ?? ''}'.trim(),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
            ..._buildNavItems(context, true),
            IconButton(
              icon: Icon(widget.isDarkMode ? Icons.dark_mode : Icons.light_mode),
              color: Colors.white,
              onPressed: widget.toggleTheme,
            ),
          ],
        ),
      ),
    );
  }

  /// **📌 Sidebar for Large Screens**
  Widget _buildSidebar(BuildContext context) {
    final theme = Theme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        print('Sidebar constraints: width=${constraints.maxWidth}, height=${constraints.maxHeight}');
        return AnimatedContainer(
          key: Key('sidebar-container'),
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          width: _isExpanded ? 230 : 80,
          height: constraints.hasBoundedHeight ? constraints.maxHeight : MediaQuery.of(context).size.height,
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
              InkWell(
                child: const Padding(
                  padding: EdgeInsets.all(12.0),
                  child: Icon(Icons.real_estate_agent, size: 42, color: Colors.white),
                ),
              ),
              const SizedBox(height: 10),
              if (_isExpanded)
                const Padding(
                  padding: EdgeInsets.all(12.0),
                  child: Text(
                    "RealEst",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
              const SizedBox(height: 30),
              ..._buildNavItems(context, false),
              const Spacer(),
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
              IconButton(
                key: Key('theme-toggle-button'), // Added key for easier testing
                icon: Icon(widget.isDarkMode ? Icons.dark_mode : Icons.light_mode),
                color: Colors.white,
                onPressed: widget.toggleTheme,
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: _isExpanded ? 100 : 50,
                height: _isExpanded ? 100 : 50,
                child: ProfilePic(
                  toggleTheme: widget.toggleTheme,
                  onAccountSettings: () => GoRouter.of(context).go("/settings"),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        );
      },
    );
  }

  /// **📌 Navigation Items**
  List<Widget> _buildNavItems(BuildContext context, bool isDrawer) {
    final userProvider = Provider.of<UserProvider>(context);
    final currentRoute = GoRouter.of(context).routerDelegate.currentConfiguration.fullPath;
    return userProvider.userRole == "realtor"?
    //nav items for realtor
    [
      _NavItem(icon: Icons.dashboard, label: "Dashboard", route: '/home', isDrawer: isDrawer, currentRoute: currentRoute),
      _NavItem(icon: Icons.search, label: "Home Search", route: '/search', isDrawer: isDrawer, currentRoute: currentRoute),
      _NavItem(icon: Icons.calculate, label: "Calculators", route: '/calculators', isDrawer: isDrawer, currentRoute: currentRoute),
      _NavItem(icon: Icons.people, label: "Clients", route: '/clients', isDrawer: isDrawer, currentRoute: currentRoute),
      _NavItem(icon: Icons.assessment, label: "Reports", route: '/reports', isDrawer: isDrawer, currentRoute: currentRoute),
    ] :
    //nav items for investor
    [
      _NavItem(icon: Icons.home, label: "My Feed", route: '/home', isDrawer: isDrawer, currentRoute: currentRoute),
      _NavItem(icon: Icons.search, label: "Home Search", route: '/search', isDrawer: isDrawer, currentRoute: currentRoute),
      _NavItem(icon: Icons.calculate, label: "Calculators", route: '/calculators', isDrawer: isDrawer, currentRoute: currentRoute),
      _NavItem(icon: Icons.favorite, label: "Saved", route: '/saved', isDrawer: isDrawer, currentRoute: currentRoute),
      _NavItem(icon: Icons.close, label: "Disliked", route: '/disliked', isDrawer: isDrawer, currentRoute: currentRoute),
    ];
  }
}
class _NavItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final String route;
  final bool isDrawer;
  final String? currentRoute; // Add currentRoute parameter

  const _NavItem({
    required this.icon,
    required this.label,
    required this.route,
    required this.isDrawer,
    this.currentRoute, // Optional currentRoute
  });

  @override
  __NavItemState createState() => __NavItemState();
}

class __NavItemState extends State<_NavItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    // Use the passed currentRoute instead of GoRouterState
    bool isSelected = widget.currentRoute == widget.route;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: () {
          final goRouter = GoRouter.of(context); // Use GoRouter instance
          goRouter.go(widget.route);
          if (widget.isDrawer) Navigator.pop(context);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          child: ClipRect(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 8),
              decoration: BoxDecoration(
                color: _isHovered
                    ? Colors.deepPurpleAccent.withOpacity(0.5)
                    : isSelected
                        ? Colors.deepPurpleAccent.withOpacity(0.2)
                        : Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: widget.isDrawer
                    ? MainAxisAlignment.start
                    : MainAxisAlignment.center,
                children: [
                  Icon(
                    widget.icon,
                    color: isSelected ? Colors.deepPurpleAccent : Colors.white,
                  ),
                  if (widget.isDrawer)
                    const SizedBox(width: 12),
                  if (widget.isDrawer)
                    Text(
                      widget.label,
                      style: TextStyle(
                        color: isSelected
                            ? Colors.deepPurpleAccent
                            : Colors.white,
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
