import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:url_launcher/url_launcher.dart';
import 'feature_container.dart';

class HeaderHeroPage extends StatefulWidget {
  final double gifOpacity;

  const HeaderHeroPage({
    required this.gifOpacity,
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

  // Firebase Storage URL for the APK
  final String _apkDownloadUrl = 'https://firebasestorage.googleapis.com/v0/b/realest-3a0d2.firebasestorage.app/o/app-release.apk?alt=media&token=c765016a-1d08-4a4b-878b-07049821a861';

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
  }

  @override
  void dispose() {
    _headerController.dispose();
    _subtitleController.dispose();
    _buttonController.dispose();
    _featuresController.dispose();
    super.dispose();
  }

  static const Color neonPurple = Color(0xFFa78cde);

  Widget _tabButton(BuildContext context, String title) {
    return TextButton(
      onPressed: () {},
      child: Text(
        title,
        style: const TextStyle(color: Colors.white, fontSize: 20),
      ),
    );
  }

  // Function to launch the APK download URL
  Future<void> _launchApkDownload() async {
    final Uri url = Uri.parse(_apkDownloadUrl);
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not launch download URL')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error launching URL: $e')),
        );
      }
    }
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
              Positioned.fill(
                child: Opacity(
                  opacity: widget.gifOpacity.clamp(0.0, 1.0),
                  child: Image.asset(
                    'assets/videos/triangle.gif',
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                  ),
                ),
              ),
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
                                    onPressed: () => context.go('/login?register=true'),
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
                          onPressed: _launchApkDownload,
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
                                'Download Mobile APK',
                                style: TextStyle(
                                  color: neonPurple,
                                  fontSize: isMobile ? 16 : 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                Icons.download,
                                color: neonPurple,
                                size: isMobile ? 20 : 24,
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
                                const SizedBox(width: 12),
                                FeatureContainer(
                                  icon: Icons.lightbulb,
                                  title: 'Swipe-to-Invest',
                                  cta: 'Watch Demo',
                                ),
                                const SizedBox(width: 12),
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