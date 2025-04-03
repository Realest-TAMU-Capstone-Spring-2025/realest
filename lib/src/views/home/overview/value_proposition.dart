import 'package:flutter/material.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'value_prop_container.dart';

class ValuePropositions extends StatefulWidget {
  const ValuePropositions({super.key});

  @override
  _ValuePropositionsState createState() => _ValuePropositionsState();
}

class _ValuePropositionsState extends State<ValuePropositions> with TickerProviderStateMixin {
  static const Color neonPurple = Color(0xFFD500F9);

  late AnimationController _titleController;
  late Animation<double> _titleFadeAnimation;
  late List<AnimationController> _containerControllers;
  late List<Animation<double>> _containerFadeAnimations;
  late List<Animation<Offset>> _containerSlideAnimations;

  bool _hasAnimated = false; // Prevent re-animation after first run

  @override
  void initState() {
    super.initState();

    // Title animation
    _titleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _titleFadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _titleController, curve: Curves.easeIn),
    );

    // Initialize animations for 4 containers
    _containerControllers = List.generate(
      4,
          (index) => AnimationController(
        duration: const Duration(milliseconds: 600),
        vsync: this,
      ),
    );
    _containerFadeAnimations = _containerControllers.map((controller) {
      return Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeIn),
      );
    }).toList();
    _containerSlideAnimations = List.generate(4, (index) {
      final beginOffset = index % 2 == 0 ? const Offset(-0.5, 0) : const Offset(0.5, 0);
      return Tween<Offset>(begin: beginOffset, end: Offset.zero).animate(
        CurvedAnimation(parent: _containerControllers[index], curve: Curves.easeOut),
      );
    });

    debugPrint('ValuePropositions initState called');
  }

  @override
  void dispose() {
    _titleController.dispose();
    for (var controller in _containerControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _startAnimations() {
    if (_hasAnimated) return; // Prevent re-running animations
    debugPrint('Starting animations');
    _titleController.forward();
    for (int i = 0; i < _containerControllers.length; i++) {
      Future.delayed(Duration(milliseconds: i * 200 + 300), () {
        debugPrint('Animating container $i');
        _containerControllers[i].forward();
      });
    }
    _hasAnimated = true; // Mark as animated
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('ValuePropositions build called');
    return VisibilityDetector(
      key: const Key('value-propositions'), // Unique key for detector
      onVisibilityChanged: (visibilityInfo) {
        final visibleFraction = visibilityInfo.visibleFraction;
        debugPrint('Visibility fraction: $visibleFraction');
        if (visibleFraction > 0.1 && !_hasAnimated) {
          // Trigger animations when at least 10% visible
          _startAnimations();
        }
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
        color: Colors.black,
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
                  'Value Propositions',
                  style: TextStyle(
                    fontSize: 56,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            const SizedBox(height: 80),
            Wrap(
              spacing: 24,
              runSpacing: 24,
              alignment: WrapAlignment.center,
              children: [
                SlideTransition(
                  position: _containerSlideAnimations[0],
                  child: FadeTransition(
                    opacity: _containerFadeAnimations[0],
                    child: ValuePropContainer(
                      icon: Icons.real_estate_agent,
                      title: 'Realtors',
                      subheading: 'Curate & Conquer',
                      details: [
                        'Bulk listing distribution',
                        'Custom cash flow edits',
                        'Client analytics dashboard',
                      ],
                    ),
                  ),
                ),
                SlideTransition(
                  position: _containerSlideAnimations[1],
                  child: FadeTransition(
                    opacity: _containerFadeAnimations[1],
                    child: ValuePropContainer(
                      icon: Icons.swipe,
                      title: 'Investors',
                      subheading: 'Swipe to Invest',
                      details: [
                        'Tinder Style Swiping',
                        'Interactive ROI calculator',
                        'Property comparison tool',
                      ],
                    ),
                  ),
                ),
                SlideTransition(
                  position: _containerSlideAnimations[2],
                  child: FadeTransition(
                    opacity: _containerFadeAnimations[2],
                    child: ValuePropContainer(
                      icon: Icons.hourglass_empty,
                      title: 'Time Saver',
                      subheading: '10hrs → 20mins Weekly',
                      details: [
                        'Automated MLS data parsing',
                        'Pre-built report templates',
                        'Email/SMS notification system',
                      ],
                    ),
                  ),
                ),
                SlideTransition(
                  position: _containerSlideAnimations[3],
                  child: FadeTransition(
                    opacity: _containerFadeAnimations[3],
                    child: ValuePropContainer(
                      icon: Icons.speed,
                      title: 'Closing Shortcut',
                      subheading: 'Close 28% Faster',
                      details: [
                        'Shared notes system',
                        'Transaction milestone tracker',
                        'Document sharing hub',
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}