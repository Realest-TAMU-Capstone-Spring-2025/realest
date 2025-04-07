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
    final panelHeight = (screenHeight - dividerHeight) / 2;

    // Single image provider to avoid loading the image twice.
    final imageProvider = AssetImage('assets/images/login.png');

    return Scaffold(
      body: Stack(
        children: [
          // Base background.
          Container(
            width: double.infinity,
            height: double.infinity,
            color: const Color(0xFF1f1e25),
          ),
          // Top panel: show top half of the image.
          SlideTransition(
            position: _topPanelAnimation,
            child: Container(
              height: panelHeight,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Clip to show only the top half of the image.
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
                  // Content on top of the image.
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
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
          // Bottom panel: show bottom half of the image.
          Align(
            alignment: Alignment.bottomCenter,
            child: SlideTransition(
              position: _bottomPanelAnimation,
              child: Container(
                height: panelHeight,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Clip to show only the bottom half of the image.
                    ClipRect(
                      child: OverflowBox(
                        maxHeight: screenHeight,
                        alignment: Alignment.bottomCenter,
                        child: Image(
                          image: imageProvider,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: screenHeight,
                        ),
                      ),
                    ),
                    // Content on top of the image.
                    const Center(
                      child: Text(
                        'Click on logo to get started',
                        style: TextStyle(
                          fontSize: 24,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Center divider.
          Align(
            alignment: Alignment.center,
            child: Container(
              width: double.infinity,
              height: dividerHeight,
              color: const Color(0xFF1f1e25),
            ),
          ),
          // Centered circular logo with fade-out effect.
          Center(
            child: GestureDetector(
              onTap: _onLogoTap,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF1f1e25),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.real_estate_agent,
                      size: 120,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Copyright info.
          SlideTransition(
            position: _bottomPanelAnimation,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 40),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Text(
                      '© 2025 RealEst',
                      style: TextStyle(
                        fontSize: 24,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}