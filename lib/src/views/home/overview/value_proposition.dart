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

  bool _hasAnimated = false;

  @override
  void initState() {
    super.initState();

    _titleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _titleFadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _titleController, curve: Curves.easeIn),
    );

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
    if (_hasAnimated) return;
    _titleController.forward();
    for (int i = 0; i < _containerControllers.length; i++) {
      Future.delayed(Duration(milliseconds: i * 200 + 300), () {
        if (mounted) {
          _containerControllers[i].forward();
        }
      });
    }
    _hasAnimated = true;
  }

  void _resetAnimations() {
    _hasAnimated = false;
    _titleController.reset();
    for (var controller in _containerControllers) {
      controller.reset();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 800;

    return VisibilityDetector(
      key: const Key('value-propositions'),
      onVisibilityChanged: (visibilityInfo) {
        final visibleFraction = visibilityInfo.visibleFraction;
        if (visibleFraction > 0.1 && !_hasAnimated) {
          _startAnimations();
        } else if (visibleFraction <= 0.1 && _hasAnimated) {
          _resetAnimations();
        }
      },
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          vertical: isMobile ? 20 : 40,
          horizontal: isMobile ? 8 : 120,
        ),
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
                child: Text(
                  'Value Propositions',
                  style: TextStyle(
                    fontSize: isMobile ? 36 : 56,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            SizedBox(height: isMobile ? 40 : 80),
            _buildContainersSection(isMobile),
          ],
        ),
      ),
    );
  }

  Widget _buildContainersSection(bool isMobile) {
    final containers = [
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
    ];

    return isMobile
        ? Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        containers[0],
        const SizedBox(height: 24),
        containers[1],
        const SizedBox(height: 24),
        containers[2],
        const SizedBox(height: 24),
        containers[3],
      ],
    )
        : Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(child: containers[0]),
        const SizedBox(width: 16),
        Expanded(child: containers[1]),
        const SizedBox(width: 16),
        Expanded(child: containers[2]),
        const SizedBox(width: 16),
        Expanded(child: containers[3]),
      ],
    );
  }
}