import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';

/// Displays an animated overview of the app's features with a carousel of screenshots.
class AppOverview extends StatefulWidget {
  /// Creates an [AppOverview] instance.
  const AppOverview({super.key});

  @override
  _AppOverviewState createState() => _AppOverviewState();
}

/// State for [AppOverview], managing animations and carousel functionality.
class _AppOverviewState extends State<AppOverview> with TickerProviderStateMixin {
  /// Neon purple color used for styling text and icons.
  static const Color neonPurple = Color(0xFFa78cde);

  /// Controller for the carousel slider.
  final CarouselSliderController _carouselController = CarouselSliderController();

  /// Tracks the current carousel page index.
  int _currentPage = 0;

  /// Controller for title fade animation.
  late AnimationController _titleController;

  /// Fade animation for the title.
  late Animation<double> _titleFadeAnimation;

  /// Controller for left text fade and slide animations.
  late AnimationController _leftTextController;

  /// Fade animation for the left text section.
  late Animation<double> _leftTextFadeAnimation;

  /// Slide animation for the left text section.
  late Animation<Offset> _leftTextSlideAnimation;

  /// Controller for carousel fade and slide animations.
  late AnimationController _carouselControllerAnim;

  /// Fade animation for the carousel.
  late Animation<double> _carouselFadeAnimation;

  /// Slide animation for the carousel.
  late Animation<Offset> _carouselSlideAnimation;

  /// Flag to track if the widget is visible for animation triggers.
  bool _isVisible = false;

  @override
  void initState() {
    super.initState();

    // Initialize title animation
    _titleController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _titleFadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _titleController, curve: Curves.easeIn),
    );

    // Initialize left text animations
    _leftTextController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _leftTextFadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _leftTextController, curve: Curves.easeIn),
    );
    _leftTextSlideAnimation = Tween<Offset>(
      begin: const Offset(-0.5, 0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _leftTextController, curve: Curves.easeOut),
    );

    // Initialize carousel animations
    _carouselControllerAnim = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _carouselFadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _carouselControllerAnim, curve: Curves.easeIn),
    );
    _carouselSlideAnimation = Tween<Offset>(
      begin: const Offset(0.5, 0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _carouselControllerAnim, curve: Curves.easeOut),
    );

    _startAnimations();
  }

  @override
  void dispose() {
    /// Disposes of all animation controllers to prevent memory leaks.
    _titleController.dispose();
    _leftTextController.dispose();
    _carouselControllerAnim.dispose();
    super.dispose();
  }

  /// Starts animations with staggered delays for a smooth reveal effect.
  void _startAnimations() {
    _titleController.forward(from: 0);
    Future.delayed(const Duration(milliseconds: 400), () {
      _leftTextController.forward(from: 0);
      Future.delayed(const Duration(milliseconds: 400), () {
        _carouselControllerAnim.forward(from: 0);
      });
    });
    setState(() {
      _isVisible = true;
    });
  }

  /// Resets animations and visibility state when the widget is off-screen.
  void _resetAnimations() {
    _titleController.reset();
    _leftTextController.reset();
    _carouselControllerAnim.reset();
    setState(() {
      _isVisible = false;
    });
  }

  @override
  void didUpdateWidget(AppOverview oldWidget) {
    super.didUpdateWidget(oldWidget);
    /// Restarts animations if the widget becomes visible again.
    if (!_isVisible) {
      _startAnimations();
    }
  }

  @override
  Widget build(BuildContext context) {
    /// Builds the overview section with a scroll listener for animation resets.
    return NotificationListener<ScrollNotification>(
      onNotification: (scrollNotification) {
        if (scrollNotification is ScrollEndNotification) {
          final RenderBox? box = context.findRenderObject() as RenderBox?;
          if (box != null) {
            final Offset position = box.localToGlobal(Offset.zero);
            final double screenHeight = MediaQuery.of(context).size.height;
            if (position.dy < -box.size.height || position.dy > screenHeight) {
              _resetAnimations();
            }
          }
        }
        return true;
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 800;

          return Container(
            height: MediaQuery.of(context).size.height * (isMobile ? 1.2 : 0.9),
            color: const Color(0xFF1f1e25),
            padding: EdgeInsets.symmetric(
              vertical: isMobile ? 16 : 40,
              horizontal: isMobile ? 60 : 100,
            ),
            child: isMobile
                ? Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                FadeTransition(
                  opacity: _titleFadeAnimation,
                  child: ShaderMask(
                    shaderCallback: (Rect bounds) {
                      return const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: [0.0, 0.7, 1.0],
                        colors: [neonPurple, Colors.white, Colors.white],
                      ).createShader(bounds);
                    },
                    child: Text(
                      'App Overview',
                      style: TextStyle(
                        fontSize: isMobile ? 32 : 56,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                const SizedBox(height: 50),
                SlideTransition(
                  position: _leftTextSlideAnimation,
                  child: FadeTransition(
                    opacity: _leftTextFadeAnimation,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '📱 Dual UI Ecosystem:',
                          style: TextStyle(
                            fontSize: 18,
                            color: neonPurple,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Power tools for agents, simple swipes for buyers',
                          style: TextStyle(fontSize: 12, color: Colors.white),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          '🚀 Cash Flow Calculator:',
                          style: TextStyle(
                            fontSize: 18,
                            color: neonPurple,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'MLS-integrated ROI/cap rate insights with manual override capability',
                          style: TextStyle(fontSize: 12, color: Colors.white),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          '🔗 Realtor Branding:',
                          style: TextStyle(
                            fontSize: 18,
                            color: neonPurple,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'White-label interface with your logo/colors for client-facing interactions',
                          style: TextStyle(fontSize: 12, color: Colors.white),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          '⚡ Instant Match System:',
                          style: TextStyle(
                            fontSize: 18,
                            color: neonPurple,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Tag clients, send listings in bulk, and track responses in real time',
                          style: TextStyle(fontSize: 12, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: SlideTransition(
                    position: _carouselSlideAnimation,
                    child: FadeTransition(
                      opacity: _carouselFadeAnimation,
                      child: _buildCarousel(isMobile),
                    ),
                  ),
                ),
              ],
            )
                : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  flex: 6,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FadeTransition(
                          opacity: _titleFadeAnimation,
                          child: ShaderMask(
                            shaderCallback: (Rect bounds) {
                              return const LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                stops: [0.0, 0.7, 1.0],
                                colors: [neonPurple, Colors.white, Colors.white],
                              ).createShader(bounds);
                            },
                            child: const Text(
                              'App Overview',
                              style: TextStyle(
                                fontSize: 56,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                        const SizedBox(height: 60),
                        SlideTransition(
                          position: _leftTextSlideAnimation,
                          child: FadeTransition(
                            opacity: _leftTextFadeAnimation,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        '📱 Dual UI Ecosystem:',
                                        style: TextStyle(
                                          fontSize: 28,
                                          color: neonPurple,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 20),
                                      const Text(
                                        '    - Power tools for agents, simple swipes for buyers',
                                        style: TextStyle(fontSize: 18, color: Colors.white),
                                      ),
                                      const SizedBox(height: 100),
                                      const Text(
                                        '🚀 Cash Flow Calculator:',
                                        style: TextStyle(
                                          fontSize: 28,
                                          color: neonPurple,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 20),
                                      const Text(
                                        '    - MLS-integrated ROI/cap rate insights with manual override capability',
                                        style: TextStyle(fontSize: 18, color: Colors.white),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 30),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        '🔗 Realtor Branding:',
                                        style: TextStyle(
                                          fontSize: 28,
                                          color: neonPurple,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 20),
                                      const Text(
                                        'White-label interface with your logo/colors for client-facing interactions',
                                        style: TextStyle(fontSize: 18, color: Colors.white),
                                      ),
                                      const SizedBox(height: 100),
                                      const Text(
                                        '⚡ Instant Match System:',
                                        style: TextStyle(
                                          fontSize: 28,
                                          color: neonPurple,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 20),
                                      const Text(
                                        'Tag clients, send listings in bulk, and track responses in real time',
                                        style: TextStyle(fontSize: 18, color: Colors.white),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  flex: 4,
                  child: SlideTransition(
                    position: _carouselSlideAnimation,
                    child: FadeTransition(
                      opacity: _carouselFadeAnimation,
                      child: _buildCarousel(isMobile),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Builds the animated carousel of app screenshots.
  ///
  /// [isMobile] determines the size of navigation icons.
  /// Returns a [Widget] containing the carousel and navigation controls.
  Widget _buildCarousel(bool isMobile) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                CarouselSlider(
                  carouselController: _carouselController,
                  options: CarouselOptions(
                    aspectRatio: 16 / 9,
                    viewportFraction: 1.0,
                    initialPage: 0,
                    enableInfiniteScroll: true,
                    autoPlay: true,
                    autoPlayInterval: const Duration(seconds: 3),
                    autoPlayAnimationDuration: const Duration(milliseconds: 800),
                    autoPlayCurve: Curves.easeInOut,
                    enlargeCenterPage: true,
                    onPageChanged: (index, reason) {
                      setState(() {
                        _currentPage = index;
                      });
                    },
                    scrollDirection: Axis.horizontal,
                  ),
                  items: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          image: const DecorationImage(
                            image: AssetImage('assets/demo/dashboard.png'),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          image: const DecorationImage(
                            image: AssetImage('assets/demo/login.png'),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          image: const DecorationImage(
                            image: AssetImage('assets/demo/house_search.png'),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                Positioned(
                  left: 0,
                  child: IconButton(
                    icon: Icon(Icons.arrow_left, color: neonPurple, size: isMobile ? 30 : 40),
                    onPressed: () {
                      _carouselController.previousPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                  ),
                ),
                Positioned(
                  right: 0,
                  child: IconButton(
                    icon: Icon(Icons.arrow_right, color: neonPurple, size: isMobile ? 30 : 40),
                    onPressed: () {
                      _carouselController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (index) {
              return GestureDetector(
                onTap: () {
                  _carouselController.animateToPage(
                    index,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
                child: Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentPage == index
                        ? neonPurple
                        : Colors.white.withOpacity(0.5),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}