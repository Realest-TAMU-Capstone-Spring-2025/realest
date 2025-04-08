import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MobileHomePage extends StatefulWidget {
  const MobileHomePage({Key? key}) : super(key: key);

  @override
  State<MobileHomePage> createState() => _MobileHomePageState();
}

class _MobileHomePageState extends State<MobileHomePage> with TickerProviderStateMixin {
  late final AnimationController _gateController;
  late final Animation<Offset> _topPanelAnimation;
  late final Animation<Offset> _bottomPanelAnimation;
  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _gateController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _topPanelAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0, -1.0),
    ).animate(
      CurvedAnimation(parent: _gateController, curve: Curves.easeInOut),
    );

    _bottomPanelAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0, 1.0),
    ).animate(
      CurvedAnimation(parent: _gateController, curve: Curves.easeInOut),
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _gateController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _onLogoTap() {
    _gateController.forward().then((_) {
      _fadeController.forward().then((_) {
        context.go('/login');
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    const dividerHeight = 12.0;
    final bottomPanelHeight = screenHeight / 8; // Bottom panel is 1/10th of screen height
    final topPanelHeight = screenHeight - bottomPanelHeight - dividerHeight; // Top panel takes the rest

    // Single image provider for the top panel
    final imageProvider = AssetImage('assets/images/login.png');

    return Scaffold(
      body: Stack(
        children: [
          // Base background
          Container(
            width: double.infinity,
            height: double.infinity,
            color: const Color(0xFF1f1e25),
          ),
          // Top panel: extends down to the divider with text near the top
          SlideTransition(
            position: _topPanelAnimation,
            child: Container(
              height: topPanelHeight,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRect(
                    child: OverflowBox(
                      maxHeight: screenHeight,
                      alignment: Alignment.topCenter,
                      child: Image(
                        image: imageProvider,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: screenHeight,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 50), // Move text up with some padding from the top
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: const [
                        Text(
                          'Welcome to RealEst',
                          style: TextStyle(
                            fontSize: 38,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Automate Analysis, Multiply Deals',
                          style: TextStyle(
                            fontSize: 20,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Bottom panel: grey background only, no image or text
          Align(
            alignment: Alignment.bottomCenter,
            child: SlideTransition(
              position: _bottomPanelAnimation,
              child: Container(
                height: bottomPanelHeight,
                width: double.infinity,
                color: const Color(0xFF1f1e25), // Grey background
              ),
            ),
          ),
          // Divider: positioned at screenHeight / 10 from the bottom
          Positioned(
            bottom: bottomPanelHeight,
            left: 0, // Ensure fully constrained horizontally
            right: 0, // Ensure fully constrained horizontally
            child: Container(
              height: dividerHeight,
              color: const Color(0xFF1f1e25),
            ),
          ),
          // Copyright info: positioned above the bottom panel
          // Centered circular logo with fade-out effect
          Positioned(
            bottom: bottomPanelHeight - 75, // Center logo over the divider
            left: MediaQuery.of(context).size.width / 2 - 75, // Center horizontally
            child: GestureDetector(
              onTap: _onLogoTap,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF1f1e25),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.real_estate_agent,
                      size: 100,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}