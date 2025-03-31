import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:slider_button/slider_button.dart';
import 'feature_container.dart';

class HeaderHeroPage extends StatelessWidget {
  final VideoPlayerController videoController;
  final bool isVideoInitialized;
  final double videoOpacity;

  const HeaderHeroPage({
    required this.videoController,
    required this.isVideoInitialized,
    required this.videoOpacity,
    super.key,
  });

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
    return SizedBox(
      width: double.infinity,
      height: MediaQuery.of(context).size.height * 1 + AppBar().preferredSize.height,
      child: Stack(
        children: [
          // Video layer with opacity
          if (isVideoInitialized)
            Positioned.fill(
              child: Opacity(
                opacity: videoOpacity.clamp(0.0, 1.0),
                child: AspectRatio(
                  aspectRatio: videoController.value.aspectRatio, // Use video's native aspect ratio
                  child: FittedBox(
                    fit: BoxFit.cover,
                    clipBehavior: Clip.hardEdge, // Ensure no overflow
                    child: SizedBox(
                      width: videoController.value.size.width,
                      height: videoController.value.size.height,
                      child: VideoPlayer(videoController),
                    ),
                  ),
                ),
              ),
            )
          else
            const Center(child: CircularProgressIndicator(color: Colors.white)),
          // Navbar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
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
                        onPressed: () {},
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: neonPurple),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        ),
                        child: const Text('Log In', style: TextStyle(color: Colors.white, fontSize: 18)),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton(
                        onPressed: () {},
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
          // Main text and slider button
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
                  child: const Text(
                    'Automate Analysis, Multiply Deals',
                    style: TextStyle(
                      fontSize: 76,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Turn spreadsheet hours into investor-ready insights instantly.',
                  style: TextStyle(fontSize: 22, color: Colors.white),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                StatefulBuilder(
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
                            print('Slider completed - no action');
                            return false;
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
              ],
            ),
          ),
          // Feature containers
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FeatureContainer(icon: Icons.hourglass_empty, title: '10 Hours Saved Weekly', cta: 'See How'),
                const SizedBox(width: 24),
                FeatureContainer(icon: Icons.lightbulb, title: 'Swipe-to-Invest', cta: 'Watch Demo'),
                const SizedBox(width: 24),
                FeatureContainer(icon: Icons.handshake, title: 'Branded Collaboration', cta: 'Customize Portal'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}