import 'package:flutter/material.dart';

class RealtorStats extends StatefulWidget {
  final ScrollController scrollController;

  const RealtorStats({super.key, required this.scrollController});

  @override
  _RealtorStatsState createState() => _RealtorStatsState();
}

class _RealtorStatsState extends State<RealtorStats> with SingleTickerProviderStateMixin {
  static const Color neonPurple = Color(0xFFD500F9);
  static const Color darkPurple = Color(0xFF4A0072);
  late AnimationController _animationController;
  late Animation<double> _barAnimation;
  bool _isVisible = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000), // Animation duration
      vsync: this,
    );
    _barAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    // Listen to scroll position
    widget.scrollController.addListener(_checkVisibility);
  }

  void _checkVisibility() {
    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final position = renderBox.localToGlobal(Offset.zero);
    final screenHeight = MediaQuery.of(context).size.height;
    final widgetTop = position.dy;
    final widgetBottom = widgetTop + renderBox.size.height;

    // Check if the widget is at least partially visible
    final isVisible = widgetTop < screenHeight && widgetBottom > 0;

    if (isVisible && !_isVisible) {
      setState(() {
        _isVisible = true;
        _animationController.forward(from: 0); // Start animation
      });
    } else if (!isVisible && _isVisible) {
      setState(() {
        _isVisible = false;
        _animationController.reset(); // Reset animation
      });
    }
  }

  @override
  void dispose() {
    widget.scrollController.removeListener(_checkVisibility);
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(100, 40, 100, 40),
      color: Colors.black,
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
              'Our Clients',
              style: TextStyle(
                fontSize: 56,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 100),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Column 1: Profile Photo, Name, and Quote
              Expanded(
                flex: 1,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: neonPurple, width: 2),
                        image: const DecorationImage(
                          image: AssetImage('assets/images/greg.jpg'),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Greg - "Using realEst streamlined my workflow and \nhelped my clients close deals faster than ever!"',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontStyle: FontStyle.italic,
                        fontFamily: 'homePage',
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 40),
              // Column 2: Horizontal Bar Graph and Text
              Expanded(
                flex: 1,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Description above the bar
                    const Text(
                      "Closing Speed Comparison",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontFamily: 'homePage',
                      ),
                    ),
                    const SizedBox(height: 30),
                    // Animated horizontal bar
                    AnimatedBuilder(
                      animation: _barAnimation,
                      builder: (context, child) {
                        const maxValue = 40; // Max value is 35%
                        final othersWidth = (20 / maxValue) * _barAnimation.value; // 18% of max
                        final realEstWidth = (28 / maxValue) * _barAnimation.value; // 28% of max
                        final barWidth = MediaQuery.of(context).size.width * 0.5; // Limit bar width to 50% of screen

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Bar Graph
                            Stack(
                              children: [
                                // Full bar background (35%)
                                Container(
                                  height: 40,
                                  width: barWidth,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[800],
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                // Dark purple portion (0% to 18%)
                                Container(
                                  height: 40,
                                  width: barWidth * othersWidth,
                                  decoration: BoxDecoration(
                                    color: darkPurple,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                // Neon purple portion (0% to 28%)
                                Container(
                                  height: 40,
                                  width: barWidth * realEstWidth,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [darkPurple, neonPurple],
                                      stops: const [0.643, 0.643], // 18/28 ≈ 0.643
                                      begin: Alignment.centerLeft,
                                      end: Alignment.centerRight,
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 5),
                            // Labels with arrows and percentages
                            SizedBox(
                              width: barWidth,
                              height: 80, // Fixed height for labels
                              child: Stack(
                                children: [
                                  // "Others" label at 18%
                                  Positioned(
                                    left: barWidth * (20 / 40) - 65, // Center under 18%
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
                                  // "realEst" label at 28%
                                  Positioned(
                                    left: barWidth * (28 / 40) - 35, // Center under 28%
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
                    // Labels with arrows and percentages
                    const SizedBox(height: 30),
                    const Text(
                      "Greg's clients close 28% faster – will you be next?",
                      style: TextStyle(
                        color: neonPurple,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'homePage',
                      ),
                      textAlign: TextAlign.left,
                    ),
                    const SizedBox(height: 40),
                    ElevatedButton(
                      onPressed: () {
                        // Add your navigation logic here
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: neonPurple,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 30,
                          vertical: 15,
                        ),
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
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}