import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:slider_button/slider_button.dart';
import 'package:go_router/go_router.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'feature_container.dart';

class HeaderHeroPage extends StatefulWidget {
  final VideoPlayerController videoController;
  final bool isVideoInitialized;
  final double videoOpacity;

  const HeaderHeroPage({
    required this.videoController,
    required this.isVideoInitialized,
    required this.videoOpacity,
    super.key,
  });

  @override
  _HeaderHeroPageState createState() => _HeaderHeroPageState();
}

class _HeaderHeroPageState extends State<HeaderHeroPage> with TickerProviderStateMixin {
  late AnimationController _headerController;
  late Animation<double> _headerAnimation;
  late AnimationController _subtitleController;
  late Animation<double> _subtitleAnimation;
  late AnimationController _sliderController;
  late Animation<double> _sliderAnimation;
  late AnimationController _featuresController;
  late Animation<double> _featuresAnimation;

  // Flag to ensure typing animation runs only once
  bool _hasTyped = false;

  @override
  void initState() {
    super.initState();

    // Header animation controller
    _headerController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _headerAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _headerController, curve: Curves.easeIn),
    );

    // Subtitle animation controller
    _subtitleController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _subtitleAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _subtitleController, curve: Curves.easeIn),
    );

    // Slider button animation controller
    _sliderController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _sliderAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _sliderController, curve: Curves.easeIn),
    );

    // Features animation controller
    _featuresController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _featuresAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _featuresController, curve: Curves.easeIn),
    );

    // Start header animation immediately
    _headerController.forward();

    // Debug print to track init
    debugPrint('HeaderHeroPage initState called');
  }

  @override
  void dispose() {
    _headerController.dispose();
    _subtitleController.dispose();
    _sliderController.dispose();
    _featuresController.dispose();
    super.dispose();
  }

  void startAnimations() {
    _subtitleController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      _sliderController.forward();
      Future.delayed(const Duration(milliseconds: 300), () {
        _featuresController.forward();
      });
    });
  }

  static const Color neonPurple = Color(0xFFD500F9);

  Widget _tabButton(BuildContext context, String title) {
    return TextButton(
      onPressed: () {},
      child: Text(
        title,
        style: const TextStyle(color: Colors.white, fontSize: 18),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Debug print to track rebuilds
    debugPrint('HeaderHeroPage build called');

    return SizedBox(
      width: double.infinity,
      height: MediaQuery.of(context).size.height + AppBar().preferredSize.height,
      child: Stack(
        children: [
          // Video layer with opacity, no loading circle
          if (widget.isVideoInitialized)
            Positioned.fill(
              child: Opacity(
                opacity: widget.videoOpacity.clamp(0.0, 1.0),
                child: AspectRatio(
                  aspectRatio: widget.videoController.value.aspectRatio,
                  child: FittedBox(
                    fit: BoxFit.cover,
                    clipBehavior: Clip.hardEdge,
                    child: SizedBox(
                      width: widget.videoController.value.size.width,
                      height: widget.videoController.value.size.height,
                      child: VideoPlayer(widget.videoController),
                    ),
                  ),
                ),
              ),
            )
          else
            Container(color: Colors.black),

          // Navbar with fade-in animation
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: FadeTransition(
              opacity: _headerAnimation,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.real_estate_agent, color: neonPurple, size: 40),
                        SizedBox(width: 8),
                        Text('RealEst', style: TextStyle(color: Colors.white, fontSize: 32)),
                      ],
                    ),
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
                            decoration: BoxDecoration(
                              border: Border.all(color: neonPurple),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _tabButton(context, 'Overview'),
                                const SizedBox(width: 16),
                                _tabButton(context, 'Realtors'),
                                const SizedBox(width: 16),
                                _tabButton(context, 'Investors'),
                                const SizedBox(width: 16),
                                _tabButton(context, 'Solutions'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        OutlinedButton(
                          onPressed: () {
                            context.go('/login');
                          },
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: neonPurple),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          ),
                          child: const Text('Log In', style: TextStyle(color: Colors.white, fontSize: 18)),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton(
                          onPressed: () {
                            context.go('/login');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          ),
                          child: const Text('Sign Up', style: TextStyle(color: Colors.black, fontSize: 18)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Main text and slider button with animations
          Positioned(
            top: 180,
            left: 0,
            right: 0,
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
                  child: _hasTyped
                      ? const Text(
                    'Automate Analysis, Multiply Deals',
                    style: TextStyle(
                      fontSize: 76,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  )
                      : AnimatedTextKit(
                    animatedTexts: [
                      TypewriterAnimatedText(
                        'Automate Analysis, Multiply Deals',
                        textStyle: const TextStyle(
                          fontSize: 76,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                        speed: const Duration(milliseconds: 50),
                      ),
                    ],
                    isRepeatingAnimation: false,
                    displayFullTextOnTap: true,
                    stopPauseOnTap: true,
                    onFinished: () {
                      setState(() {
                        _hasTyped = true; // Switch to static text after animation
                      });
                      startAnimations();
                    },
                  ),
                ),
                const SizedBox(height: 20),
                FadeTransition(
                  opacity: _subtitleAnimation,
                  child: const Text(
                    'Turn spreadsheet hours into investor-ready insights instantly.',
                    style: TextStyle(fontSize: 22, color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 40),
                FadeTransition(
                  opacity: _sliderAnimation,
                  child: StatefulBuilder(
                    builder: (context, setState) {
                      bool isSliding = false;
                      return Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: isSliding ? Colors.black : neonPurple,
                            width: 2.0,
                          ),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: GestureDetector(
                          onHorizontalDragStart: (_) => setState(() => isSliding = true),
                          onHorizontalDragEnd: (_) => setState(() => isSliding = false),
                          child: SliderButton(
                            action: () async {
                              context.go('/login');
                            },
                            width: 200,
                            height: 60,
                            radius: 30,
                            backgroundColor: isSliding ? neonPurple : Colors.black,
                            buttonColor: neonPurple,
                            baseColor: neonPurple,
                            highlightedColor: Colors.white,
                            shimmer: false,
                            label: Text(
                              'Get Started',
                              style: TextStyle(
                                color: isSliding ? Colors.white : neonPurple,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            icon: const Icon(
                              Icons.arrow_forward,
                              color: Colors.white,
                              size: 30,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // Feature containers with fade-in animation
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: FadeTransition(
              opacity: _featuresAnimation,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FeatureContainer(
                    icon: Icons.hourglass_empty,
                    title: '10 Hours Saved Weekly',
                    cta: 'Learn More',
                  ),
                  const SizedBox(width: 24),
                  FeatureContainer(
                    icon: Icons.lightbulb,
                    title: 'Swipe-to-Invest',
                    cta: 'Watch Demo',
                  ),
                  const SizedBox(width: 24),
                  FeatureContainer(
                    icon: Icons.handshake,
                    title: 'Branded Collaboration',
                    cta: 'Customize Portal',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}