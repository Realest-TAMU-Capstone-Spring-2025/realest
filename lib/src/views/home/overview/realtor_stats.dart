import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// A section showcasing realtor statistics with animated bars and testimonials.
class RealtorStats extends StatefulWidget {
  /// Scroll controller to track visibility for animation triggers.
  final ScrollController scrollController;

  const RealtorStats({super.key, required this.scrollController});

  @override
  _RealtorStatsState createState() => _RealtorStatsState();
}

/// Manages animations and visibility state for [RealtorStats].
class _RealtorStatsState extends State<RealtorStats> with SingleTickerProviderStateMixin {
  /// Neon purple color used for styling text, buttons, and bars.
  static const Color neonPurple = Color(0xFFa78cde);

  /// Dark purple color used for progress bar gradients.
  static const Color darkPurple = Color(0xFF4A0072);

  /// Controller for all animations in the section.
  late AnimationController _animationController;

  /// Animation for progress bar growth effect.
  late Animation<double> _barAnimation;

  /// Animation for fading in elements.
  late Animation<double> _fadeAnimation;

  /// Animation for sliding in the testimonial text.
  late Animation<Offset> _slideAnimation;

  /// Animation for scaling the profile image.
  late Animation<double> _scaleAnimation;

  /// Tracks whether the section is visible on screen to trigger animations.
  bool _isVisible = false;

  @override
  void initState() {
    super.initState();
    // Initialize animation controller and animations
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 2300),
      vsync: this,
    );

    _barAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 2.0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    // Attach listener to check visibility and trigger animations
    widget.scrollController.addListener(_checkVisibility);
  }

  /// Checks if the section is visible on screen and triggers or resets animations.
  void _checkVisibility() {
    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final position = renderBox.localToGlobal(Offset.zero);
    final screenHeight = MediaQuery.of(context).size.height;
    final widgetTop = position.dy;
    final widgetBottom = widgetTop + renderBox.size.height;

    final isVisible = widgetTop < screenHeight && widgetBottom > 0;

    if (isVisible && !_isVisible) {
      setState(() {
        _isVisible = true;
        _animationController.forward(from: 0);
      });
    } else if (!isVisible && _isVisible) {
      setState(() {
        _isVisible = false;
        _animationController.reset();
      });
    }
  }

  @override
  void dispose() {
    // Dispose scroll listener and animation controller to prevent memory leaks
    widget.scrollController.removeListener(_checkVisibility);
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Builds the stats section with a responsive layout and animated elements
    final isMobile = MediaQuery.of(context).size.width < 800;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 20 : 100,
        vertical: 40,
      ),
      color: const Color(0xFF1f1e25),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ShaderMask(
            shaderCallback: (Rect bounds) {
              return const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0.0, 0.7, 1.0],
                colors: [neonPurple, Colors.white, Colors.white],
              ).createShader(bounds);
            },
            child: Text(
              'Our Clients',
              style: TextStyle(
                fontSize: isMobile ? 32 : 56,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 40),
          _buildContent(context),
        ],
      ),
    );
  }

  /// Builds the main content, adapting to mobile or desktop layouts.
  ///
  /// [context] The build context for responsive sizing.
  /// Returns a [Widget] containing the profile and progress sections.
  Widget _buildContent(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 800;

    return isMobile
        ? Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildProfileSection(),
        const SizedBox(height: 40),
        _buildProgressSection(context),
      ],
    )
        : Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 1, child: _buildProfileSection()),
        const SizedBox(width: 40),
        Expanded(flex: 1, child: _buildProgressSection(context)),
      ],
    );
  }

  /// Builds the profile section with an animated image and testimonial.
  ///
  /// Returns a [Widget] containing the profile image and testimonial text.
  Widget _buildProfileSection() {
    final isMobile = MediaQuery.of(context).size.width < 800;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ScaleTransition(
          scale: _scaleAnimation,
          child: Container(
            width: isMobile ? 120 : 200,
            height: isMobile ? 120 : 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: neonPurple, width: 2),
              image: const DecorationImage(
                image: AssetImage('assets/images/greg.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        SlideTransition(
          position: _slideAnimation,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Text(
              'Greg - "Using realEst streamlined my workflow and \nhelped my clients close deals faster than ever!"',
              style: TextStyle(
                color: Colors.white,
                fontSize: isMobile ? 14 : 18,
                fontStyle: FontStyle.italic,
                fontFamily: 'homePage',
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }

  /// Builds the progress section with animated bars and a call-to-action.
  ///
  /// [context] The build context for responsive sizing.
  /// Returns a [Widget] containing the progress bars and call-to-action button.
  Widget _buildProgressSection(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 800;
    final barWidth = isMobile ? MediaQuery.of(context).size.width * 0.8 : MediaQuery.of(context).size.width * 0.5;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Text(
          "Closing Speed Comparison",
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontFamily: 'homePage',
          ),
        ),
        const SizedBox(height: 30),
        AnimatedBuilder(
          animation: _barAnimation,
          builder: (context, child) {
            const maxValue = 40;
            final othersWidth = (20 / maxValue) * _barAnimation.value;
            final realEstWidth = (28 / maxValue) * _barAnimation.value;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    Container(
                      height: 40,
                      width: barWidth,
                      decoration: BoxDecoration(
                        color: Colors.grey[800],
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    Container(
                      height: 40,
                      width: barWidth * othersWidth,
                      decoration: BoxDecoration(
                        color: darkPurple,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    Container(
                      height: 40,
                      width: barWidth * realEstWidth,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [darkPurple, neonPurple],
                          stops: const [0.643, 0.643],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                SizedBox(
                  width: barWidth,
                  height: 80,
                  child: Stack(
                    children: [
                      Positioned(
                        left: barWidth * (20 / 40) - 65,
                        child: Column(
                          children: const [
                            Icon(Icons.arrow_drop_down, color: Colors.white, size: 30),
                            Text(
                              "Others",
                              style: TextStyle(color: Colors.white, fontSize: 18),
                            ),
                            Text(
                              "22%",
                              style: TextStyle(color: Colors.white, fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                        left: barWidth * (28 / 40) - 35,
                        child: Column(
                          children: const [
                            Icon(Icons.arrow_drop_down, color: neonPurple, size: 30),
                            Text(
                              "RealEst",
                              style: TextStyle(color: neonPurple, fontSize: 18),
                            ),
                            Text(
                              "28%",
                              style: TextStyle(color: neonPurple, fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 30),
        Text(
          "Greg's clients close 28% faster – will you be next?",
          style: TextStyle(
            color: neonPurple,
            fontSize: isMobile ? 18 : 24,
            fontWeight: FontWeight.bold,
            fontFamily: 'homePage',
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 40),
        ElevatedButton(
          onPressed: () => context.go('/login'),
          style: ElevatedButton.styleFrom(
            backgroundColor: neonPurple,
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
          child: const Text(
            'Schedule a Call',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}