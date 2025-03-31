import 'package:flutter/material.dart';

class AppOverview extends StatelessWidget {
  static const Color neonPurple = Color(0xFFD500F9);

  const AppOverview({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      color: Colors.black,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 100),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // First Column: App Overview with two sub-columns (70% width)
          Expanded(
            flex: 6, // 60% of the available space
            child: Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                      'App Overview',
                      style: TextStyle(
                        fontSize: 56,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 60),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Sub-column 1: First two points
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
                      const SizedBox(width: 40),
                      // Sub-column 2: Last two points
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
                ],
              ),
            ),
          ),
          // Second Column: Placeholder for Images (40% width)
          Expanded(
            flex: 4,
            child: Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Image Placeholder',
                    style: TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    height: 200, // Adjust height as needed
                    width: double.infinity,
                    color: Colors.grey.withOpacity(0.3), // Placeholder background
                    child: const Center(
                      child: Text(
                        'Upload Images Here Later',
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    ),
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