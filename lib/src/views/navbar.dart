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

    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 40,
                  child: ProfilePic(
                    toggleTheme: widget.toggleTheme,
                    onAccountSettings: () => context.go("/settings"),
                  ),
                ),
                const SizedBox(height: 10),
                //User Details
                Text(
                  '${userProvider.firstName ?? ''} ${userProvider.lastName ?? ''}'.trim(),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
          ..._buildNavItems(context, true),
        ],
      ),
    );
  }

  /// **📌 Sidebar for Large Screens**
  Widget _buildSidebar(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        width: _isExpanded ? 230 : 80,
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
            SizedBox(height: 30,),
            InkWell(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Icon(Icons.real_estate_agent, size: 42, color: Colors.white),
              ),
            ),
            SizedBox(height: 10,),
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

            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: _isExpanded ? 100 : 50,
              height: _isExpanded ? 100 : 50,
              child: ProfilePic(
                toggleTheme: widget.toggleTheme,
                onAccountSettings: () => context.go("/settings"),
              ),
            ),
            SizedBox(height: 30,)
          ],
        ),
      );
  }

  /// **📌 Navigation Items**
  List<Widget> _buildNavItems(BuildContext context, bool isDrawer) {
    final userProvider = Provider.of<UserProvider>(context);
    return userProvider.userRole == "realtor"?
    //nav items for realtor
    [
      _NavItem(icon: Icons.dashboard, label: "Dashboard", route: '/home', isDrawer: isDrawer),
      _NavItem(icon: Icons.search, label: "Home Search", route: '/search', isDrawer: isDrawer),
      _NavItem(icon: Icons.calculate, label: "Calculators", route: '/calculators', isDrawer: isDrawer),
      _NavItem(icon: Icons.people, label: "Clients", route: '/clients', isDrawer: isDrawer),
      _NavItem(icon: Icons.assessment, label: "Reports", route: '/reports', isDrawer: isDrawer),
    ] :
    //nav items for investor
    [
      _NavItem(icon: Icons.home, label: "My Feed", route: '/home', isDrawer: isDrawer),
      _NavItem(icon: Icons.search, label: "Home Search", route: '/search', isDrawer: isDrawer),
      _NavItem(icon: Icons.calculate, label: "Calculators", route: '/calculators', isDrawer: isDrawer),
      _NavItem(icon: Icons.favorite, label: "Saved", route: '/saved', isDrawer: isDrawer),
      _NavItem(icon: Icons.close, label: "Disliked", route: '/disliked', isDrawer: isDrawer),
    ];
  }
}
class _NavItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final String route;
  final bool isDrawer;
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

class __NavItemState extends State<_NavItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    bool isSelected = GoRouterState.of(context).matchedLocation == widget.route;

    // ✅ Get sidebar expansion state
    bool isSidebarExpanded = context.findAncestorStateOfType<_NavBarState>()?._isExpanded ?? false;
    final theme = Theme.of(context);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: () {
          widget.onTap != null ? widget.onTap!() : context.go(widget.route);
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
              child:Row(
                mainAxisAlignment: isSidebarExpanded || widget.isDrawer
                    ? MainAxisAlignment.start
                    : MainAxisAlignment.center,
                children: [
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
