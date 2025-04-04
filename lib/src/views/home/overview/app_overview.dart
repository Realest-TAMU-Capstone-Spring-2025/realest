import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';

class AppOverview extends StatefulWidget {
  const AppOverview({super.key});

  @override
  _AppOverviewState createState() => _AppOverviewState();
}

class _AppOverviewState extends State<AppOverview> with TickerProviderStateMixin {
  static const Color neonPurple = Color(0xFFD500F9);

  final CarouselSliderController _carouselController = CarouselSliderController();
  int _currentPage = 0;

  // Animation controllers
  late AnimationController _titleController;
  late Animation<double> _titleFadeAnimation;
  late AnimationController _leftTextController;
  late Animation<double> _leftTextFadeAnimation;
  late Animation<Offset> _leftTextSlideAnimation;
  late AnimationController _carouselControllerAnim;
  late Animation<double> _carouselFadeAnimation;
  late Animation<Offset> _carouselSlideAnimation;

  // Flag to track visibility
  bool _isVisible = false;

  @override
  void initState() {
    super.initState();

    // Title fade-in
    _titleController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _titleFadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _titleController, curve: Curves.easeIn),
    );

    // Left text fade-in and slide-in
    _leftTextController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _leftTextFadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _leftTextController, curve: Curves.easeIn),
    );
    _leftTextSlideAnimation = Tween<Offset>(
      begin: const Offset(-0.5, 0), // Slide from left
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _leftTextController, curve: Curves.easeOut),
    );

    // Carousel fade-in and slide-in
    _carouselControllerAnim = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _carouselFadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _carouselControllerAnim, curve: Curves.easeIn),
    );
    _carouselSlideAnimation = Tween<Offset>(
      begin: const Offset(0.5, 0), // Slide from right
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _carouselControllerAnim, curve: Curves.easeOut),
    );

    // Start animations when widget is first built
    _startAnimations();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _leftTextController.dispose();
    _carouselControllerAnim.dispose();
    super.dispose();
  }

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

  void _resetAnimations() {
    _titleController.reset();
    _leftTextController.reset();
    _carouselControllerAnim.reset();
    setState(() {
      _isVisible = false;
    });
  }

  // Check visibility when widget is rebuilt (e.g., after scrolling)
  @override
  void didUpdateWidget(AppOverview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isVisible) {
      _startAnimations();
    }
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (scrollNotification) {
        if (scrollNotification is ScrollEndNotification) {
          // Check if widget is out of viewport (simplified approach)
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
      child: Container(
        height: MediaQuery.of(context).size.height * 0.9,
        color: Colors.black,
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 100),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Left section: Text content with fade and slide
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
                                    style: TextStyle(fontSize: 28, color: neonPurple, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 20),
                                  const Text(
                                    '    - Power tools for agents, simple swipes for buyers',
                                    style: TextStyle(fontSize: 18, color: Colors.white),
                                  ),
                                  const SizedBox(height: 100),
                                  const Text(
                                    '🚀 Cash Flow Calculator:',
                                    style: TextStyle(fontSize: 28, color: neonPurple, fontWeight: FontWeight.bold),
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
                                    style: TextStyle(fontSize: 28, color: neonPurple, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 20),
                                  const Text(
                                    'White-label interface with your logo/colors for client-facing interactions',
                                    style: TextStyle(fontSize: 18, color: Colors.white),
                                  ),
                                  const SizedBox(height: 100),
                                  const Text(
                                    '⚡ Instant Match System:',
                                    style: TextStyle(fontSize: 28, color: neonPurple, fontWeight: FontWeight.bold),
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
            // Right section: Carousel slider with fade and slide
            Expanded(
              flex: 4,
              child: SlideTransition(
                position: _carouselSlideAnimation,
                child: FadeTransition(
                  opacity: _carouselFadeAnimation,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            CarouselSlider(
                              carouselController: _carouselController,
                              options: CarouselOptions(
                                height: 500,
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
                                Stack(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.all(20.0),
                                      child: Container(
                                        width: double.infinity,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(10),
                                          image: const DecorationImage(
                                            image: AssetImage('assets/demo/dashboard.png'),
                                            fit: BoxFit.contain,
                                          ),
                                        ),
                                      ),
                                    ),
                                    Container(
                                      width: double.infinity,
                                      height: 500,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(10),
                                        image: const DecorationImage(
                                          image: AssetImage('assets/browser.png'),
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                Stack(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.all(20.0),
                                      child: Container(
                                        width: double.infinity,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(10),
                                          image: const DecorationImage(
                                            image: AssetImage('assets/demo/login.png'),
                                            fit: BoxFit.contain,
                                          ),
                                        ),
                                      ),
                                    ),
                                    Container(
                                      width: double.infinity,
                                      height: 500,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(10),
                                        image: const DecorationImage(
                                          image: AssetImage('assets/browser.png'),
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                Stack(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.all(20.0),
                                      child: Container(
                                        width: double.infinity,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(10),
                                          image: const DecorationImage(
                                            image: AssetImage('assets/demo/house_search.png'),
                                            fit: BoxFit.contain,
                                          ),
                                        ),
                                      ),
                                    ),
                                    Container(
                                      width: double.infinity,
                                      height: 500,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(10),
                                        image: const DecorationImage(
                                          image: AssetImage('assets/demo/browser.png'),
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            Positioned(
                              left: 0,
                              child: IconButton(
                                icon: const Icon(Icons.arrow_left, color: neonPurple, size: 40),
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
                                icon: const Icon(Icons.arrow_right, color: neonPurple, size: 40),
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
                        const SizedBox(height: 20),
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
                                width: 10,
                                height: 10,
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
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}