import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
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
  late AnimationController _buttonController;
  late Animation<double> _buttonAnimation;
  late AnimationController _featuresController;
  late Animation<double> _featuresAnimation;

  bool _hasTyped = false;
  bool _isVideoReady = false;

  @override
  void initState() {
    super.initState();
    _headerController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _headerAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _headerController, curve: Curves.easeIn),
    );

    _subtitleController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _subtitleAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _subtitleController, curve: Curves.easeIn),
    );

    _buttonController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _buttonAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _buttonController, curve: Curves.easeIn),
    );

    _featuresController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _featuresAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _featuresController, curve: Curves.easeIn),
    );

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _headerController.forward();
    });
    Future.delayed(const Duration(milliseconds: 2000), () {
      if (mounted) _subtitleController.forward();
    });
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) _buttonController.forward();
    });
    Future.delayed(const Duration(milliseconds: 3200), () {
      if (mounted) _featuresController.forward();
    });

    _isVideoReady = widget.isVideoInitialized;
    if (_isVideoReady) {
      _startVideoPlayback();
    } else {
      widget.videoController.addListener(_onVideoControllerUpdate);
    }
  }

  void _onVideoControllerUpdate() {
    if (widget.videoController.value.isInitialized && !_isVideoReady) {
      if (!mounted) return;
      setState(() {
        _isVideoReady = true;
      });
      _startVideoPlayback();
      widget.videoController.removeListener(_onVideoControllerUpdate);
    }
  }

  void _startVideoPlayback() {
    widget.videoController.setLooping(true);
    widget.videoController.play();
  }

  @override
  void didUpdateWidget(HeaderHeroPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.videoController != oldWidget.videoController) {
      oldWidget.videoController.removeListener(_onVideoControllerUpdate);
      _isVideoReady = widget.videoController.value.isInitialized;
      if (_isVideoReady) {
        _startVideoPlayback();
      } else {
        widget.videoController.addListener(_onVideoControllerUpdate);
      }
    }
  }

  @override
  void dispose() {
    _headerController.dispose();
    _subtitleController.dispose();
    _buttonController.dispose();
    _featuresController.dispose();
    widget.videoController.removeListener(_onVideoControllerUpdate);
    super.dispose();
  }

  static const Color neonPurple = Color(0xFFD500F9);

  Widget _tabButton(BuildContext context, String title) {
    return TextButton(
      onPressed: () {},
      child: Text(
        title,
        style: const TextStyle(color: Colors.white, fontSize: 16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 800;

        return SizedBox(
          width: double.infinity,
          height: MediaQuery.of(context).size.height + AppBar().preferredSize.height,
          child: Stack(
            children: [
              if (_isVideoReady)
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
              Positioned.fill(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      FadeTransition(
                        opacity: _headerAnimation,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.real_estate_agent, color: neonPurple, size: 32),
                                  SizedBox(width: 8),
                                  Text(
                                    'RealEst',
                                    style: TextStyle(
                                        color: Colors.white, fontSize: isMobile ? 24 : 32),
                                  ),
                                ],
                              ),
                              if (!isMobile)
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
                                    onPressed: () => context.go('/login'),
                                    style: OutlinedButton.styleFrom(
                                      side: const BorderSide(color: neonPurple),
                                      padding: EdgeInsets.symmetric(
                                        horizontal: isMobile ? 10 : 20,
                                        vertical: isMobile ? 8 : 16,
                                      ),
                                    ),
                                    child: Text(
                                      'Log In',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: isMobile ? 14 : 18,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton(
                                    onPressed: () => context.go('/login'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      padding: EdgeInsets.symmetric(
                                        horizontal: isMobile ? 10 : 20,
                                        vertical: isMobile ? 8 : 16,
                                      ),
                                    ),
                                    child: Text(
                                      'Sign Up',
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontSize: isMobile ? 14 : 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: isMobile ? 40 : 100),
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
                            ? Text(
                          'Automate Analysis, Multiply Deals',
                          style: TextStyle(
                            fontSize: isMobile ? 34 : 76,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        )
                            : AnimatedTextKit(
                          animatedTexts: [
                            TypewriterAnimatedText(
                              'Automate Analysis, Multiply Deals',
                              textStyle: TextStyle(
                                fontSize: isMobile ? 34 : 76,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                              speed: const Duration(milliseconds: 80),
                              cursor: '',
                            ),
                          ],
                          isRepeatingAnimation: false,
                          displayFullTextOnTap: true,
                          stopPauseOnTap: true,
                          onFinished: () {
                            if (!mounted) return;
                            setState(() => _hasTyped = true);
                          },
                        ),
                      ),
                      const SizedBox(height: 20),
                      FadeTransition(
                        opacity: _subtitleAnimation,
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: isMobile ? 32 : 0),
                          child: Text(
                            'Turn spreadsheet hours into investor-ready insights instantly.',
                            style: TextStyle(
                              fontSize: isMobile ? 14 : 24,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                      FadeTransition(
                        opacity: _buttonAnimation,
                        child: ElevatedButton(
                          onPressed: () => context.go('/login'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            foregroundColor: neonPurple,
                            padding: EdgeInsets.symmetric(
                              horizontal: isMobile ? 20 : 40,
                              vertical: isMobile ? 10 : 20,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                              side: const BorderSide(color: neonPurple, width: 2),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Get Started',
                                style: TextStyle(
                                  color: neonPurple,
                                  fontSize: isMobile ? 16 : 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                Icons.arrow_forward,
                                color: neonPurple,
                                size: isMobile ? 20 : 40,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 100),
                      FadeTransition(
                        opacity: _featuresAnimation,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 30),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                FeatureContainer(
                                  icon: Icons.hourglass_empty,
                                  title: '10 Hours Saved Weekly',
                                  cta: 'Learn More',
                                ),
                                const SizedBox(width: 12), // Reduced from 16
                                FeatureContainer(
                                  icon: Icons.lightbulb,
                                  title: 'Swipe-to-Invest',
                                  cta: 'Watch Demo',
                                ),
                                const SizedBox(width: 12), // Reduced from 16
                                FeatureContainer(
                                  icon: Icons.handshake,
                                  title: 'Branded Collaboration',
                                  cta: isMobile ? 'Customize' : 'Customize Portal',
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: isMobile ? 20 : 100),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}