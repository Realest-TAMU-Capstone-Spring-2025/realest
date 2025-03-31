import 'package:flutter/material.dart';
import 'value_prop_container.dart';

class ValuePropositions extends StatelessWidget {
  const ValuePropositions({super.key});

  static const Color neonPurple = Color(0xFFD500F9);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
      color: Colors.black, // Match HomePage background
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
              'Value Propositions',
              style: TextStyle(
                fontSize: 56,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 80),
          Wrap(
            spacing: 24,
            runSpacing: 24,
            alignment: WrapAlignment.center,
            children: [
              ValuePropContainer(
                icon: Icons.real_estate_agent,
                title: 'Realtors',
                subheading: 'Curate & Conquer',
                details: [
                  'Bulk listing distribution',
                  'Custom cash flow edits',
                  'Client analytics dashboard',
                ],
              ),
              ValuePropContainer(
                icon: Icons.swipe,
                title: 'Investors',
                subheading: 'Swipe to Invest',
                details: [
                  'Tinder Style Swiping',
                  'Interactive ROI calculator',
                  'Property comparison tool',
                ],
              ),
              ValuePropContainer(
                icon: Icons.hourglass_empty,
                title: 'Time Saver',
                subheading: '10hrs → 20mins Weekly',
                details: [
                  'Automated MLS data parsing',
                  'Pre-built report templates',
                  'Email/SMS notification system',
                ],
              ),
              ValuePropContainer(
                icon: Icons.speed,
                title: 'Closing Shortcut',
                subheading: 'Close 28% Faster',
                details: [
                  'Shared notes system',
                  'Transaction milestone tracker',
                  'Document sharing hub',
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}